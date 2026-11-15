import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';

/// Escolha de um item numa lista, em folha.
Future<T?> escolher<T>(
  BuildContext context, {
  required String titulo,
  required List<T> itens,
  required String Function(T) rotulo,
  String? Function(T)? detalhe,
  T? atual,
  bool permiteNenhum = false,
}) =>
    showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.p),
                child: Text(titulo, style: Theme.of(context).textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in itens)
                      ListTile(
                        title: Text(rotulo(item)),
                        subtitle: detalhe?.call(item) == null ? null : Text(detalhe!(item)!),
                        trailing: item == atual ? const Icon(Icons.check_rounded) : null,
                        onTap: () => Navigator.pop(context, item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

Future<String?> escolherDia(BuildContext context, String atual) async {
  final d = await showDatePicker(
    context: context,
    initialDate: diaDaChave(atual),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  return d == null ? null : chaveDoDia(d);
}

const rotulosDeConta = {
  'corrente': 'Conta corrente',
  'dinheiro': 'Dinheiro',
  'cartao': 'Cartão de crédito',
  'investimento': 'Investimento',
  'divida': 'Dívida',
};

/// Modo avançado: todos os detalhes de um lançamento, campo a campo.
/// Devolve a leitura ajustada, ou `null` se a pessoa desistir.
class FormularioAvancado extends StatefulWidget {
  const FormularioAvancado({
    super.key,
    required this.inicial,
    required this.contas,
    required this.categorias,
    required this.hoje,
    this.titulo = 'Detalhes do lançamento',
    this.permiteRepetir = true,
    this.rotuloDeSalvar = 'Pronto',
  });

  final Leitura inicial;
  final List<Conta> contas;
  final List<Categoria> categorias;
  final String hoje;
  final String titulo;
  final bool permiteRepetir;
  final String rotuloDeSalvar;

  @override
  State<FormularioAvancado> createState() => _FormularioAvancadoState();
}

class _FormularioAvancadoState extends State<FormularioAvancado> {
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
    Navigator.pop(
      context,
      _l.copiar(
        valorCentavos: valor,
        descricao: _descricao.text.trim(),
        parcelas: () => parcelas,
        recorrente: _repetir == 'mensal',
        categoriaId: () => _l.tipo == 'transferencia' ? null : _l.categoriaId,
        contaDestinoId: () => _l.tipo == 'transferencia' ? _l.contaDestinoId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = Cores.de(context);
    final contas = widget.contas.where((x) => !x.arquivada || x.id == _l.contaId).toList();
    final categorias = widget.categorias
        .where((x) => (!x.arquivada || x.id == _l.categoriaId) && x.tipo == (_l.tipo == 'entrada' ? 'entrada' : 'saida'))
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));

    Widget campo(String rotulo, String valor, VoidCallback aoTocar) => InkWell(
          onTap: aoTocar,
          borderRadius: Raios.m,
          child: InputDecorator(
            decoration: InputDecoration(labelText: rotulo, suffixIcon: const Icon(Icons.expand_more_rounded)),
            child: Text(valor, style: texto.bodyLarge),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'saida', label: Text('Saída')),
                  ButtonSegment(value: 'entrada', label: Text('Entrada')),
                  ButtonSegment(value: 'transferencia', label: Text('Transferência')),
                ],
                selected: {_l.tipo},
                onSelectionChanged: (s) => setState(() => _l = _l.copiar(tipo: s.first, categoriaId: () => null)),
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
              campo(_l.tipo == 'transferencia' ? 'Sai de' : 'Conta', _conta(_l.contaId)?.nome ?? 'Escolher', () async {
                final conta = await escolher<Conta>(context,
                    titulo: 'Conta', itens: contas, rotulo: (x) => x.nome, detalhe: (x) => rotulosDeConta[x.tipo], atual: _conta(_l.contaId));
                if (conta != null) setState(() => _l = _l.copiar(contaId: () => conta.id));
              }),
              if (_l.tipo == 'transferencia') ...[
                const SizedBox(height: Espacos.m),
                campo('Entra em', _conta(_l.contaDestinoId)?.nome ?? 'Escolher', () async {
                  final conta = await escolher<Conta>(context,
                      titulo: 'Conta de destino',
                      itens: contas.where((x) => x.id != _l.contaId).toList(),
                      rotulo: (x) => x.nome,
                      detalhe: (x) => rotulosDeConta[x.tipo],
                      atual: _conta(_l.contaDestinoId));
                  if (conta != null) setState(() => _l = _l.copiar(contaDestinoId: () => conta.id));
                }),
              ] else ...[
                const SizedBox(height: Espacos.m),
                campo(
                  'Categoria',
                  widget.categorias.where((x) => x.id == _l.categoriaId).firstOrNull?.nome ?? 'Sem categoria',
                  () async {
                    final escolhida = await escolher<Categoria?>(context,
                        titulo: 'Categoria',
                        itens: [null, ...categorias],
                        rotulo: (x) => x?.nome ?? 'Sem categoria',
                        atual: categorias.where((x) => x.id == _l.categoriaId).firstOrNull);
                    setState(() => _l = _l.copiar(categoriaId: () => escolhida?.id));
                  },
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
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'nao', label: Text('Não')),
                    ButtonSegment(value: 'parcelado', label: Text('Parcelado')),
                    ButtonSegment(value: 'mensal', label: Text('Todo mês')),
                  ],
                  selected: {_repetir},
                  onSelectionChanged: (s) => setState(() => _repetir = s.first),
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
              FilledButton(onPressed: _salvar, child: Text(widget.rotuloDeSalvar)),
            ],
          ),
        ),
      ),
    );
  }
}
