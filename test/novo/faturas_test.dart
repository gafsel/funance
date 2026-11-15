import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/faturas.dart';

Fatura fatura(String id, String vence, String fecha, {int total = 10000, int pago = 0, String cartao = 'cartao'}) => Fatura(
      id: id,
      contaId: cartao,
      vencimento: vence,
      fechamento: fecha,
      inicio: fecha,
      fim: fecha,
      totalCentavos: total,
      pagoCentavos: pago,
    );

void main() {
  const hoje = '2026-11-15';
  Fatura out({int pago = 0}) => fatura('out', '2026-10-10', '2026-10-05', pago: pago);
  Fatura nov({int pago = 0}) => fatura('nov', '2026-11-10', '2026-11-05', pago: pago);
  final dez = fatura('dez', '2026-12-10', '2026-12-05', total: 5000);

  group('paga não é o mesmo que quitada', () {
    test('sem pagamento a fatura fechada está pendente; vencida, atrasada', () {
      final s = situacoesDasFaturas([nov(), dez], hoje);
      expect(s['nov']!.pendente, isTrue);
      expect(s['nov']!.atrasada, isTrue);
      expect(s['nov']!.aPagarCentavos, 10000);
      expect(s['dez']!.aberta, isTrue);
      expect(s['dez']!.devidoCentavos, 5000);
    });

    test('pagamento parcial: a fatura está paga e o resto vai para a seguinte', () {
      final s = situacoesDasFaturas([nov(pago: 4000), dez], hoje);
      expect(s['nov']!.paga, isTrue);
      expect(s['nov']!.pendente, isFalse);
      expect(s['nov']!.emParte, isTrue);
      expect(s['nov']!.quitada, isFalse);
      expect(s['nov']!.levadoCentavos, 6000);
      expect(s['nov']!.aPagarCentavos, 0);
      expect(s['dez']!.transportadoCentavos, 6000);
      expect(s['dez']!.devidoCentavos, 11000);
    });

    test('pagar a mais vira crédito na seguinte', () {
      final s = situacoesDasFaturas([nov(pago: 12000), dez], hoje);
      expect(s['nov']!.quitada, isTrue);
      expect(s['dez']!.transportadoCentavos, -2000);
      expect(s['dez']!.devidoCentavos, 3000);
    });

    test('pagamento exato quita e não leva nada', () {
      final s = situacoesDasFaturas([nov(pago: 10000), dez], hoje);
      expect(s['nov']!.quitada, isTrue);
      expect(s['dez']!.transportadoCentavos, 0);
    });

    test('o que foi levado segue pela cadeia até ser pago', () {
      final s = situacoesDasFaturas([out(pago: 4000), nov(pago: 10000), dez], hoje);
      // Outubro deixou 60; novembro devia 160 e pagou 100: leva 60 para dezembro.
      expect(s['nov']!.devidoCentavos, 16000);
      expect(s['nov']!.levadoCentavos, 6000);
      expect(s['dez']!.devidoCentavos, 11000);
    });

    test('fatura pendente não passa nada adiante: ela mesma espera pagamento', () {
      final s = situacoesDasFaturas([out(), nov(), dez], hoje);
      expect(s['nov']!.transportadoCentavos, 0);
      expect(s['out']!.atrasada, isTrue);
      expect(s['nov']!.atrasada, isTrue);
    });

    test('cada cartão tem a sua cadeia', () {
      final s = situacoesDasFaturas([nov(pago: 4000), fatura('outro', '2026-12-10', '2026-12-05', cartao: 'b')], hoje);
      expect(s['outro']!.transportadoCentavos, 0);
    });
  });

  group('que fatura um pagamento paga', () {
    test('a pendente mais antiga', () {
      expect(faturaQueOPagamentoQuita([dez, nov(), out()], hoje)?.id, 'out');
    });

    test('o complemento vai para a última fechada paga em parte', () {
      expect(faturaQueOPagamentoQuita([dez, nov(pago: 4000), out(pago: 10000)], hoje)?.id, 'nov');
    });

    test('sem pendência, é crédito na fatura aberta: não paga nenhuma', () {
      expect(faturaQueOPagamentoQuita([dez, nov(pago: 10000)], hoje), isNull);
      expect(faturaQueOPagamentoQuita([dez], hoje), isNull);
    });
  });

  group('destaque e dívida cara', () {
    test('destaque: pendente, depois a aberta, depois a paga em parte', () {
      expect(faturaEmDestaque(situacoesDasFaturas([out(), nov(), dez], hoje), 'cartao')?.fatura.id, 'out');
      final comAberta = situacoesDasFaturas([nov(pago: 4000), dez], hoje);
      expect(faturaEmDestaque(comAberta, 'cartao')?.fatura.id, 'dez');
      expect(valorEmDestaque(faturaEmDestaque(comAberta, 'cartao')!), 11000);
      final semAberta = situacoesDasFaturas([nov(pago: 4000)], hoje);
      expect(faturaEmDestaque(semAberta, 'cartao')?.fatura.id, 'nov');
      expect(valorEmDestaque(faturaEmDestaque(semAberta, 'cartao')!), 6000);
      expect(faturaEmDestaque(situacoesDasFaturas([nov(pago: 10000)], hoje), 'cartao'), isNull);
    });

    test('dívida cara: fatura atrasada ou paga em parte', () {
      expect(faturasEmDividaCara(situacoesDasFaturas([nov(), dez], hoje)).single.fatura.id, 'nov');
      expect(faturasEmDividaCara(situacoesDasFaturas([nov(pago: 4000), dez], hoje)).single.fatura.id, 'nov');
      expect(faturasEmDividaCara(situacoesDasFaturas([nov(pago: 10000), dez], hoje)), isEmpty);
      // Outubro foi paga em parte, mas novembro já fechou e foi quitada com o que veio.
      expect(faturasEmDividaCara(situacoesDasFaturas([out(pago: 4000), nov(pago: 16000), dez], hoje)), isEmpty);
    });
  });

  test('variação contra a fatura anterior', () {
    expect(variacaoPercentual(12000, 10000), 20);
    expect(variacaoPercentual(7500, 10000), -25);
    expect(variacaoPercentual(7500, 0), isNull);
    expect(variacaoPercentual(7500, null), isNull);
  });
}
