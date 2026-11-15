import '../modelo/modelos.dart';

/// A fatura que um pagamento feito em [dia] quita: a mais antiga já fechada
/// que ainda tem valor em aberto; sem nenhuma fechada, a mais antiga em
/// aberto (pagamento antecipado). Sem nada em aberto, nenhuma: o dinheiro
/// entra como crédito no cartão.
Fatura? faturaQueOPagamentoQuita(Iterable<Fatura> doCartao, String dia) {
  final emAberto = doCartao.where((f) => f.abertoCentavos > 0).toList()
    ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  if (emAberto.isEmpty) return null;
  return emAberto.where((f) => f.fechamento.compareTo(dia) <= 0).firstOrNull ?? emAberto.first;
}

/// A fatura em aberto mais antiga do cartão: é a que pede atenção primeiro.
Fatura? faturaEmAbertoMaisAntiga(Iterable<Fatura> faturas, String cartaoId) {
  final abertas = faturas.where((f) => f.contaId == cartaoId && f.abertoCentavos > 0).toList()
    ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  return abertas.firstOrNull;
}

/// Variação, em pontos percentuais inteiros, de uma fatura contra a
/// anterior. Nula quando não há base de comparação.
int? variacaoPercentual(int atualCentavos, int? anteriorCentavos) {
  if (anteriorCentavos == null || anteriorCentavos <= 0) return null;
  return ((atualCentavos - anteriorCentavos) * 100 / anteriorCentavos).round();
}
