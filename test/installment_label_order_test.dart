import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail/transaction_detail_header.dart';
import 'package:funances/l10n/app_localizations.dart';

/// "3 de 10" é a terceira parcela de dez. A chave de tradução recebe
/// (número, total) nessa ordem, e os três lugares que a chamavam passavam
/// (total, número) — o detalhe da fatura mostrava "10 de 3". Este teste
/// prende a ordem no widget que o dono viu.
void main() {
  testWidgets('a parcela 3 de 10 aparece como "3 de 10", nunca "10 de 3"', (
    tester,
  ) async {
    final installment = InstallmentModel(
      id: 'p3',
      orderId: 'o1',
      amount: 120,
      description: 'Geladeira',
      dueDate: DateTime(2026, 9, 20, 12),
      status: InstallmentStatus.pending,
      type: OrderType.expense,
      installmentType: InstallmentType.installment,
      installmentNumber: 3,
      installmentCount: 10,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransactionDetailHeader(
            installment: installment,
            amountColor: Colors.red,
            onUpdated: null,
            onDelete: () async {},
            onBackToPending: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('3 de 10'), findsOneWidget);
    expect(find.textContaining('10 de 3'), findsNothing);
  });
}
