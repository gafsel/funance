import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../dados/provedores.dart';
import '../modelo/modelos.dart';
import '../regras/formatos.dart';
import '../tema/tema_novo.dart';
import 'conta.dart';
import 'detalhe.dart';
import 'entrada.dart';
import 'lancar.dart';
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
      appBar: AppBar(title: Text(cartao.nome)),
      body: Pagina(
        larguraMaxima: 640,
        centralizada: true,
        filhos: [
          Text(
            'Fecha dia ${cartao.diaFechamento ?? 5}, vence dia ${cartao.diaVencimento ?? 10}. '
            'A compra conta como gasto no mês em que foi feita; pagar a fatura não conta de novo.',
            style: texto.bodySmall,
          ),
          const SizedBox(height: Espacos.m),
          Wrap(spacing: Espacos.p, runSpacing: Espacos.p, children: [
            BotaoPequeno('Lançar neste cartão', icone: Icons.add_rounded, cheio: true, aoTocar: () => abrirLancar(context, contaId: cartao.id)),
            BotaoPequeno('Importar fatura', icone: Icons.upload_file_rounded, aoTocar: () => abrirImportacao(context, contaId: cartao.id)),
            BotaoPequeno('Extrato e titulares', aoTocar: () => abrirConta(context, cartao.id)),
          ]),
          const TituloDeSecao('Faturas'),
          if (faturas.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma fatura neste cartão ainda.'))
          else
            Lista(filhos: [
              for (final f in faturas)
                Linha(
                  titulo: 'Vence ${diaPorExtenso(f.vencimento, hoje)}',
                  detalhe: f.quitada
                      ? 'Paga'
                      : (f.fechamento.compareTo(hoje) > 0 ? 'Aberta, fecha ${diaPorExtenso(f.fechamento, hoje)}' : 'Fechada'),
                  corDoDetalhe: !f.quitada && f.vencimento.compareTo(hoje) < 0 ? c.atencao : null,
                  direita: Text(reais(f.totalCentavos), style: Textos.valor(context)),
                  aoTocar: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => TelaFatura(cartao: cartao, faturaId: f.id))),
                ),
            ]),
        ],
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
    final mensageiro = ScaffoldMessenger.of(context);
    final origem = await escolherConta(context, ref, titulo: 'Pagar ${reais(f.abertoCentavos)} com', filtro: (x) => x.ehDeUso);
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
      appBar: AppBar(title: Text('Fatura de ${cartao.nome}')),
      body: Pagina(
        larguraMaxima: 640,
        centralizada: true,
        filhos: [
          Text('Vence ${diaPorExtenso(f.vencimento, hoje)}', style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(reais(f.totalCentavos), style: Textos.numerao(context, tamanho: 36)),
          ),
          Text(
            'Compras de ${diaPorExtenso(f.inicio, hoje)} a ${diaPorExtenso(f.fim, hoje)}.'
            '${f.pagoCentavos > 0 ? ' Já pago: ${reais(f.pagoCentavos)}.' : ''}',
            style: texto.bodyMedium?.copyWith(fontSize: 13, color: c.tinta2),
          ),
          if (f.abertoCentavos > 0) ...[
            const SizedBox(height: Espacos.m),
            Acoes(filhos: [
              FilledButton(onPressed: () => _pagar(context, ref, f), child: Text('Pagar ${reais(f.abertoCentavos)}')),
            ]),
          ],
          TituloDeSecao('Compras', detalhe: '${compras.length}'),
          if (compras.isEmpty)
            const Cartao(padding: EdgeInsets.zero, child: Vazio('Nenhuma compra nesta fatura.'))
          else
            Lista(filhos: [
              for (final l in compras)
                LinhaDeLancamento(
                  lancamento: l,
                  hoje: hoje,
                  conta: cartao,
                  categoria: categorias[l.categoriaId],
                  onTap: () => abrirLancamento(context, ref, l),
                ),
            ]),
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
    );
  }
}
