import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/observability/app_logger.dart';
import '../../firebase_ambiente.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/distribuicao.dart';
import '../regras/formatos.dart';
import '../regras/mascara.dart';
import '../regras/organizacao.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

/// Organização financeira, de três em três meses: a pessoa confere a renda
/// e os gastos fixos (o app já traz o que conhece), e sai com um limite por
/// categoria de estilo de vida. A sugestão vem de uma conta simples; a IA,
/// quando responde, refina os limites e explica onde está a oportunidade.
class TelaOrganizacao extends ConsumerStatefulWidget {
  const TelaOrganizacao({super.key});

  @override
  ConsumerState<TelaOrganizacao> createState() => _TelaOrganizacaoState();
}

class _TelaOrganizacaoState extends ConsumerState<TelaOrganizacao> {
  final _renda = TextEditingController();
  final _fixos = TextEditingController();
  final _limites = <String, TextEditingController>{};
  bool _preenchido = false;
  bool _pedindo = false;
  bool _salvando = false;
  String? _insight;
  String? _avisoDaIa;

  @override
  void dispose() {
    _renda.dispose();
    _fixos.dispose();
    for (final c in _limites.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _texto(int centavos) => centavos <= 0 ? '' : reais(centavos, comSimbolo: false);

  /// As categorias de estilo de vida e a média mensal de cada uma.
  List<(Categoria, int)> _categorias() {
    final d = ref.read(diagnosticoProvider);
    final medias = {for (final x in d?.categorias['conforto'] ?? const <CategoriaNoGrupo>[]) x.categoriaId: x.mediaCentavos};
    final lista = [
      for (final c in ref.read(categoriasProvider).valueOrNull ?? const <Categoria>[])
        if (c.tipo == 'saida' && !c.arquivada && grupoDa(c) == 'conforto') (c, medias[c.id] ?? 0),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return lista;
  }

  int get _metas => (ref.read(metasProvider).valueOrNull ?? const <Meta>[])
      .where((m) => m.emAberto)
      .fold<int>(0, (s, m) => s + (m.parcelaMensalCentavos ?? 0));

  SugestaoDeLimites _sugestao() => sugerirLimites(
        rendaCentavos: lerCentavos(_renda.text) ?? 0,
        fixosCentavos: lerCentavos(_fixos.text) ?? 0,
        metasCentavos: _metas,
        percentualDoEstilo: (ref.read(diagnosticoProvider)?.referencia ?? referencias.first).conforto,
        mediaPorCategoria: {for (final (c, media) in _categorias()) c.id: media},
      );

  void _aplicarNosCampos(Map<String, int> limites) {
    for (final (c, _) in _categorias()) {
      (_limites[c.id] ??= TextEditingController()).text = _texto(limites[c.id] ?? 0);
    }
  }

  /// Traz o que o app já conhece: renda e fixos médios, e a sugestão base.
  void _preencher() {
    final d = ref.read(diagnosticoProvider);
    _renda.text = _texto(d?.rendaCentavos ?? 0);
    _fixos.text = _texto(d?.porGrupo['essencial'] ?? 0);
    _aplicarNosCampos(_sugestao().limites);
    _preenchido = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirIa());
  }

  void _recalcular() => setState(() {
        _insight = null;
        _aplicarNosCampos(_sugestao().limites);
      });

  Future<void> _pedirIa() async {
    final espaco = ref.read(espacoAtualProvider);
    final base = _sugestao();
    final categorias = _categorias().where((x) => x.$2 > 0).toList();
    if (espaco == null || base.tetoCentavos <= 0 || categorias.isEmpty || _pedindo) return;
    setState(() {
      _pedindo = true;
      _avisoDaIa = null;
    });
    try {
      final resposta = await funcoesDoAmbiente.httpsCallable('sugerirOrganizacao').call<Map<Object?, Object?>>({
        'espacoId': espaco.id,
        'rendaCentavos': lerCentavos(_renda.text) ?? 0,
        'fixosCentavos': lerCentavos(_fixos.text) ?? 0,
        'metasCentavos': _metas,
        'tetoCentavos': base.tetoCentavos,
        'categorias': [for (final (c, media) in categorias) {'id': c.id, 'nome': c.nome, 'mediaCentavos': media}],
      });
      final insight = resposta.data['insight'];
      final limites = resposta.data['limites'];
      if (!mounted || insight is! String || limites is! Map) return;
      setState(() {
        _insight = insight;
        _aplicarNosCampos({
          ...base.limites,
          for (final e in limites.entries)
            if (e.value is num) '${e.key}': (e.value as num).round(),
        });
      });
    } on FirebaseFunctionsException catch (erro, pilha) {
      AppLogger.error('Sugestão de organização falhou', erro, pilha);
      if (mounted) setState(() => _avisoDaIa = 'A IA não respondeu agora. Os limites abaixo vêm da conta do próprio app.');
    } catch (erro, pilha) {
      AppLogger.error('Sugestão de organização falhou', erro, pilha);
      if (mounted) setState(() => _avisoDaIa = 'A IA não respondeu agora. Os limites abaixo vêm da conta do próprio app.');
    } finally {
      if (mounted) setState(() => _pedindo = false);
    }
  }

  Future<void> _aplicar() async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    setState(() => _salvando = true);
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final hoje = ref.read(hojeProvider);
    var definidos = 0;
    for (final (c, _) in _categorias()) {
      final valor = lerCentavos(_limites[c.id]?.text ?? '');
      if (valor != null) definidos++;
      if (valor != c.limiteMensalCentavos) await repo.gravarCategoria(c.id, {'limiteMensalCentavos': valor});
    }
    await repo.marcar('organizacao', {
      'feitaEm': hoje,
      'adiadaEm': null,
      'rendaCentavos': lerCentavos(_renda.text) ?? 0,
      'fixosCentavos': lerCentavos(_fixos.text) ?? 0,
    });
    navegador.pop();
    mensageiro
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Organização salva: $definidos ${definidos == 1 ? 'categoria com limite' : 'categorias com limite'}.')));
  }

  @override
  Widget build(BuildContext context) {
    final c = Cores.de(context);
    final t = Theme.of(context).textTheme;
    final pronto = ref.watch(categoriasProvider).hasValue && ref.watch(resumosProvider).hasValue;
    final d = ref.watch(diagnosticoProvider);
    if (pronto && !_preenchido) _preencher();

    if (!pronto) {
      return Scaffold(appBar: AppBar(title: const Text('Organização financeira')), body: const Center(child: CircularProgressIndicator()));
    }

    final sugestao = _sugestao();
    final categorias = _categorias();
    final soma = categorias.fold<int>(0, (s, x) => s + (lerCentavos(_limites[x.$1.id]?.text ?? '') ?? 0));
    final acima = sugestao.tetoCentavos > 0 && soma > sugestao.tetoCentavos;

    Widget campo(TextEditingController controle, String rotulo, String ajuda) => TextField(
          controller: controle,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MascaraDeValor()],
          onChanged: (_) => _recalcular(),
          decoration: InputDecoration(labelText: rotulo, prefixText: r'R$ ', helperText: ajuda, helperMaxLines: 2),
        );

    final entrada = <Widget>[
      const TituloDeSecao('O que entra e o que é fixo', semTopo: true),
      Cartao(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          campo(
            _renda,
            'Renda mensal total',
            d == null ? 'Some tudo o que entra num mês comum.' : 'O app trouxe a média dos últimos ${d.meses.length} ${d.meses.length == 1 ? 'mês' : 'meses'}. Ajuste se mudou.',
          ),
          const SizedBox(height: Espacos.m),
          campo(_fixos, 'Gastos fixos por mês', 'Moradia, contas, mercado, saúde, transporte, escola: o que não dá para deixar de pagar.'),
          const SizedBox(height: Espacos.m),
          Row(children: [
            Expanded(child: Text('Reservado para as metas', style: t.bodyMedium)),
            Text(reais(_metas, sempre: true), style: Textos.valor(context)),
          ]),
          const Divider(height: Espacos.xg),
          Row(children: [
            Expanded(child: Text('Cabe no estilo de vida', style: t.titleSmall)),
            Text(reais(sugestao.tetoCentavos, sempre: true), style: Textos.valor(context, tamanho: 16)),
          ]),
          if (sugestao.aviso != null) ...[
            const SizedBox(height: Espacos.p),
            Text(sugestao.aviso!, style: t.bodySmall?.copyWith(color: c.atencao)),
          ],
        ]),
      ),
      if (_pedindo || _insight != null || _avisoDaIa != null) ...[
        const TituloDeSecao('O que o app sugere'),
        Cartao(
          cor: _insight != null ? c.primariaSuave : null,
          child: _pedindo
              ? Row(children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: Espacos.m),
                  Expanded(child: Text('Lendo os seus números para sugerir os limites…', style: t.bodySmall)),
                ])
              : Text(_insight ?? _avisoDaIa!, style: _insight != null ? t.bodyMedium : t.bodySmall),
        ),
      ],
    ];

    final limites = <Widget>[
      TituloDeSecao(
        'Limite por categoria',
        semTopo: ehMesa(context),
        detalhe: sugestao.tetoCentavos > 0 ? '${reais(soma, sempre: true)} de ${reais(sugestao.tetoCentavos, sempre: true)}' : null,
      ),
      if (categorias.isEmpty)
        const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma categoria de estilo de vida cadastrada.'))
      else
        Lista(filhos: [
          for (final (categoria, media) in categorias)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                SeloDaCategoria(categoria: categoria),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(categoria.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    Text(media > 0 ? 'costuma gastar ${reais(media, sempre: true)}' : 'sem gasto nos últimos meses', style: t.bodySmall),
                  ]),
                ),
                SizedBox(
                  width: 128,
                  child: TextField(
                    controller: _limites[categoria.id],
                    textAlign: TextAlign.end,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: const [MascaraDeValor()],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: 'sem limite', prefixText: r'R$ ', isDense: true),
                  ),
                ),
              ]),
            ),
        ]),
      const SizedBox(height: Espacos.p),
      Text(
        acima
            ? 'A soma passa do que cabe no estilo de vida em ${reais(soma - sugestao.tetoCentavos, sempre: true)}.'
            : 'Deixe em branco para a categoria ficar sem limite próprio: ela entra no resto do estilo de vida.',
        style: t.bodySmall?.copyWith(color: acima ? c.atencao : null),
      ),
      const SizedBox(height: Espacos.g),
      Acoes(filhos: [
        FilledButton(onPressed: _salvando ? null : _aplicar, child: const Text('Aplicar limites')),
        TextButton(onPressed: _pedindo ? null : _pedirIa, child: const Text('Pedir outra sugestão')),
      ]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Organização financeira')),
      body: Pagina(
        larguraMaxima: 1000,
        centralizada: true,
        filhos: ehMesa(context)
            ? [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: entrada)),
                  const SizedBox(width: Espacos.xg),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: limites)),
                ]),
              ]
            : [...entrada, ...limites],
      ),
    );
  }
}
