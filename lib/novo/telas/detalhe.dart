import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dados/provedores.dart';
import '../dados/repositorio.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../regras/leitura_frase.dart';
import '../tema/tema_novo.dart';
import 'formulario.dart';
import 'pecas.dart';

void _avisar(ScaffoldMessengerState mensageiro, String texto, Future<void> Function() desfazer) => mensageiro
  ..clearSnackBars()
  ..showSnackBar(SnackBar(
    duration: const Duration(seconds: 8),
    content: Text(texto),
    action: SnackBarAction(label: 'Desfazer', onPressed: desfazer),
  ));

/// Detalhe de um lançamento, em folha. O que se faz com frequência fica em
/// destaque (pagar ou receber o que está agendado); editar e apagar, que
/// são raros, ficam no menu.
Future<void> abrirLancamento(BuildContext context, WidgetRef ref, Lancamento l) =>
    abrirFolha<void>(context, (_) => _DetalheDoLancamento(lancamentoId: l.id, inicial: l), largura: 480);

class _DetalheDoLancamento extends ConsumerWidget {
  const _DetalheDoLancamento({required this.lancamentoId, required this.inicial});
  final String lancamentoId;
  final Lancamento inicial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final t = Theme.of(context).textTheme;
    final c = Cores.de(context);
    // O lançamento pode mudar com a folha aberta (foi pago, foi editado).
    final l = ref.watch(recentesProvider).where((x) => x.id == lancamentoId).firstOrNull ??
        (ref.watch(previstosProvider).valueOrNull ?? const <Lancamento>[]).where((x) => x.id == lancamentoId).firstOrNull ??
        inicial;
    final contas = {for (final x in ref.watch(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final membros = ref.watch(membrosProvider).valueOrNull ?? const <Membro>[];
    final nomes = ref.watch(nomesDasContasProvider);
    final categoria = categorias[l.categoriaId];
    final atrasado = l.previsto && l.data.compareTo(hoje) < 0;
    final repo = ref.watch(repositorioProvider);

    Widget campo(String rotulo, Widget valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            SizedBox(width: 92, child: Text(rotulo, style: t.bodySmall)),
            Expanded(child: valor),
          ]),
        );
    Widget texto(String s, {Color? cor}) =>
        Text(s, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontSize: 13.5, color: cor));
    Widget conta(String? id) => Row(children: [
          SelosDoLancamento(origem: contas[id], membros: membros),
          const SizedBox(width: 8),
          Expanded(child: texto(nomes[id] ?? '?')),
        ]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Espacos.g, 0, 6, Espacos.g),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              l.ehTransferencia
                  ? Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: c.suave, shape: BoxShape.circle),
                      child: Icon(Icons.swap_horiz_rounded, size: 22, color: c.tinta2),
                    )
                  : SeloDaCategoria(categoria: categoria, tamanho: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.descricao.isEmpty ? 'Sem descrição' : l.descricao, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleLarge?.copyWith(fontSize: 18)),
                    Text(
                      l.ehTransferencia ? 'Transferência' : (categoria?.nome ?? 'Sem categoria'),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Mais ações',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (acao) => _acao(context, ref, l, acao),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  if (l.efetivado && l.previstoCentavos != null)
                    const PopupMenuItem(value: 'desefetivar', child: Text('Voltar para agendado')),
                  PopupMenuItem(value: 'apagar', child: Text('Excluir', style: t.bodyMedium?.copyWith(color: c.problema))),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Espacos.m),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valorComSinal(l), style: Textos.numerao(context, tamanho: 32).copyWith(color: corDoValor(context, l))),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (l.efetivado)
                    Etiqueta(l.ehEntrada ? 'Recebido' : (l.ehTransferencia ? 'Feito' : 'Pago'), tom: Tom.bom)
                  else if (atrasado)
                    const Etiqueta('Atrasado', tom: Tom.atencao)
                  else
                    const Etiqueta('Agendado', tom: Tom.calor),
                  if (l.parcelaNumero != null) Etiqueta('Parcela ${l.parcelaNumero} de ${l.parcelaTotal}'),
                  if (l.serieId != null && l.parcelaNumero == null) const Etiqueta('Todo mês'),
                ]),
                const SizedBox(height: Espacos.m),
                const Divider(),
                const SizedBox(height: 4),
                if (l.previsto)
                  campo('Vence', texto(diaPorExtenso(l.data, hoje), cor: atrasado ? c.atencao : null))
                else ...[
                  campo(l.ehEntrada ? 'Recebido' : 'Pago', texto(diaPorExtenso(l.dia, hoje))),
                  if (l.previstoCentavos != null && l.data != l.dia) campo('Vencia', texto(diaPorExtenso(l.data, hoje))),
                  if (l.previstoCentavos != null && l.previstoCentavos != l.realizadoCentavos)
                    campo('Previsto', texto(reais(l.previstoCentavos!))),
                ],
                campo(l.ehTransferencia ? 'Sai de' : 'Conta', conta(l.contaId)),
                if (l.ehTransferencia) campo('Entra em', conta(l.contaDestinoId)),
                if (l.previsto) ...[
                  const SizedBox(height: Espacos.m),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    onPressed: repo == null
                        ? null
                        : () async {
                            final mensageiro = ScaffoldMessenger.of(context);
                            final navegador = Navigator.of(context);
                            await repo.efetivar(l, dia: hoje);
                            navegador.pop();
                            _avisar(mensageiro, l.ehEntrada ? 'Marcado como recebido hoje.' : 'Marcado como pago hoje.', () => repo.gravar(l));
                          },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(l.ehEntrada ? 'Recebi hoje, ${reais(l.valorCentavos)}' : 'Paguei hoje, ${reais(l.valorCentavos)}'),
                  ),
                  const SizedBox(height: Espacos.p),
                  OutlinedButton(
                    onPressed: () async {
                      final navegador = Navigator.of(context);
                      final pagou = await abrirPagamento(context, ref, l);
                      if (pagou) navegador.pop();
                    },
                    child: Text(l.ehEntrada ? 'Recebi com outra data, valor ou conta' : 'Paguei com outra data, valor ou conta'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acao(BuildContext context, WidgetRef ref, Lancamento l, String acao) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    final mensageiro = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    switch (acao) {
      case 'desefetivar':
        await repo.gravar(l.copiar(situacao: 'previsto', realizadoCentavos: () => null, dataEfetiva: () => null));
        navegador.pop();
        _avisar(mensageiro, 'Voltou para agendado.', () => repo.gravar(l));
      case 'apagar':
        await repo.apagar(l.id);
        navegador.pop();
        _avisar(mensageiro, 'Lançamento excluído.', () => repo.gravar(l));
      case 'editar':
        final editado = await _editar(context, ref, repo, l);
        if (editado) navegador.pop();
    }
  }
}

