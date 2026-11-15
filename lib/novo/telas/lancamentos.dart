import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'formulario.dart';
import 'pecas.dart';

/// Mês em exibição na tela de lançamentos; `null` = mês de hoje.
final mesExibidoProvider = StateProvider<String?>((ref) => null);

/// Aba interna de Lançamentos: `caixa`, `agendados` ou `todos`. `null` deixa
/// o app escolher: a caixa de entrada, se houver algo nela.
final abaDeLancamentosProvider = StateProvider<String?>((ref) => null);

class TelaLancamentos extends ConsumerStatefulWidget {
  const TelaLancamentos({super.key});

  @override
  ConsumerState<TelaLancamentos> createState() => _TelaLancamentosState();
}

class _TelaLancamentosState extends ConsumerState<TelaLancamentos> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final mes = ref.watch(mesExibidoProvider) ?? hoje.substring(0, 7);
    final pendentes = ref.watch(entradaProvider).valueOrNull?.length ?? 0;
    final aba = ref.watch(abaDeLancamentosProvider) ?? (pendentes > 0 ? 'caixa' : 'todos');
    final mesa = ehMesa(context);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);

    final segmentos = Segmentos<String>(
      largo: !mesa,
      valor: aba,
      aoMudar: (v) => ref.read(abaDeLancamentosProvider.notifier).state = v,
      opcoes: [
        // No celular o rótulo curto mantém as três opções do mesmo tamanho.
        ('caixa', '${mesa ? 'Caixa de entrada' : 'Entrada'}${pendentes > 0 ? ' ($pendentes)' : ''}'),
        ('agendados', 'Agendados'),
        ('todos', 'Todos'),
      ],
    );

    if (aba == 'caixa') {
      return Pagina(filhos: [
        Align(alignment: Alignment.centerLeft, child: segmentos),
        const SizedBox(height: Espacos.g),
        const CaixaDeEntrada(),
      ]);
    }

    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final carregando = ref.watch(lancamentosDoMesProvider(mes)).isLoading;
    final todos = (ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[])
        // Aparece no mês em que aconteceu; o agendado, no mês em que vence.
        .where((l) => l.situacao != 'cancelado' && l.dia.startsWith(mes))
        .toList();
    final busca = normalizar(_busca.trim());
    final visiveis = todos
        .where((l) => aba == 'todos' || l.previsto)
        .where((l) =>
            busca.isEmpty ||
            normalizar('${l.descricao} ${contas[l.contaId]?.nome ?? ''} ${categorias[l.categoriaId]?.nome ?? ''}').contains(busca))
        .toList()
      ..sort((a, b) => aba == 'agendados' ? a.dia.compareTo(b.dia) : b.dia.compareTo(a.dia));

    var entradas = 0;
    var saidas = 0;
    for (final l in visiveis) {
      if (l.ehEntrada) entradas += l.valorCentavos;
      if (l.ehSaida) saidas += l.valorCentavos;
    }

    final navegacaoDoMes = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Mês anterior',
          visualDensity: VisualDensity.compact,
          onPressed: () => ref.read(mesExibidoProvider.notifier).state = somarMeses(mes, -1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Flexible(child: Text(nomeDoMes(mes), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium)),
        IconButton(
          tooltip: 'Mês seguinte',
          visualDensity: VisualDensity.compact,
          onPressed: () => ref.read(mesExibidoProvider.notifier).state = somarMeses(mes, 1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
    final campoDeBusca = TextField(
      onChanged: (v) => setState(() => _busca = v),
      decoration: const InputDecoration(
        hintText: 'Buscar',
        prefixIcon: Icon(Icons.search_rounded, size: 18),
        prefixIconConstraints: BoxConstraints(minWidth: 36),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      ),
    );

    Widget total(String rotulo, int centavos, {Color? cor}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rotulo, style: t.bodySmall),
            Text(reais(centavos), style: Textos.valor(context, cor: cor)),
          ],
        );
    final totais = Cartao(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(child: total(aba == 'agendados' ? 'A receber' : 'Entradas', entradas, cor: c.positivo)),
          Expanded(child: total(aba == 'agendados' ? 'A pagar' : 'Saídas', saidas)),
          Expanded(child: total('Resultado', entradas - saidas, cor: entradas - saidas < 0 ? c.problema : null)),
          if (mesa)
            Text('${visiveis.length} ${visiveis.length == 1 ? 'lançamento' : 'lançamentos'}', style: t.bodySmall),
        ],
      ),
    );

    Widget corpo;
    if (carregando && todos.isEmpty) {
      corpo = const Padding(padding: EdgeInsets.all(Espacos.xxg), child: Center(child: CircularProgressIndicator()));
    } else if (visiveis.isEmpty) {
      corpo = Cartao(
        padding: EdgeInsets.zero,
        child: Vazio(_busca.isNotEmpty
            ? 'Nada encontrado para "$_busca".'
            : (aba == 'agendados' ? 'Nada agendado em ${nomeDoMes(mes)}.' : 'Nenhum lançamento em ${nomeDoMes(mes)}.')),
      );
    } else if (mesa) {
      corpo = Cartao(
        padding: EdgeInsets.zero,
        child: _Grade(
          lancamentos: visiveis,
          contas: contas,
          categorias: categorias,
          hoje: hoje,
          aoTocar: (l) => abrirLancamento(context, ref, l),
          aoEditar: (antes, depois) async {
            final repo = ref.read(repositorioProvider);
            if (repo == null) return;
            final mensageiro = ScaffoldMessenger.of(context);
            await repo.gravar(depois);
            mensageiro
              ..clearSnackBars()
              ..showSnackBar(SnackBar(
                content: const Text('Alteração salva.'),
                action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.gravar(antes)),
              ));
          },
        ),
      );
    } else {
      corpo = Lista(filhos: [
        for (final l in visiveis)
          LinhaDeLancamento(
            lancamento: l,
            hoje: hoje,
            conta: contas[l.contaId],
            destino: contas[l.contaDestinoId],
            categoria: categorias[l.categoriaId],
            onTap: () => abrirLancamento(context, ref, l),
          ),
      ]);
    }

    return Pagina(filhos: [
      if (mesa)
        Row(children: [
          segmentos,
          const SizedBox(width: Espacos.g),
          navegacaoDoMes,
          const Spacer(),
          SizedBox(width: 240, child: campoDeBusca),
        ])
      else ...[
        segmentos,
        const SizedBox(height: Espacos.p),
        Row(children: [Expanded(child: navegacaoDoMes)]),
        campoDeBusca,
      ],
      const SizedBox(height: Espacos.m),
      totais,
      const SizedBox(height: Espacos.m),
      corpo,
    ]);
  }
}

