import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../firebase_ambiente.dart';
import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../regras/montar.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

const _uuid = Uuid();

/// Abre o lançar. No celular é uma folha; na mesa, um diálogo.
Future<void> abrirLancar(BuildContext context, {String textoInicial = ''}) {
  if (ehMesa(context)) {
    return showDialog<void>(
      context: context,
      // Um clique fora não pode jogar fora o que já foi digitado.
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: Lancar(textoInicial: textoInicial),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(heightFactor: 0.92, child: Lancar(textoInicial: textoInicial)),
    ),
  );
}

/// Lançar por texto: a pessoa escreve, o app mostra o que entendeu e a
/// consequência, e só então salva. Uma linha por lançamento.
class Lancar extends ConsumerStatefulWidget {
  const Lancar({super.key, this.textoInicial = ''});
  final String textoInicial;

  @override
  ConsumerState<Lancar> createState() => _LancarState();
}

class _LancarState extends ConsumerState<Lancar> {
  late final _texto = TextEditingController(text: widget.textoInicial);

  /// Ajustes feitos à mão ou vindos da IA, por linha digitada.
  final _ajustes = <String, Leitura>{};
  bool _lendoComIa = false;
  bool _salvando = false;
  String? _aviso;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  List<(String, Leitura?)> _itens(ContextoDeLeitura ctx) => [
        for (final (linha, leitura) in lerTexto(_texto.text, ctx)) (linha, _ajustes[linha] ?? leitura),
      ];

  Future<void> _lerComIa(List<String> linhas, ContextoDeLeitura ctx) async {
    final espaco = ref.read(espacoAtualProvider);
    if (espaco == null) return;
    setState(() {
      _lendoComIa = true;
      _aviso = null;
    });
    try {
      final resposta = await funcoesDoAmbiente.httpsCallable('interpretarFrase').call<Map<Object?, Object?>>({
        'espacoId': espaco.id,
        'texto': linhas.join('\n'),
        'hoje': ctx.hoje,
        'contas': [
          for (final c in ctx.contas.where((c) => !c.arquivada)) {'id': c.id, 'nome': c.nome, 'tipo': c.tipo},
        ],
        'categorias': [
          for (final c in ctx.categorias.where((c) => !c.arquivada)) {'id': c.id, 'nome': c.nome, 'tipo': c.tipo},
        ],
      });
      final leituras = (resposta.data['leituras'] as List? ?? const [])
          .whereType<Map<Object?, Object?>>()
          .toList();
      if (!mounted) return;
      setState(() {
        // A IA devolve um item por linha, na ordem. Se a contagem não bater,
        // é mais honesto não adivinhar qual é qual.
        if (leituras.length == linhas.length) {
          for (var i = 0; i < linhas.length; i++) {
            final l = Leitura.deMapa(leituras[i], linhas[i]);
            _ajustes[linhas[i]] = l.contaId == null ? l.copiar(contaId: () => ctx.contaPadraoId) : l;
          }
        } else {
          _aviso = 'Não consegui ler essas linhas com segurança. Preencha os detalhes à mão.';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _aviso = 'Não consegui ler agora. Preencha os detalhes à mão.');
    } finally {
      if (mounted) setState(() => _lendoComIa = false);
    }
  }

  Future<void> _detalhar(String linha, Leitura? leitura, ContextoDeLeitura ctx) async {
    final ajustada = await Navigator.of(context).push<Leitura>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FormularioAvancado(
        inicial: leitura ??
            Leitura(tipo: 'saida', descricao: linha, valorCentavos: 0, data: ctx.hoje, contaId: ctx.contaPadraoId, original: linha),
        contas: ctx.contas,
        categorias: ctx.categorias,
        hoje: ctx.hoje,
      ),
    ));
    if (ajustada != null) setState(() => _ajustes[linha] = ajustada);
  }

