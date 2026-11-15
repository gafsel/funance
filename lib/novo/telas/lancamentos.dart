import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'fechamento.dart';
import 'formulario.dart';
import 'pecas.dart';

/// Mês em exibição na tela de lançamentos; `null` = mês de hoje.
final mesExibidoProvider = StateProvider<String?>((ref) => null);

class TelaLancamentos extends ConsumerStatefulWidget {
  const TelaLancamentos({super.key});

  @override
  ConsumerState<TelaLancamentos> createState() => _TelaLancamentosState();
}

class _TelaLancamentosState extends ConsumerState<TelaLancamentos> {
  String _filtro = 'tudo';
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final hoje = ref.watch(hojeProvider);
    final mes = ref.watch(mesExibidoProvider) ?? hoje.substring(0, 7);
    final contas = {for (final c in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) c.id: c};
    final categorias = {for (final c in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) c.id: c};
    final carregando = ref.watch(lancamentosDoMesProvider(mes)).isLoading;
    final todos = (ref.watch(lancamentosDoMesProvider(mes)).valueOrNull ?? const <Lancamento>[])
        // Aparece no mês em que aconteceu; o agendado, no mês em que vence.
        .where((l) => l.situacao != 'cancelado' && l.dia.startsWith(mes))
        .toList();
    final busca = normalizar(_busca.trim());
    final visiveis = todos
        .where((l) => _filtro == 'tudo' || (_filtro == 'agendados' ? l.previsto : l.efetivado))
        .where((l) =>
            busca.isEmpty ||
            normalizar('${l.descricao} ${contas[l.contaId]?.nome ?? ''} ${categorias[l.categoriaId]?.nome ?? ''}').contains(busca))
        .toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));

    var entradas = 0;
    var saidas = 0;
    for (final l in visiveis) {
      if (l.ehEntrada) entradas += l.valorCentavos;
      if (l.ehSaida) saidas += l.valorCentavos;
    }

    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final mesa = ehMesa(context);

    final cabecalho = Wrap(
      spacing: Espacos.m,
      runSpacing: Espacos.p,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Mês anterior',
              onPressed: () => ref.read(mesExibidoProvider.notifier).state = somarMeses(mes, -1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(nomeDoMes(mes), style: texto.titleLarge),
            IconButton(
              tooltip: 'Mês seguinte',
              onPressed: () => ref.read(mesExibidoProvider.notifier).state = somarMeses(mes, 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'tudo', label: Text('Tudo')),
            ButtonSegment(value: 'feitos', label: Text('Feitos')),
            ButtonSegment(value: 'agendados', label: Text('Agendados')),
          ],
          selected: {_filtro},
          onSelectionChanged: (s) => setState(() => _filtro = s.first),
        ),
        OutlinedButton.icon(
          onPressed: () => abrirFechamento(context, mes),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Fechar o mês'),
        ),
        SizedBox(
          width: mesa ? 260 : double.infinity,
          child: TextField(
            onChanged: (v) => setState(() => _busca = v),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Buscar',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
      ],
    );

    final totais = Cartao(
      padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: Espacos.m),
      child: Wrap(
        spacing: Espacos.xg,
        runSpacing: Espacos.p,
        children: [
          _Total('Entradas', entradas, c.positivo),
          _Total('Saídas', saidas, c.tinta),
          _Total('Resultado', entradas - saidas, entradas - saidas < 0 ? c.atencao : c.tinta),
          Text('${visiveis.length} ${visiveis.length == 1 ? 'lançamento' : 'lançamentos'}', style: texto.bodySmall),
        ],
      ),
    );

    Widget corpo;
    if (carregando && todos.isEmpty) {
      corpo = const Padding(padding: EdgeInsets.all(Espacos.xxg), child: Center(child: CircularProgressIndicator()));
    } else if (visiveis.isEmpty) {
      corpo = Vazio(_busca.isEmpty ? 'Nenhum lançamento em ${nomeDoMes(mes)}.' : 'Nada encontrado para "$_busca".');
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
      corpo = Cartao(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final l in visiveis)
            LinhaDeLancamento(
              lancamento: l,
              hoje: hoje,
              conta: contas[l.contaId],
              destino: contas[l.contaDestinoId],
              categoria: categorias[l.categoriaId],
              onTap: () => abrirLancamento(context, ref, l),
            ),
        ]),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(mesa ? Espacos.xg : Espacos.g, Espacos.g, mesa ? Espacos.xg : Espacos.g, 96),
      children: [cabecalho, const SizedBox(height: Espacos.m), totais, const SizedBox(height: Espacos.m), corpo],
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.rotulo, this.centavos, this.cor);
  final String rotulo;
  final int centavos;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: texto.bodySmall),
        Text(reais(centavos), style: texto.titleMedium?.copyWith(color: cor)),
      ],
    );
  }
}

/// Grade densa da web: uma linha por lançamento, colunas alinhadas.
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
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);

    Widget celula(String s, {int flex = 2, TextStyle? estilo, TextAlign? alinhar}) => Expanded(
          flex: flex,
          child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo ?? texto.bodyMedium, textAlign: alinhar),
        );

    Widget linha(List<Widget> filhos, {VoidCallback? onTap}) => InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Espacos.g, vertical: Espacos.p + 2),
            child: Row(children: filhos),
          ),
        );

    return Column(
      children: [
        linha([
          celula('Data', estilo: texto.bodySmall),
          celula('Descrição', flex: 5, estilo: texto.bodySmall),
          celula('Categoria', flex: 3, estilo: texto.bodySmall),
          celula('Conta', flex: 3, estilo: texto.bodySmall),
          celula('Situação', estilo: texto.bodySmall),
          celula('Valor', flex: 3, estilo: texto.bodySmall, alinhar: TextAlign.end),
        ]),
        const Divider(),
        for (final l in lancamentos)
          linha(onTap: () => aoTocar(l), [
            celula(diaPorExtenso(l.dia, hoje)),
            Expanded(
              flex: 5,
              child: _CelulaDeTexto(
                valor: l.descricao,
                sufixo: l.parcelaNumero != null ? '  ${l.parcelaNumero}/${l.parcelaTotal}' : '',
                aoMudar: (novo) => aoEditar(l, l.copiar(descricao: novo)),
              ),
            ),
            Expanded(
              flex: 3,
              child: l.ehTransferencia
                  ? Text('Transferência', style: texto.bodyMedium)
                  : _CelulaDeEscolha(
                      rotulo: categorias[l.categoriaId]?.nome ?? '—',
                      aoTocar: () async {
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
              estilo: texto.bodyMedium?.copyWith(
                color: l.previsto && l.data.compareTo(hoje) < 0 ? c.atencao : c.tintaSuave,
              ),
            ),
            celula(valorComSinal(l),
                flex: 3, alinhar: TextAlign.end, estilo: texto.titleMedium?.copyWith(color: corDoValor(context, l))),
          ]),
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
    final texto = Theme.of(context).textTheme;
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
          style: texto.bodyMedium,
        ),
      );
    }
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _terminar(salvar: false)},
      child: TextField(
        controller: controle,
        focusNode: _foco,
        style: texto.bodyMedium,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: Espacos.p, vertical: Espacos.p)),
        onSubmitted: (_) => _terminar(salvar: true),
      ),
    );
  }
}

class _CelulaDeEscolha extends StatelessWidget {
  const _CelulaDeEscolha({required this.rotulo, required this.aoTocar});
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: aoTocar,
        child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
      );
}
