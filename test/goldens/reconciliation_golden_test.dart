// As imagens de referência foram gravadas no macOS. No Linux do CI o texto
// renderiza diferente (1,7% a 2,5% dos pixels), então o CI roda com
// `--exclude-tags golden`; localmente estes testes continuam valendo.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/reconciliation_screen.dart';

import 'golden_support.dart';

/// F4.8 §5.3 — a etapa de revisão da conciliação é a tela mais densa do app:
/// `_MatchItem` tinha 531 linhas com DOIS layouts (cartão no mobile, linha de
/// duas colunas no desktop) que precisam continuar idênticos depois da
/// extração. O golden cobre os dois e os quatro status de casamento.

class _FakeReconciliationRepository
    with NaoUsado
    implements IReconciliationRepository {}

final _conta = goldenAccount();

final _categoria = goldenCategory(id: 'mercado', name: 'Mercado');

ReconciliationTransaction _doc({
  required String description,
  required double amount,
  required int dia,
  OrderType type = OrderType.expense,
}) => ReconciliationTransaction(
  description: description,
  amount: amount,
  date: DateTime(2026, 3, dia, 12),
  type: type,
);

InstallmentModel _parcela({
  required String id,
  required String description,
  required double amount,
  required int dia,
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: amount,
  description: description,
  dueDate: DateTime(2026, 3, dia, 12),
  status: InstallmentStatus.pending,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
  category: _categoria,
  accounts: {'acc-1': AccountImpact.debt},
);

final _matches = <ReconciliationMatch>[
  // Casado
  ReconciliationMatch(
    documentTransaction: _doc(
      description: 'SUPERMERCADO XYZ',
      amount: -250,
      dia: 3,
    ),
    systemInstallment: _parcela(
      id: 'i1',
      description: 'Mercado do mês',
      amount: 250,
      dia: 3,
    ),
    status: ReconciliationMatchStatus.matched,
  ),
  // Sugerido
  ReconciliationMatch(
    documentTransaction: _doc(
      description: 'PADARIA CENTRAL',
      amount: -48.9,
      dia: 5,
    ),
    systemInstallment: _parcela(
      id: 'i2',
      description: 'Padaria',
      amount: 49.9,
      dia: 6,
    ),
    status: ReconciliationMatchStatus.suggested,
  ),
  // Sem descrição no extrato e sem par no sistema
  ReconciliationMatch(
    documentTransaction: _doc(description: '', amount: -13.5, dia: 8),
    status: ReconciliationMatchStatus.unmatched,
  ),
  // Só no sistema
  ReconciliationMatch(
    systemInstallment: _parcela(
      id: 'i3',
      description: 'Assinatura de streaming',
      amount: 39.9,
      dia: 10,
    ),
  ),
  // Ignorado
  ReconciliationMatch(
    documentTransaction: _doc(
      description: 'ESTORNO',
      amount: 90,
      dia: 12,
      type: OrderType.income,
    ),
    status: ReconciliationMatchStatus.ignored,
  ),
];

/// Mesma máquina de estados de produção, já na etapa de revisão: montar o
/// upload de um PDF falso só para chegar aqui não testaria nada além do
/// upload.
class _NotifierEmRevisao extends ReconciliationNotifier {
  _NotifierEmRevisao({
    required super.reconciliationService,
    required super.account,
    required super.analytics,
  }) {
    state = state.copyWith(step: ReconciliationStep.review, matches: _matches);
  }
}

Future<void> _pump(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    goldenApp(
      ReconciliationScreen(account: _conta),
      brightness: brightness,
      overrides: goldenOverrides(
        accounts: [_conta],
        categories: [_categoria],
        extra: [
          ReconciliationDomainProviders.repository.overrideWithValue(
            _FakeReconciliationRepository(),
          ),
          FinanceViewProviders.reconciliation(_conta).overrideWith(
            (ref) => _NotifierEmRevisao(
              reconciliationService: ref.watch(
                ReconciliationDomainProviders.service,
              ),
              account: _conta,
              analytics: FakeAnalytics(),
            ),
          ),
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('conciliação — revisão em cartões (mobile)', (tester) async {
    await setGoldenSurface(tester, const Size(760, 1600));
    await _pump(tester);

    await expectLater(
      find.byType(ReconciliationScreen),
      matchesGoldenFile('images/reconciliation_mobile.png'),
    );
  });

  testWidgets('conciliação — revisão em duas colunas (desktop)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(1400, 1400));
    await _pump(tester);

    await expectLater(
      find.byType(ReconciliationScreen),
      matchesGoldenFile('images/reconciliation_desktop.png'),
    );
  });

  // M7 — o mesmo par no tema escuro.
  testWidgets('conciliação — revisão em cartões (mobile, escuro)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(760, 1600));
    await _pump(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(ReconciliationScreen),
      matchesGoldenFile('images/reconciliation_mobile_escuro.png'),
    );
  });

  testWidgets('conciliação — revisão em duas colunas (desktop, escuro)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(1400, 1400));
    await _pump(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(ReconciliationScreen),
      matchesGoldenFile('images/reconciliation_desktop_escuro.png'),
    );
  });
}
