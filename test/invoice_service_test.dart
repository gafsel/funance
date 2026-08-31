import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/services/invoice_service.dart';

AccountModel _card({required int closingDay, required int dueDay}) {
  return AccountModel.creditCard(
    id: 'card',
    name: 'Cartão',
    icon: 'credit_card',
    color: '#000000',
    initialBalanceDate: DateTime(2026, 1, 1),
    limit: 1000,
    dueDay: dueDay,
    closingDay: closingDay,
  );
}

void main() {
  group('InvoiceService.calculateInvoiceCycleRange', () {
    test('ciclo vai do fechamento anterior (incl.) à véspera do atual (incl.)', () {
      // Fechamento dia 10, vencimento dia 20 do mesmo mês.
      final card = _card(closingDay: 10, dueDay: 20);
      final (start, end) = InvoiceService.calculateInvoiceCycleRange(
        DateTime(2026, 8, 20, 12),
        card,
      );

      expect(start, DateTime(2026, 7, 10)); // 00:00 do fechamento anterior
      expect(end, DateTime(2026, 8, 9, 23, 59, 59)); // véspera do fechamento
    });

    test('dia do fechamento fica fora, independente do fuso da normalização', () {
      final card = _card(closingDay: 10, dueDay: 20);
      final (start, end) = InvoiceService.calculateInvoiceCycleRange(
        DateTime(2026, 8, 20, 12),
        card,
      );

      // Normalização do app: 12:00 local; do servidor (UTC-3): 09:00 local.
      final appOnClosing = DateTime(2026, 8, 10, 12);
      final serverOnClosing = DateTime(2026, 8, 10, 9);
      expect(appOnClosing.isAfter(end), isTrue);
      expect(serverOnClosing.isAfter(end), isTrue);

      // E o dia do fechamento anterior entra inteiro, nas duas normalizações.
      final appOnPrevClosing = DateTime(2026, 7, 10, 12);
      final serverOnPrevClosing = DateTime(2026, 7, 10, 9);
      expect(appOnPrevClosing.isBefore(start), isFalse);
      expect(serverOnPrevClosing.isBefore(start), isFalse);
    });

    test('vencimento menor que fechamento cai no mês seguinte ao fechamento', () {
      // Fecha dia 25, vence dia 5 do mês seguinte.
      final card = _card(closingDay: 25, dueDay: 5);
      final (start, end) = InvoiceService.calculateInvoiceCycleRange(
        DateTime(2026, 9, 5, 12),
        card,
      );

      expect(start, DateTime(2026, 7, 25));
      expect(end, DateTime(2026, 8, 24, 23, 59, 59));
    });

    test('virada de ano', () {
      final card = _card(closingDay: 10, dueDay: 20);
      final (start, end) = InvoiceService.calculateInvoiceCycleRange(
        DateTime(2026, 1, 20, 12),
        card,
      );

      expect(start, DateTime(2025, 12, 10));
      expect(end, DateTime(2026, 1, 9, 23, 59, 59));
    });

    test('fechamento dia 31 é limitado ao último dia de meses curtos', () {
      final card = _card(closingDay: 31, dueDay: 10);
      // Vencimento 10/03 → fechamento em fevereiro (clamp para 28 em 2026).
      final (start, end) = InvoiceService.calculateInvoiceCycleRange(
        DateTime(2026, 3, 10, 12),
        card,
      );

      expect(start, DateTime(2026, 1, 31));
      expect(end, DateTime(2026, 2, 27, 23, 59, 59));
    });
  });
}
