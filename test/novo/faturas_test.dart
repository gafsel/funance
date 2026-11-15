import 'package:flutter_test/flutter_test.dart';
import 'package:funances/novo/modelo/modelos.dart';
import 'package:funances/novo/regras/faturas.dart';

Fatura fatura(String id, String vence, String fecha, {int total = 10000, int pago = 0}) => Fatura(
      id: id,
      contaId: 'cartao',
      vencimento: vence,
      fechamento: fecha,
      inicio: fecha,
      fim: fecha,
      totalCentavos: total,
      pagoCentavos: pago,
    );

void main() {
  final outubro = fatura('out', '2026-10-10', '2026-10-05', pago: 10000);
  final novembro = fatura('nov', '2026-11-10', '2026-11-05', pago: 4000);
  final dezembro = fatura('dez', '2026-12-10', '2026-12-05');

  test('o complemento vai para a fatura fechada que ficou com saldo', () {
    expect(faturaQueOPagamentoQuita([dezembro, novembro, outubro], '2026-11-15')?.id, 'nov');
  });

  test('sem fatura fechada em aberto, é pagamento antecipado da aberta', () {
    final quitada = fatura('nov', '2026-11-10', '2026-11-05', pago: 10000);
    expect(faturaQueOPagamentoQuita([dezembro, quitada], '2026-11-15')?.id, 'dez');
  });

  test('sem nada em aberto, não quita fatura nenhuma', () {
    expect(faturaQueOPagamentoQuita([outubro], '2026-11-15'), isNull);
  });

  test('a fatura em aberto mais antiga é a que aparece primeiro', () {
    expect(faturaEmAbertoMaisAntiga([dezembro, novembro, outubro], 'cartao')?.id, 'nov');
    expect(faturaEmAbertoMaisAntiga([outubro], 'cartao'), isNull);
  });

  test('variação contra a fatura anterior', () {
    expect(variacaoPercentual(12000, 10000), 20);
    expect(variacaoPercentual(7500, 10000), -25);
    expect(variacaoPercentual(7500, 0), isNull);
    expect(variacaoPercentual(7500, null), isNull);
  });
}