Future<bool> _editar(BuildContext context, WidgetRef ref, Repositorio repo, Lancamento l) async {
  final hoje = ref.read(hojeProvider);
  final mensageiro = ScaffoldMessenger.of(context);
  final editada = await Navigator.of(context).push<Leitura>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => FormularioAvancado(
      titulo: 'Editar lançamento',
      rotuloDeSalvar: 'Salvar',
      permiteRepetir: false,
      hoje: hoje,
      contas: ref.read(contasProvider).valueOrNull ?? const <Conta>[],
      categorias: ref.read(categoriasProvider).valueOrNull ?? const <Categoria>[],
      inicial: Leitura(
        tipo: l.tipo,
        descricao: l.descricao,
        valorCentavos: l.valorCentavos,
        data: l.dia,
        contaId: l.contaId,
        contaDestinoId: l.contaDestinoId,
        categoriaId: l.categoriaId,
        efetivado: l.efetivado,
        contraparteId: l.contraparteId,
      ),
      contrapartes: (ref.read(espacoAtualProvider)?.ehEmpresa ?? false)
          ? (ref.read(contrapartesProvider).valueOrNull ?? const <Contraparte>[])
          : null,
      aoCriarContraparte: (nome, tipo) async {
        final id = 'cp-${DateTime.now().microsecondsSinceEpoch}';
        await repo.gravarContraparte(id, nome: nome, tipo: tipo);
        return Contraparte(id: id, nome: nome, tipo: tipo);
      },
    ),
  ));
  if (editada == null) return false;
  final novo = l.copiar(
    tipo: editada.tipo,
    descricao: editada.descricao,
    contaId: editada.contaId,
    contaDestinoId: () => editada.contaDestinoId,
    categoriaId: () => editada.categoriaId,
    contraparteId: () => editada.contraparteId,
    situacao: editada.efetivado ? 'efetivado' : 'previsto',
    // O planejado só muda se o lançamento continua agendado; pagar com
    // valor diferente não reescreve o que tinha sido previsto.
    previstoCentavos: () => editada.efetivado ? l.previstoCentavos : editada.valorCentavos,
    realizadoCentavos: () => editada.efetivado ? editada.valorCentavos : null,
    data: editada.efetivado && l.previstoCentavos != null ? l.data : editada.data,
    dataEfetiva: () => editada.efetivado ? editada.data : null,
  );
  await repo.gravar(novo);
  _avisar(mensageiro, 'Alteração salva.', () => repo.gravar(l));
  return true;
}