  Future<void> _salvar(List<Leitura> prontas, ContextoDeLeitura ctx) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    setState(() => _salvando = true);
    final autor = ref.read(authProvider).valueOrNull?.uid;
    final contas = {for (final c in ctx.contas) c.id: c};
    final montagens = [
      for (final l in prontas) montar(l, conta: contas[l.contaId]!, novoId: _uuid.v4, autorId: autor),
    ];
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      final lote = await repo.salvar(montagens, loteId: _uuid.v4(), autorId: autor);
      final total = montagens.fold<int>(0, (n, m) => n + m.lancamentos.length);
      navegador.pop();
      mensageiro
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(total == 1 ? 'Lançamento salvo.' : '$total lançamentos salvos.'),
          action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.desfazerLote(lote)),
        ));
    } catch (_) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _aviso = 'Não foi possível salvar. Confira a conexão e tente de novo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(contextoDeLeituraProvider);
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final itens = _itens(ctx);
    final prontas = [for (final (_, l) in itens) if (l != null && l.completa) l];
    final semLeitura = [for (final (linha, l) in itens) if (l == null) linha];
    final contas = {for (final x in ctx.contas) x.id: x};
    final categorias = {for (final x in ctx.categorias) x.id: x};

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.p, Espacos.g, Espacos.g),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Lançar', style: texto.titleLarge)),
              TextButton.icon(
                onPressed: () => _detalhar('', null, ctx).then((_) {
                  final l = _ajustes.remove('');
                  if (l != null && l.completa) _salvar([l], ctx);
                }),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Modo avançado'),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: Espacos.p),
          TextField(
            controller: _texto,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _aviso = null),
            decoration: const InputDecoration(
              hintText: 'mercado 45,90 no cartão\nuber 23 ontem\nrecebi salário 5000',
              helperText: 'Uma linha por lançamento. Pode colar vários de uma vez.',
            ),
          ),
          const SizedBox(height: Espacos.m),
          Expanded(
            child: ListView(
              children: [
                for (final (linha, l) in itens)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espacos.p),
                    child: l == null
                        ? Cartao(
                            onTap: () => _detalhar(linha, null, ctx),
                            child: Row(
                              children: [
                                Icon(Icons.help_outline_rounded, color: c.atencao),
                                const SizedBox(width: Espacos.m),
                                Expanded(child: Text('Não achei o valor em "$linha". Toque para preencher.')),
                              ],
                            ),
                          )
                        : _CartaoDeLeitura(
                            leitura: l,
                            hoje: ctx.hoje,
                            conta: contas[l.contaId],
                            destino: contas[l.contaDestinoId],
                            categoria: categorias[l.categoriaId],
                            aoTocar: () => _detalhar(linha, l, ctx),
                          ),
                  ),
                if (semLeitura.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _lendoComIa ? null : () => _lerComIa(semLeitura, ctx),
                      icon: _lendoComIa
                          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(_lendoComIa ? 'Lendo…' : 'Tentar ler com a IA'),
                    ),
                  ),
                if (_aviso != null)
                  Padding(
                    padding: const EdgeInsets.only(top: Espacos.p),
                    child: Text(_aviso!, style: texto.bodyMedium?.copyWith(color: c.atencao)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Espacos.p),
          FilledButton(
            onPressed: prontas.isEmpty || _salvando ? null : () => _salvar(prontas, ctx),
            child: Text(prontas.isEmpty
                ? 'Salvar'
                : (prontas.length == 1 ? 'Salvar ${reais(prontas.single.valorCentavos)}' : 'Salvar ${prontas.length} lançamentos')),
          ),
        ],
      ),
    );
  }
}

class _CartaoDeLeitura extends StatelessWidget {
  const _CartaoDeLeitura({
    required this.leitura,
    required this.hoje,
    required this.aoTocar,
    this.conta,
    this.destino,
    this.categoria,
  });

  final Leitura leitura;
  final String hoje;
  final Conta? conta;
  final Conta? destino;
  final Categoria? categoria;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final l = leitura;
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    return Cartao(
      onTap: aoTocar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.descricao, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(
                '${l.tipo == 'entrada' ? '+' : (l.tipo == 'saida' ? '-' : '')}${reais(l.valorCentavos)}',
                style: texto.titleMedium?.copyWith(color: l.tipo == 'entrada' ? c.positivo : c.tinta),
              ),
            ],
          ),
          const SizedBox(height: Espacos.p),
          Wrap(
            spacing: Espacos.p,
            runSpacing: Espacos.xp,
            children: [
              Etiqueta(diaPorExtenso(l.data, hoje)),
              Etiqueta(conta?.nome ?? 'sem conta', cor: conta == null ? c.atencao : null),
              if (l.tipo == 'transferencia')
                Etiqueta('→ ${destino?.nome ?? 'sem destino'}', cor: destino == null ? c.atencao : null)
              else
                Etiqueta(categoria?.nome ?? 'sem categoria'),
              if (l.parcelas != null) Etiqueta('${l.parcelas}x'),
              if (l.recorrente) const Etiqueta('todo mês'),
              if (!l.efetivado) const Etiqueta('agendado'),
            ],
          ),
          const SizedBox(height: Espacos.p),
          Text(
            l.completa ? consequencia(l, conta: conta, destino: destino) : 'Falta um detalhe. Toque para completar.',
            style: texto.bodySmall?.copyWith(color: l.completa ? null : c.atencao),
          ),
        ],
      ),
    );
  }
}
