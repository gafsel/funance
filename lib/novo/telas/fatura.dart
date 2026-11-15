import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'detalhe.dart';
import 'formulario.dart';
import 'pecas.dart';

void abrirCartao(BuildContext context, Conta cartao) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TelaCartao(cartao: cartao)));

/// Faturas de um cartão: a em aberto em destaque, as outras em lista.
class TelaCartao extends ConsumerWidget {
  const TelaCartao({super.key, required this.cartao});
  final Conta cartao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final faturas = (ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[])
        .where((f) => f.contaId == cartao.id && (f.totalCentavos != 0 || f.pagoCentavos != 0))
        .toList()
      ..sort((a, b) => b.vencimento.compareTo(a.vencimento));
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(cartao.nome), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
              Text(
                'Fecha dia ${cartao.diaFechamento ?? 5}, vence dia ${cartao.diaVencimento ?? 10}. '
                'A compra conta como gasto no mês em que foi feita; pagar a fatura não conta de novo.',
                style: texto.bodySmall,
              ),
              const SizedBox(height: Espacos.m),
              if (faturas.isEmpty) const Vazio('Nenhuma fatura neste cartão ainda.'),
              for (final f in faturas)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacos.p),
                  child: Cartao(
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => TelaFatura(cartao: cartao, faturaId: f.id))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vence ${diaPorExtenso(f.vencimento, hoje)}', style: texto.titleMedium),
                              Text(
                                f.quitada
                                    ? 'Paga'
                                    : (f.fechamento.compareTo(hoje) > 0 ? 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}' : 'Fechada'),
                                style: texto.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(reais(f.totalCentavos), style: texto.titleMedium),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

final _comprasProvider = StreamProvider.family<List<Lancamento>, Fatura>((ref, fatura) {
  final repo = ref.watch(repositorioProvider);
  return repo == null ? Stream.value(const []) : repo.comprasDaFatura(fatura);
});

class TelaFatura extends ConsumerWidget {
  const TelaFatura({super.key, required this.cartao, required this.faturaId});
  final Conta cartao;
  final String faturaId;

  Future<void> _pagar(BuildContext context, WidgetRef ref, Fatura f) async {
    final repo = ref.read(repositorioProvider);
    if (repo == null) return;
    final hoje = ref.read(hojeProvider);
    final contas = (ref.read(contasProvider).valueOrNull ?? const <Conta>[]).where((x) => x.ehDeUso && !x.arquivada).toList();
    final saldos = ref.read(saldosProvider);
    final mensageiro = ScaffoldMessenger.of(context);
    final origem = await escolher<Conta>(
      context,
      titulo: 'Pagar ${reais(f.abertoCentavos)} com',
      itens: contas,
      rotulo: (x) => x.nome,
      detalhe: (x) => 'Saldo ${reais(saldos[x.id] ?? 0)}',
    );
    if (origem == null) return;
    final pagamento = Lancamento(
      id: const Uuid().v4(),
      tipo: 'transferencia',
      descricao: 'Fatura ${cartao.nome}',
      realizadoCentavos: f.abertoCentavos,
      data: f.vencimento,
      dataEfetiva: hoje,
      situacao: 'efetivado',
      contaId: origem.id,
      contaDestinoId: cartao.id,
      pagaFaturaId: f.id,
      autorId: ref.read(authProvider).valueOrNull?.uid,
    );
    await repo.gravar(pagamento);
    mensageiro
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 8),
        content: Text('Fatura paga com ${origem.nome}. Não conta como gasto.'),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.apagar(pagamento.id)),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoje = ref.watch(hojeProvider);
    final c = Cores.de(context);
    final texto = Theme.of(context).textTheme;
    final f = (ref.watch(faturasProvider).valueOrNull ?? const <Fatura>[]).where((x) => x.id == faturaId).firstOrNull;
    if (f == null) {
      return Scaffold(appBar: AppBar(), body: const Vazio('Esta fatura não existe mais.'));
    }
    final compras = (ref.watch(_comprasProvider(f)).valueOrNull ?? const <Lancamento>[]).toList()
      ..sort((a, b) => b.dia.compareTo(a.dia));
    final categorias = {for (final x in ref.watch(categoriasProvider).valueOrNull ?? const <Categoria>[]) x.id: x};
    final somaListada = compras.fold<int>(
        0, (s, l) => s + (l.contaId == cartao.id && !l.ehEntrada ? l.valorCentavos : -l.valorCentavos));

    return Scaffold(
      appBar: AppBar(title: Text('Fatura de ${cartao.nome}'), backgroundColor: c.fundo, surfaceTintColor: c.fundo),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(Espacos.g),
            children: [
              Cartao(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vence ${diaPorExtenso(f.vencimento, hoje)}', style: texto.bodyMedium?.copyWith(color: c.tintaSuave)),
                    Text(reais(f.totalCentavos), style: texto.displaySmall),
                    Text(
                      'Compras de ${diaPorExtenso(f.inicio, hoje)} a ${diaPorExtenso(f.fim, hoje)}.'
                      '${f.pagoCentavos > 0 ? ' Já pago: ${reais(f.pagoCentavos)}.' : ''}',
                      style: texto.bodySmall,
                    ),
                    if (f.abertoCentavos > 0) ...[
                      const SizedBox(height: Espacos.m),
                      FilledButton(
                        onPressed: () => _pagar(context, ref, f),
                        child: Text('Pagar ${reais(f.abertoCentavos)}'),
                      ),
                    ],
                  ],
                ),
              ),
              const TituloDeSecao('Compras'),
              Cartao(
                padding: EdgeInsets.zero,
                child: compras.isEmpty
                    ? const Vazio('Nenhuma compra nesta fatura.')
                    : Column(children: [
                        for (final l in compras)
                          LinhaDeLancamento(
                            lancamento: l,
                            hoje: hoje,
                            conta: cartao,
                            categoria: categorias[l.categoriaId],
                            onTap: () => abrirLancamento(context, ref, l),
                          ),
                      ]),
              ),
              if (compras.isNotEmpty && somaListada != f.totalCentavos)
                Padding(
                  padding: const EdgeInsets.only(top: Espacos.p),
                  child: Text(
                    'As compras listadas somam ${reais(somaListada)}. A diferença para o total pode vir de compras em fim de semana ou feriado perto do fechamento, que entram no ciclo seguinte, ou da dívida inicial do cartão.',
                    style: texto.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