/// Grade densa da web: uma linha por lançamento, colunas alinhadas.
/// Descrição e categoria são editadas na própria linha.
class _Grade extends StatelessWidget {
  const _Grade({
    required this.lancamentos,
    required this.contas,
    required this.categorias,
    required this.hoje,
    required this.aoTocar,
    required this.aoEditar,
  });

  /// Edição feita direto numa célula: (como era, como ficou).
  final void Function(Lancamento, Lancamento) aoEditar;
  final List<Lancamento> lancamentos;
  final Map<String, Conta> contas;
  final Map<String, Categoria> categorias;
  final String hoje;
  final void Function(Lancamento) aoTocar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final cabeca = Textos.sobrancelha(context);

    Widget celula(String s, {int flex = 2, TextStyle? estilo, TextAlign? alinhar}) => Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo ?? t.bodyMedium?.copyWith(fontSize: 13.5), textAlign: alinhar),
          ),
        );

    Widget linha(List<Widget> filhos, {VoidCallback? onTap, double vertical = 9}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, vertical, 2, vertical),
            child: Row(children: filhos),
          ),
        );

    return Column(
      children: [
        linha(vertical: 8, [
          celula('DATA', estilo: cabeca),
          celula('DESCRIÇÃO', flex: 5, estilo: cabeca),
          celula('CATEGORIA', flex: 3, estilo: cabeca),
          celula('CONTA', flex: 3, estilo: cabeca),
          celula('SITUAÇÃO', estilo: cabeca),
          celula('VALOR', flex: 3, estilo: cabeca, alinhar: TextAlign.end),
        ]),
        for (final l in lancamentos) ...[
          const Divider(),
          linha(onTap: () => aoTocar(l), [
            celula(diaPorExtenso(l.dia, hoje)),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _CelulaDeTexto(
                  valor: l.descricao,
                  sufixo: l.parcelaNumero != null ? '  ${l.parcelaNumero}/${l.parcelaTotal}' : '',
                  aoMudar: (novo) => aoEditar(l, l.copiar(descricao: novo)),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: l.ehTransferencia
                      ? Text('Transferência', maxLines: 1, style: t.bodyMedium?.copyWith(fontSize: 13.5, color: c.tinta3))
                      : InkWell(
                          borderRadius: Raios.pilula,
                          onTap: () async {
                            final opcoes = categorias.values
                                .where((x) => !x.arquivada && x.tipo == (l.ehEntrada ? 'entrada' : 'saida'))
                                .toList()
                              ..sort((a, b) => a.nome.compareTo(b.nome));
                            final escolhida = await escolher<Categoria>(context,
                                titulo: 'Categoria', itens: opcoes, rotulo: (x) => x.nome, atual: categorias[l.categoriaId]);
                            if (escolhida != null && escolhida.id != l.categoriaId) {
                              aoEditar(l, l.copiar(categoriaId: () => escolhida.id));
                            }
                          },
                          child: Etiqueta(
                            categorias[l.categoriaId]?.nome ?? 'sem categoria',
                            tom: l.categoriaId == null ? Tom.atencao : Tom.neutro,
                          ),
                        ),
                ),
              ),
            ),
            celula(
              l.ehTransferencia
                  ? '${contas[l.contaId]?.nome ?? '?'} → ${contas[l.contaDestinoId]?.nome ?? '?'}'
                  : (contas[l.contaId]?.nome ?? '?'),
              flex: 3,
            ),
            celula(
              l.previsto ? (l.data.compareTo(hoje) < 0 ? 'Atrasado' : 'Agendado') : 'Feito',
              estilo: t.bodyMedium?.copyWith(
                fontSize: 13.5,
                color: l.previsto && l.data.compareTo(hoje) < 0 ? c.atencao : c.tinta3,
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(valorComSinal(l), maxLines: 1, textAlign: TextAlign.end, style: Textos.valor(context, cor: corDoValor(context, l))),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

/// Célula que vira campo de texto ao ser tocada; Enter salva, Esc desiste.
class _CelulaDeTexto extends StatefulWidget {
  const _CelulaDeTexto({required this.valor, required this.aoMudar, this.sufixo = ''});
  final String valor;
  final String sufixo;
  final void Function(String) aoMudar;

  @override
  State<_CelulaDeTexto> createState() => _CelulaDeTextoState();
}

class _CelulaDeTextoState extends State<_CelulaDeTexto> {
  TextEditingController? _controle;
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(() {
      if (!_foco.hasFocus) _terminar(salvar: true);
    });
  }

  @override
  void dispose() {
    _controle?.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _terminar({required bool salvar}) {
    final controle = _controle;
    if (controle == null) return;
    final novo = controle.text.trim();
    setState(() => _controle = null);
    controle.dispose();
    if (salvar && novo.isNotEmpty && novo != widget.valor) widget.aoMudar(novo);
  }

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600);
    final controle = _controle;
    if (controle == null) {
      return InkWell(
        onTap: () {
          setState(() => _controle = TextEditingController(text: widget.valor));
          WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
        },
        child: Text(
          '${widget.valor.isEmpty ? 'Sem descrição' : widget.valor}${widget.sufixo}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: estilo,
        ),
      );
    }
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _terminar(salvar: false)},
      child: TextField(
        controller: controle,
        focusNode: _foco,
        style: estilo,
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
        onSubmitted: (_) => _terminar(salvar: true),
      ),
    );
  }
}
