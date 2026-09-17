import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/utils/date_time_converter.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';

/// F4.7 (etapa 1 do F1.10) — dinheiro soma em centavos inteiros, e a data de
/// calendário tem uma definição só.
void main() {
  group('Money', () {
    test('a soma que o double erra', () {
      // 0.1 + 0.2 = 0.30000000000000004 em ponto flutuante.
      expect(0.1 + 0.2 == 0.3, isFalse);

      final soma = Money.fromDouble(0.1) + Money.fromDouble(0.2);
      expect(soma, Money.fromDouble(0.3));
      expect(soma.toDouble(), 0.3);
    });

    test('cem centavos somados um a um fecham em um real', () {
      final total = Money.sum(
        List.filled(100, Money.fromDouble(0.01)),
      );

      expect(total.cents, 100);
      expect(total.toDouble(), 1.0);
    });

    test('mil lançamentos de centavo quebrado não acumulam resto', () {
      final valores = List.generate(1000, (i) => 10.07 + i % 3 * 0.01);

      final emDouble = valores.fold<double>(0, (a, b) => a + b);
      final emCentavos = Money.sumOf(valores, (v) => v);

      // O double erra por frações de centavo; o inteiro não erra.
      expect(emCentavos.cents, valores.fold<int>(0, (a, v) => a + (v * 100).round()));
      expect((emDouble - emCentavos.toDouble()).abs(), lessThan(0.01));
      expect(emCentavos.toDouble() * 100, emCentavos.cents);
    });

    test('subtração de somas iguais dá zero exato, não -0.0000001', () {
      final receitas = Money.sumOf([1234.56, 78.90, 0.07], (v) => v);
      final despesas = Money.sumOf([0.07, 78.90, 1234.56], (v) => v);

      final saldo = receitas - despesas;
      expect(saldo.isZero, isTrue);
      expect(saldo.isNegative, isFalse);
    });

    test('multiplicação arredonda no centavo', () {
      expect((Money.fromDouble(10.01) * 0.5).toDouble(), 5.01);
      expect((Money.fromDouble(100) * 0.3).toDouble(), 30.0);
    });

    test('lista vazia soma zero, e razão de total zero não explode', () {
      expect(Money.sum(const []), Money.zero);
      expect(Money.fromDouble(10).ratioOf(Money.zero), 0);
      expect(Money.fromDouble(25).ratioOf(Money.fromDouble(100)), 0.25);
    });

    test('comparações são exatas: nada de epsilon', () {
      final a = Money.fromDouble(0.1) + Money.fromDouble(0.2);
      expect(a == Money.fromDouble(0.3), isTrue);
      expect(a > Money.fromDouble(0.29), isTrue);
      expect(a < Money.fromDouble(0.31), isTrue);
      expect(a.compareTo(Money.fromDouble(0.3)), 0);
    });
  });

  group('referenceDate', () {
    InstallmentModel parcela({DateTime? paidDate}) => InstallmentModel(
      id: 'i1',
      orderId: 'o1',
      amount: 100,
      description: 'Luz',
      // Uma data vinda de um formulário chega com a hora que o usuário abriu
      // a tela — não com meio-dia.
      dueDate: DateTime(2026, 3, 1, 23, 40),
      paidDate: paidDate,
      status: InstallmentStatus.pending,
      type: OrderType.expense,
      installmentType: InstallmentType.single,
    );

    test('é sempre meio-dia, venha do vencimento ou do pagamento', () {
      expect(parcela().referenceDate, DateTime(2026, 3, 1, 12));
      expect(
        parcela(paidDate: DateTime(2026, 3, 4, 2)).referenceDate,
        DateTime(2026, 3, 4, 12),
      );
    });

    test('o toJson leva as três datas normalizadas', () {
      final json = parcela(paidDate: DateTime(2026, 3, 4, 2)).toJson();

      for (final campo in ['dueDate', 'paidDate', 'referenceDate']) {
        expect(
          DateTime.parse(json[campo] as String).hour,
          12,
          reason: campo,
        );
      }
    });
  });

  group('atNoon', () {
    test('a data de calendário é sempre o dia ao meio-dia', () {
      expect(atNoon(DateTime(2026, 3, 1)), DateTime(2026, 3, 1, 12));
      expect(atNoon(DateTime(2026, 3, 1, 23, 59)), DateTime(2026, 3, 1, 12));
      expect(atNoon(DateTime(2026, 3, 1, 0, 0, 1)), DateTime(2026, 3, 1, 12));
    });

    test('os converters usam a mesma regra, de ida e de volta', () {
      const converter = DateTimeTwelvePmConverter();
      final iso = converter.toJson(DateTime(2026, 3, 1, 3));

      expect(DateTime.parse(iso).hour, 12);
      expect(converter.fromJson(iso), DateTime(2026, 3, 1, 12));
    });
  });
}
