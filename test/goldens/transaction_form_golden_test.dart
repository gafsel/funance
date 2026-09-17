import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';

import 'golden_support.dart';

/// F4.8 §5.4 — `TransactionFormScreen.build` era uma closure de 749 linhas
/// com ZERO widgets privados. Os dois modos do formulário (editável e leitura)
/// vivem no mesmo `fieldsBuilder`, um dentro do `else` do outro: a extração
/// precisa manter a ORDEM dos blocos e o espaçamento entre eles, e é
/// exatamente isso que o golden fixa.

final _conta = goldenAccount(id: 'acc-1', name: 'Conta Corrente');
final _contaDestino = goldenAccount(id: 'acc-2', name: 'Poupança');
final _categoria = goldenCategory(id: 'mercado', name: 'Mercado');

InstallmentModel _parcelaLiquidada() => InstallmentModel(
  id: 'inst-1',
  orderId: 'order-1',
  amount: 250,
  description: 'Mercado do mês',
  dueDate: DateTime(2026, 3, 10),
  paidDate: DateTime(2026, 3, 11),
  paidAmount: 248.5,
  status: InstallmentStatus.settled,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
  category: _categoria,
  accounts: {'acc-1': AccountImpact.debt},
);

Future<void> _pump(WidgetTester tester, Widget tela) async {
  await tester.pumpWidget(
    goldenApp(
      tela,
      overrides: goldenOverrides(
        accounts: [_conta, _contaDestino],
        categories: [_categoria],
        extra: [analyticsServiceProvider.overrideWithValue(FakeAnalytics())],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulário de lançamento — criação de despesa', (tester) async {
    await setGoldenSurface(tester, const Size(900, 1200));
    await _pump(
      tester,
      TransactionFormScreen.creation(type: OrderType.expense),
    );

    await expectLater(
      find.byType(TransactionFormScreen),
      matchesGoldenFile('images/transaction_form_criacao.png'),
    );
  });

  testWidgets('formulário de lançamento — parcela liquidada (leitura)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(900, 1200));
    await _pump(
      tester,
      TransactionFormScreen.updateInstallment(
        installment: _parcelaLiquidada(),
      ),
    );

    await expectLater(
      find.byType(TransactionFormScreen),
      matchesGoldenFile('images/transaction_form_liquidada.png'),
    );
  });
}
