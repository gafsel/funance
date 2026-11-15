import '../modelo/modelos.dart';

/// Como uma fatura está, levando em conta o que veio da anterior.
///
/// Pagar e quitar são coisas diferentes. Registrar um pagamento, mesmo
/// parcial, tira a fatura da lista do que está pendente: ela está **paga**.
/// O que ficou diferente do valor fechado — a mais ou a menos — vai para a
/// fatura seguinte, como o banco faz. Pagar a menos é entrar no rotativo, e
/// por isso a fatura fica marcada como paga em parte até completar.
class SituacaoDaFatura {
  const SituacaoDaFatura(this.fatura, this.transportadoCentavos, this.hoje);
  final Fatura fatura;

  /// O que veio da fatura anterior: positivo é saldo não pago, negativo é
  /// crédito de quem pagou a mais.
  final int transportadoCentavos;
  final String hoje;

  /// Compras do ciclo mais o que veio da anterior.
  int get devidoCentavos => fatura.totalCentavos + transportadoCentavos;
  int get pagoCentavos => fatura.pagoCentavos;

  /// Ainda recebendo compras.
  bool get aberta => fatura.fechamento.compareTo(hoje) > 0;

  /// Fechada e com pagamento registrado (ou sem nada a pagar).
  bool get paga => !aberta && (pagoCentavos > 0 || devidoCentavos <= 0);

  /// Fechada e esperando pagamento.
  bool get pendente => !aberta && !paga;
  bool get atrasada => pendente && fatura.vencimento.compareTo(hoje) < 0;

  /// O que a fatura paga deixou para a seguinte: positivo é o que faltou
  /// (rotativo), negativo é o que sobrou (crédito).
  int get levadoCentavos => paga ? devidoCentavos - pagoCentavos : 0;

  /// Paga em parte: o resto foi para a próxima fatura e paga juros.
  bool get emParte => levadoCentavos > 0;
  bool get quitada => paga && levadoCentavos <= 0;

  /// Quanto pede pagamento agora.
  int get aPagarCentavos => paga ? 0 : devidoCentavos - pagoCentavos;
}

/// A situação de cada fatura, por id. As de cada cartão são encadeadas da
/// mais antiga para a mais nova, passando adiante o que cada uma deixou.
Map<String, SituacaoDaFatura> situacoesDasFaturas(Iterable<Fatura> faturas, String hoje) {
  final porCartao = <String, List<Fatura>>{};
  for (final f in faturas) {
    (porCartao[f.contaId] ??= []).add(f);
  }
  final situacoes = <String, SituacaoDaFatura>{};
  for (final doCartao in porCartao.values) {
    doCartao.sort((a, b) => a.vencimento.compareTo(b.vencimento));
    var transportado = 0;
    for (final f in doCartao) {
      final s = SituacaoDaFatura(f, transportado, hoje);
      situacoes[f.id] = s;
      transportado = s.levadoCentavos;
    }
  }
  return situacoes;
}

List<SituacaoDaFatura> _doCartao(Map<String, SituacaoDaFatura> situacoes, String cartaoId) =>
    situacoes.values.where((s) => s.fatura.contaId == cartaoId).toList()
      ..sort((a, b) => a.fatura.vencimento.compareTo(b.fatura.vencimento));

/// A fatura que um pagamento feito em [dia] paga: a mais antiga que está
/// pendente; sem nenhuma, a última fechada que foi paga em parte (é o
/// complemento). Sem nada disso, nenhuma: o dinheiro entra como crédito na
/// fatura que ainda está aberta.
Fatura? faturaQueOPagamentoQuita(Iterable<Fatura> doCartao, String dia) {
  final situacoes = situacoesDasFaturas(doCartao, dia).values.toList()
    ..sort((a, b) => a.fatura.vencimento.compareTo(b.fatura.vencimento));
  final pendente = situacoes.where((s) => s.pendente && s.aPagarCentavos > 0).firstOrNull;
  if (pendente != null) return pendente.fatura;
  final ultimaFechada = situacoes.where((s) => !s.aberta).lastOrNull;
  return ultimaFechada != null && ultimaFechada.emParte ? ultimaFechada.fatura : null;
}

/// A fatura do cartão que pede atenção primeiro: a pendente mais antiga;
/// sem pendente, a que está aberta; sem aberta, a última paga em parte.
SituacaoDaFatura? faturaEmDestaque(Map<String, SituacaoDaFatura> situacoes, String cartaoId) {
  final doCartao = _doCartao(situacoes, cartaoId);
  return doCartao.where((s) => s.pendente && s.aPagarCentavos > 0).firstOrNull ??
      doCartao.where((s) => s.aberta && s.devidoCentavos != 0).firstOrNull ??
      doCartao.where((s) => s.emParte).lastOrNull;
}

/// Quanto a fatura em destaque representa: o que falta pagar, o que já se
/// acumulou na aberta, ou o que ficou para a próxima.
int valorEmDestaque(SituacaoDaFatura s) =>
    s.pendente ? s.aPagarCentavos : (s.aberta ? s.devidoCentavos : s.levadoCentavos);

/// Faturas que são dívida cara agora: vencidas sem pagamento, ou pagas em
/// parte (rotativo) sem que a seguinte tenha fechado.
List<SituacaoDaFatura> faturasEmDividaCara(Map<String, SituacaoDaFatura> situacoes) {
  final caras = <SituacaoDaFatura>[];
  final cartoes = {for (final s in situacoes.values) s.fatura.contaId};
  for (final cartao in cartoes) {
    final doCartao = _doCartao(situacoes, cartao);
    caras.addAll(doCartao.where((s) => s.atrasada));
    final ultimaFechada = doCartao.where((s) => !s.aberta).lastOrNull;
    if (ultimaFechada != null && ultimaFechada.emParte) caras.add(ultimaFechada);
  }
  return caras;
}

/// Variação, em pontos percentuais inteiros, de uma fatura contra a
/// anterior. Nula quando não há base de comparação.
int? variacaoPercentual(int atualCentavos, int? anteriorCentavos) {
  if (anteriorCentavos == null || anteriorCentavos <= 0) return null;
  return ((atualCentavos - anteriorCentavos) * 100 / anteriorCentavos).round();
}
