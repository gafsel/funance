import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';

import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'pecas.dart';

/// Abre uma folha inferior. É a única forma de abrir algo por cima da tela:
/// no celular ocupa a largura; na mesa fica centralizada, com largura máxima.
Future<T?> abrirFolha<T>(BuildContext context, WidgetBuilder builder, {double largura = 560, bool alta = false}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: largura),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: alta ? FractionallySizedBox(heightFactor: 0.92, child: builder(context)) : builder(context),
      ),
    );

/// Escolha de um item numa lista, em folha.
Future<T?> escolher<T>(
  BuildContext context, {
  required String titulo,
  required List<T> itens,
  required String Function(T) rotulo,
  String? Function(T)? detalhe,
  Widget Function(T)? antes,
  T? atual,
  bool permiteNenhum = false,
}) =>
    abrirFolha<T>(
      context,
      (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.p),
              child: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: Espacos.p),
                children: [
                  for (final item in itens)
                    Linha(
                      antes: antes?.call(item),
                      titulo: rotulo(item),
                      detalhe: detalhe?.call(item),
                      direita: item == atual ? const Icon(Icons.check_rounded, size: 18) : null,
                      aoTocar: () => Navigator.pop(context, item),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

/// Escolha de categoria, com o ícone e a cor de cada uma.
Future<Categoria?> escolherCategoria(BuildContext context, {required List<Categoria> itens, Categoria? atual}) =>
    escolher<Categoria>(
      context,
      titulo: 'Categoria',
      itens: itens,
      rotulo: (x) => x.nome,
      antes: (x) => SeloDaCategoria(categoria: x),
      atual: atual,
    );

/// Escolha de conta. Com muitas contas, e várias no mesmo banco, a lista é
/// organizada para achar sem ler: primeiro as usadas há pouco; depois as de
/// quem está lançando, agrupadas por banco; depois as dos outros. Cada linha
/// mostra o logo do banco com a foto do titular.
Future<Conta?> escolherConta(
  BuildContext context,
  WidgetRef ref, {
  String titulo = 'Conta',
  bool Function(Conta)? filtro,
  String? atualId,
}) {
  final membros = ref.read(membrosProvider).valueOrNull ?? const <Membro>[];
  final eu = ref.read(authProvider).valueOrNull?.uid;
  final saldos = ref.read(saldosProvider);
  final uso = ref.read(usoDasContasProvider);
  final contas = (ref.read(contasProvider).valueOrNull ?? const <Conta>[])
      .where((c) => (!c.arquivada || c.id == atualId) && (filtro == null || filtro(c)))
      .toList();

  int grupoDoDono(Conta c) => c.donos.contains(eu) && !c.conjunta ? 0 : (c.donos.contains(eu) ? 1 : (c.donos.isEmpty ? 2 : 3));
  int ordemDoTipo(Conta c) => const {'corrente': 0, 'dinheiro': 1, 'cartao': 2, 'investimento': 3, 'divida': 4}[c.tipo] ?? 5;
  contas.sort((a, b) {
    final dono = grupoDoDono(a).compareTo(grupoDoDono(b));
    if (dono != 0) return dono;
    final banco = (a.banco ?? 'zz').compareTo(b.banco ?? 'zz');
    if (banco != 0) return banco;
    final tipo = ordemDoTipo(a).compareTo(ordemDoTipo(b));
    return tipo != 0 ? tipo : a.nome.compareTo(b.nome);
  });
  final recentes = (contas.where((c) => (uso[c.id] ?? 0) > 0).toList()
        ..sort((a, b) => (uso[b.id] ?? 0).compareTo(uso[a.id] ?? 0)))
      .take(3)
      .toList();
  const titulos = ['Suas', 'Conjuntas', 'Sem titular', 'De outras pessoas'];

  return abrirFolha<Conta>(context, (context) {
    final t = Theme.of(context).textTheme;
    Widget linha(Conta c) => Linha(
          antes: SeloDaConta(conta: c, membros: membros),
          titulo: c.nome,
          detalhe: [rotulosDeConta[c.tipo] ?? c.tipo, titularidade(c, membros, eu)].where((x) => x.isNotEmpty).join(' · '),
          direita: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(reais(saldos[c.id] ?? 0), style: Textos.valor(context, tamanho: 13, cor: Cores.de(context).tinta2)),
            if (c.id == atualId) ...[const SizedBox(width: 6), const Icon(Icons.check_rounded, size: 18)],
          ]),
          aoTocar: () => Navigator.pop(context, c),
        );
    Widget cabecalho(String texto) => Padding(
          padding: const EdgeInsets.fromLTRB(Espacos.g, Espacos.m, Espacos.g, 2),
          child: Text(texto.toUpperCase(), style: Textos.sobrancelha(context)),
        );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, 0),
            child: Text(titulo, style: t.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Espacos.p),
              children: [
                if (contas.isEmpty) const Vazio('Nenhuma conta para escolher.'),
                if (recentes.length > 1 && contas.length > 4) ...[
                  cabecalho('Usadas há pouco'),
                  for (final c in recentes) linha(c),
                ],
                for (var g = 0; g < 4; g++)
                  if (contas.any((c) => grupoDoDono(c) == g)) ...[
                    cabecalho(titulos[g]),
                    for (final c in contas.where((c) => grupoDoDono(c) == g)) linha(c),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  });
}

/// Escolha de dia, em folha, com o calendário à mostra.
Future<String?> escolherDia(BuildContext context, String atual) => abrirFolha<String>(
      context,
      (context) => Padding(
        padding: const EdgeInsets.fromLTRB(Espacos.p, 0, Espacos.p, Espacos.p),
        child: CalendarDatePicker(
          initialDate: diaDaChave(atual),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          onDateChanged: (d) => Navigator.pop(context, chaveDoDia(d)),
        ),
      ),
      largura: 380,
    );

const rotulosDeConta = {
  'corrente': 'Conta corrente',
  'dinheiro': 'Dinheiro',
  'cartao': 'Cartão de crédito',
  'investimento': 'Investimento',
  'divida': 'Dívida',
};

/// Modo avançado: todos os detalhes de um lançamento, campo a campo.
/// Devolve a leitura ajustada, ou `null` se a pessoa desistir.
class FormularioAvancado extends ConsumerStatefulWidget {
  const FormularioAvancado({
    super.key,
    required this.inicial,
    required this.contas,
    required this.categorias,
    required this.hoje,
    this.titulo = 'Detalhes do lançamento',
    this.permiteRepetir = true,
    this.rotuloDeSalvar = 'Pronto',
    this.contrapartes,
    this.aoCriarContraparte,
    this.aoConcluir,
  });

  /// Com isto, o formulário não é uma tela: é só o conteúdo, para ficar
  /// dentro de uma folha que já está aberta. Em vez de fechar a tela, ele
  /// devolve a leitura por aqui.
  final void Function(Leitura)? aoConcluir;

  /// Clientes e fornecedores do espaço. `null` esconde o campo (espaço
  /// pessoal).
  final List<Contraparte>? contrapartes;
  final Future<Contraparte?> Function(String nome, String tipo)? aoCriarContraparte;

  final Leitura inicial;
  final List<Conta> contas;
  final List<Categoria> categorias;
  final String hoje;
  final String titulo;
  final bool permiteRepetir;
  final String rotuloDeSalvar;

  @override
  ConsumerState<FormularioAvancado> createState() => _FormularioAvancadoState();
}

class _FormularioAvancadoState extends ConsumerState<FormularioAvancado> {
  late Leitura _l = widget.inicial;
  late final _valor = TextEditingController(
    text: _l.valorCentavos > 0 ? reais(_l.valorCentavos, comSimbolo: false) : '',
  );
  late final _descricao = TextEditingController(text: _l.descricao);
  late final _parcelas = TextEditingController(text: '${_l.parcelas ?? 2}');
  late String _repetir = _l.parcelas != null ? 'parcelado' : (_l.recorrente ? 'mensal' : 'nao');
  String? _erro;

  @override
  void dispose() {
    _valor.dispose();
    _descricao.dispose();
    _parcelas.dispose();
    super.dispose();
  }

  Conta? _conta(String? id) => widget.contas.where((c) => c.id == id).firstOrNull;

  /// Nome da conta com o titular, para não confundir duas de mesmo nome.
  String _nomeDaConta(String? id) {
    final conta = _conta(id);
    if (conta == null) return 'Escolher';
    final de = titularidade(conta, ref.read(membrosProvider).valueOrNull ?? const [], ref.read(authProvider).valueOrNull?.uid);
    return de.isEmpty ? conta.nome : '${conta.nome} · $de';
  }

  /// Criadas nesta tela, para aparecerem antes de a lista do banco chegar.
  final _criadas = <Contraparte>[];

  Future<void> _escolherContraparte() async {
    final tipo = _l.tipo == 'entrada' ? 'cliente' : 'fornecedor';
    const novo = Contraparte(id: '', nome: 'Novo…', tipo: '');
    const nenhum = Contraparte(id: '-', nome: 'Nenhum', tipo: '');
    final opcoes = [...widget.contrapartes!, ..._criadas].where((x) => x.tipo == tipo).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final escolhida = await escolher<Contraparte>(context,
        titulo: tipo == 'cliente' ? 'Cliente' : 'Fornecedor', itens: [nenhum, ...opcoes, novo], rotulo: (x) => x.nome);
    if (escolhida == null || !mounted) return;
    if (escolhida.id == '-') return setState(() => _l = _l.copiar(contraparteId: () => null));
    if (escolhida.id.isNotEmpty) return setState(() => _l = _l.copiar(contraparteId: () => escolhida.id));

    final nome = TextEditingController();
    final digitado = await abrirFolha<String>(
      context,
      (context) => Padding(
        padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tipo == 'cliente' ? 'Novo cliente' : 'Novo fornecedor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Espacos.m),
            TextField(
              controller: nome,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: Espacos.g),
            Acoes(filhos: [FilledButton(onPressed: () => Navigator.pop(context, nome.text), child: const Text('Criar'))]),
          ],
        ),
      ),
      largura: 420,
    );
    nome.dispose();
    if (digitado == null || digitado.trim().isEmpty) return;
    final criada = await widget.aoCriarContraparte?.call(digitado.trim(), tipo);
    if (criada != null && mounted) {
      setState(() {
        _criadas.add(criada);
        _l = _l.copiar(contraparteId: () => criada.id);
      });
    }
  }

  void _salvar() {
    final valor = lerCentavos(_valor.text);
    if (valor == null) return setState(() => _erro = 'Informe o valor.');
    if (_l.contaId == null) return setState(() => _erro = 'Escolha a conta.');
    if (_l.tipo == 'transferencia' && (_l.contaDestinoId == null || _l.contaDestinoId == _l.contaId)) {
      return setState(() => _erro = 'Escolha a conta de destino, diferente da de origem.');
    }
    final parcelas = _repetir == 'parcelado' ? int.tryParse(_parcelas.text) : null;
    if (_repetir == 'parcelado' && (parcelas == null || parcelas < 2 || parcelas > 120)) {
      return setState(() => _erro = 'Parcelas: de 2 a 120.');
    }
    final pronta = _l.copiar(
      valorCentavos: valor,
      descricao: _descricao.text.trim(),
      parcelas: () => parcelas,
      recorrente: _repetir == 'mensal',
      categoriaId: () => _l.tipo == 'transferencia' ? null : _l.categoriaId,
      contaDestinoId: () => _l.tipo == 'transferencia' ? _l.contaDestinoId : null,
    );
    final concluir = widget.aoConcluir;
    if (concluir != null) {
      concluir(pronta);
    } else {
      Navigator.pop(context, pronta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final categorias = widget.categorias
        .where((x) => (!x.arquivada || x.id == _l.categoriaId) && x.tipo == (_l.tipo == 'entrada' ? 'entrada' : 'saida'))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final categoriaAtual = widget.categorias.where((x) => x.id == _l.categoriaId).firstOrNull;

    Widget campo(String rotulo, String valor, VoidCallback aoTocar, {Widget? antes}) => InkWell(
          onTap: aoTocar,
          borderRadius: Raios.m,
          child: InputDecorator(
            decoration: InputDecoration(labelText: rotulo, suffixIcon: const Icon(Icons.expand_more_rounded, size: 20)),
            child: Row(children: [
              if (antes != null) ...[antes, const SizedBox(width: 8)],
              Expanded(child: Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis, style: texto.bodyMedium)),
            ]),
          ),
        );

    final campos = <Widget>[
              Segmentos<String>(
                opcoes: const [('saida', 'Saída'), ('entrada', 'Entrada'), ('transferencia', 'Transferência')],
                valor: _l.tipo,
                aoMudar: (v) => setState(() => _l = _l.copiar(tipo: v, categoriaId: () => null)),
              ),
              const SizedBox(height: Espacos.g),
              TextField(
                controller: _valor,
                autofocus: widget.inicial.valorCentavos == 0,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: const InputDecoration(labelText: 'Valor', prefixText: r'R$ '),
              ),
              const SizedBox(height: Espacos.m),
              TextField(
                controller: _descricao,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: Espacos.m),
              campo('Data', diaPorExtenso(_l.data, widget.hoje), () async {
                final dia = await escolherDia(context, _l.data);
                if (dia != null) setState(() => _l = _l.copiar(data: dia));
              }),
              const SizedBox(height: Espacos.m),
              campo(_l.tipo == 'transferencia' ? 'Sai de' : 'Conta', _nomeDaConta(_l.contaId), () async {
                final conta = await escolherConta(context, ref, atualId: _l.contaId);
                if (conta != null) setState(() => _l = _l.copiar(contaId: () => conta.id));
              }, antes: _conta(_l.contaId) == null ? null : SeloDaConta(conta: _conta(_l.contaId)!, membros: membros, tamanho: 26)),
              if (_l.tipo == 'transferencia') ...[
                const SizedBox(height: Espacos.m),
                campo('Entra em', _nomeDaConta(_l.contaDestinoId), () async {
                  final conta = await escolherConta(context, ref,
                      titulo: 'Conta de destino', filtro: (x) => x.id != _l.contaId, atualId: _l.contaDestinoId);
                  if (conta != null) setState(() => _l = _l.copiar(contaDestinoId: () => conta.id));
                }, antes: _conta(_l.contaDestinoId) == null ? null : SeloDaConta(conta: _conta(_l.contaDestinoId)!, membros: membros, tamanho: 26)),
              ] else ...[
                const SizedBox(height: Espacos.m),
                campo(
                  'Categoria',
                  widget.categorias.where((x) => x.id == _l.categoriaId).firstOrNull?.nome ?? 'Sem categoria',
                  () async {
                    final escolhida = await escolherCategoria(context,
                        itens: categorias, atual: categorias.where((x) => x.id == _l.categoriaId).firstOrNull);
                    if (escolhida != null) setState(() => _l = _l.copiar(categoriaId: () => escolhida.id));
                  },
                  antes: categoriaAtual == null ? null : SeloDaCategoria(categoria: categoriaAtual, tamanho: 26),
                ),
              ],
              if (widget.contrapartes != null && _l.tipo != 'transferencia') ...[
                const SizedBox(height: Espacos.m),
                campo(
                  _l.tipo == 'entrada' ? 'Cliente' : 'Fornecedor',
                  [...widget.contrapartes!, ..._criadas].where((x) => x.id == _l.contraparteId).firstOrNull?.nome ?? 'Nenhum',
                  _escolherContraparte,
                ),
              ],
              const SizedBox(height: Espacos.g),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Já aconteceu'),
                subtitle: Text(_l.efetivado ? 'Entra no saldo na data acima.' : 'Fica agendado; não mexe no saldo ainda.'),
                value: _l.efetivado,
                onChanged: (v) => setState(() => _l = _l.copiar(efetivado: v)),
              ),
              if (widget.permiteRepetir) ...[
                const SizedBox(height: Espacos.p),
                Text('Repetir', style: texto.titleMedium),
                const SizedBox(height: Espacos.p),
                Segmentos<String>(
                  opcoes: const [('nao', 'Não'), ('parcelado', 'Parcelado'), ('mensal', 'Todo mês')],
                  valor: _repetir,
                  aoMudar: (v) => setState(() => _repetir = v),
                ),
                if (_repetir == 'parcelado') ...[
                  const SizedBox(height: Espacos.m),
                  TextField(
                    controller: _parcelas,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Número de parcelas',
                      helperText: 'O valor acima é o total da compra.',
                    ),
                  ),
                ],
              ],
              if (_erro != null) ...[
                const SizedBox(height: Espacos.m),
                Text(_erro!, style: texto.bodyMedium?.copyWith(color: c.problema)),
              ],
              const SizedBox(height: Espacos.xg),
              Acoes(filhos: [FilledButton(onPressed: _salvar, child: Text(widget.rotuloDeSalvar))]),
    ];

    if (widget.aoConcluir != null) {
      return ListView(padding: EdgeInsets.zero, children: campos);
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Pagina(larguraMaxima: 520, centralizada: true, filhos: campos),
    );
  }
}
