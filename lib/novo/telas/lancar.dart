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

/// Abre o lançar, numa folha.
Future<void> abrirLancar(BuildContext context, {String textoInicial = '', String? contaId}) =>
    abrirFolha<void>(context, (_) => Lancar(textoInicial: textoInicial, contaId: contaId), largura: 600, alta: true);

/// Lançar por texto: a pessoa escreve, o app mostra o que entendeu e a
/// consequência, e só então salva. Uma linha por lançamento.
class Lancar extends ConsumerStatefulWidget {
  const Lancar({super.key, this.textoInicial = '', this.contaId});
  final String textoInicial;

  /// Conta do contexto de onde o lançar foi aberto (detalhe de uma conta):
  /// vale como padrão no lugar da conta mais usada.
  final String? contaId;

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
        for (final (linha, leitura) in lerTexto(_texto.text, ctx)) (linha, _ajustes[linha] ?? _comContraparte(leitura, linha)),
      ];

  /// Em espaço de empresa, o nome de um cliente ou fornecedor na frase já
  /// liga o lançamento a ele.
  Leitura? _comContraparte(Leitura? leitura, String linha) {
    if (leitura == null || leitura.tipo == 'transferencia' || !(ref.read(espacoAtualProvider)?.ehEmpresa ?? false)) return leitura;
    final texto = ' ${normalizar(linha)} ';
    final tipo = leitura.tipo == 'entrada' ? 'cliente' : 'fornecedor';
    for (final x in ref.read(contrapartesProvider).valueOrNull ?? const <Contraparte>[]) {
      if (x.tipo == tipo && x.nome.length >= 3 && texto.contains(' ${normalizar(x.nome)} ')) {
        return leitura.copiar(contraparteId: () => x.id);
      }
    }
    return leitura;
  }

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
        contrapartes: (ref.read(espacoAtualProvider)?.ehEmpresa ?? false)
            ? (ref.read(contrapartesProvider).valueOrNull ?? const <Contraparte>[])
            : null,
        aoCriarContraparte: (nome, tipo) async {
          final id = _uuid.v4();
          await ref.read(repositorioProvider)?.gravarContraparte(id, nome: nome, tipo: tipo);
          return Contraparte(id: id, nome: nome, tipo: tipo);
        },
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
    final base = ref.watch(contextoDeLeituraProvider);
    final ctx = widget.contaId == null
        ? base
        : ContextoDeLeitura(
            hoje: base.hoje,
            contas: base.contas,
            categorias: base.categorias,
            aprendido: base.aprendido,
            contaPadraoId: widget.contaId,
            membros: base.membros,
            euId: base.euId,
          );
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final itens = _itens(ctx);
    final prontas = [for (final (_, l) in itens) if (l != null && l.completa) l];
    final semLeitura = [for (final (linha, l) in itens) if (l == null) linha];
    final contas = {for (final x in ctx.contas) x.id: x};
    final categorias = {for (final x in ctx.categorias) x.id: x};
    final nomes = ref.watch(nomesDasContasProvider);

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
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Modo avançado'),
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
            style: texto.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'café 15\nuber 23 ontem no cartão\nrecebi salário 5000',
              helperText: 'Uma linha por lançamento. Pode colar vários de uma vez.',
              helperMaxLines: 2,
              contentPadding: EdgeInsets.all(12),
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
                            cor: c.atencaoSuave,
                            semBorda: true,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Não achei o valor em "$linha". Toque para preencher.',
                              style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.atencao),
                            ),
                          )
                        : _CartaoDeLeitura(
                            leitura: l,
                            hoje: ctx.hoje,
                            conta: contas[l.contaId],
                            destino: contas[l.contaDestinoId],
                            categoria: categorias[l.categoriaId],
                            nomeDaConta: nomes[l.contaId],
                            nomeDoDestino: nomes[l.contaDestinoId],
                            aoTocar: () => _detalhar(linha, l, ctx),
                          ),
                  ),
                if (semLeitura.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _lendoComIa ? null : () => _lerComIa(semLeitura, ctx),
                      icon: _lendoComIa
                          ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
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
    this.nomeDaConta,
    this.nomeDoDestino,
  });

  /// Nomes como aparecem nas listas (com o titular, se houver duas iguais).
  final String? nomeDaConta;
  final String? nomeDoDestino;

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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l.descricao, style: texto.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text(
                '${l.tipo == 'entrada' ? '+' : (l.tipo == 'saida' ? '-' : '')}${reais(l.valorCentavos)}',
                style: Textos.valor(context, tamanho: 15, cor: l.tipo == 'entrada' ? c.positivo : c.tinta),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Etiqueta(diaPorExtenso(l.data, hoje)),
              Etiqueta(nomeDaConta ?? conta?.nome ?? 'sem conta', tom: conta == null ? Tom.atencao : Tom.neutro),
              if (l.tipo == 'transferencia')
                Etiqueta('→ ${nomeDoDestino ?? destino?.nome ?? 'sem destino'}', tom: destino == null ? Tom.atencao : Tom.neutro)
              else
                Etiqueta(categoria?.nome ?? 'sem categoria', tom: categoria == null ? Tom.neutro : Tom.primario),
              if (l.parcelas != null) Etiqueta('${l.parcelas}x', tom: Tom.calor),
              if (l.recorrente) const Etiqueta('todo mês', tom: Tom.calor),
              if (!l.efetivado) const Etiqueta('agendado', tom: Tom.calor),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.completa ? consequencia(l, conta: conta, destino: destino) : 'Falta um detalhe. Toque para completar.',
            style: texto.bodyMedium?.copyWith(fontSize: 13, color: l.completa ? c.tinta2 : c.atencao),
          ),
        ],
      ),
    );
  }
}