/// Pagar (ou receber) um agendado dizendo quando, quanto e de qual conta.
/// Devolve `true` se o pagamento foi registrado.
Future<bool> abrirPagamento(BuildContext context, WidgetRef ref, Lancamento l) async {
  final repo = ref.read(repositorioProvider);
  if (repo == null) return false;
  final hoje = ref.read(hojeProvider);
  final mensageiro = ScaffoldMessenger.of(context);
  final campo = TextEditingController(text: reais(l.valorCentavos, comSimbolo: false));
  var dia = hoje;
  var contaId = l.contaId;
  String? erro;

  final pago = await abrirFolha<bool>(
    context,
    (context) => StatefulBuilder(builder: (context, definir) {
      final t = Theme.of(context).textTheme;
      final c = Cores.de(context);
      final contas = {for (final x in ref.read(contasProvider).valueOrNull ?? const <Conta>[]) x.id: x};
      final membros = ref.read(membrosProvider).valueOrNull ?? const <Membro>[];
      final conta = contas[contaId];
      final valor = lerCentavos(campo.text);
      final previsto = l.previstoCentavos;

      Widget seletor(String rotulo, Widget filho, VoidCallback aoTocar) => InkWell(
            borderRadius: Raios.m,
            onTap: aoTocar,
            child: InputDecorator(
              decoration: InputDecoration(labelText: rotulo, suffixIcon: const Icon(Icons.expand_more_rounded, size: 20)),
              child: filho,
            ),
          );

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Espacos.g, 0, Espacos.g, Espacos.g),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.ehEntrada ? 'Receber' : 'Pagar', style: t.titleLarge),
            Text(l.descricao.isEmpty ? 'Sem descrição' : l.descricao, style: t.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
            const SizedBox(height: Espacos.m),
            TextField(
              controller: campo,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
              onChanged: (_) => definir(() => erro = null),
              decoration: InputDecoration(
                labelText: l.ehEntrada ? 'Valor recebido' : 'Valor pago',
                prefixText: r'R$ ',
                helperText: previsto != null && valor != null && valor != previsto
                    ? 'Estava previsto ${reais(previsto)}: ${valor > previsto ? '${reais(valor - previsto)} a mais' : '${reais(previsto - valor)} a menos'}.'
                    : null,
              ),
            ),
            const SizedBox(height: Espacos.m),
            seletor('Data', Text(diaPorExtenso(dia, hoje), style: t.bodyMedium), () async {
              final escolhido = await escolherDia(context, dia);
              if (escolhido != null) definir(() => dia = escolhido);
            }),
            const SizedBox(height: Espacos.m),
            seletor(
              l.ehEntrada ? 'Entrou em' : 'Saiu de',
              Row(children: [
                if (conta != null) ...[SeloDaConta(conta: conta, membros: membros, tamanho: 26), const SizedBox(width: 8)],
                Expanded(
                  child: Text(ref.read(nomesDasContasProvider)[contaId] ?? 'Escolher', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium),
                ),
              ]),
              () async {
                final escolhida = await escolherConta(context, ref,
                    titulo: l.ehEntrada ? 'Entrou em qual conta?' : 'Saiu de qual conta?',
                    filtro: (x) => x.id != l.contaDestinoId,
                    atualId: contaId);
                if (escolhida != null) definir(() => contaId = escolhida.id);
              },
            ),
            if (erro != null) ...[
              const SizedBox(height: Espacos.m),
              Text(erro!, style: t.bodyMedium?.copyWith(fontSize: 13, color: c.problema)),
            ],
            const SizedBox(height: Espacos.g),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
              onPressed: () {
                if (lerCentavos(campo.text) == null) return definir(() => erro = 'Informe o valor.');
                if (dia.compareTo(hoje) > 0) return definir(() => erro = 'A data do pagamento não pode ser no futuro.');
                Navigator.pop(context, true);
              },
              child: Text(l.ehEntrada ? 'Confirmar recebimento' : 'Confirmar pagamento'),
            ),
          ],
        ),
      );
    }),
    largura: 440,
  );
  final valor = lerCentavos(campo.text);
  campo.dispose();
  if (pago != true || valor == null) return false;

  await repo.efetivar(l, dia: dia, valorCentavos: valor, contaId: contaId);
  _avisar(mensageiro, '${l.ehEntrada ? 'Recebido' : 'Pago'}: ${reais(valor)}, ${diaPorExtenso(dia, hoje)}.', () => repo.gravar(l));
  return true;
}
