import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/reconciliation_history_picker.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F3.8 (QA) — o mapper parou de escrever "Sem descrição" em português, e
/// quem não aplicasse o texto na tela passaria a mostrar uma linha em branco.
/// A lista da conciliação é o caso mais visível: ela nasce da leitura de um
/// extrato, onde descrição ausente é comum.

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

class _FakeFinanceRepository with _NaoUsado implements IFinanceRepository {
  _FakeFinanceRepository(this.items);

  final List<InstallmentModel> items;

  @override
  Future<QueryChunk<InstallmentModel>> queryInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  }) async => QueryChunk(items: items);
}

class _FakeAccountRepository with _NaoUsado implements IAccountRepository {}

class _FakeCategoryRepository with _NaoUsado implements ICategoryRepository {}

InstallmentModel _parcela({required String description}) => InstallmentModel(
  id: 'i1',
  orderId: 'o1',
  amount: 42.5,
  description: description,
  dueDate: DateTime(2026, 3, 10, 12),
  status: InstallmentStatus.paid,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  List<InstallmentModel> items,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        FinanceDomainProviders.repository.overrideWithValue(
          _FakeFinanceRepository(items),
        ),
        AccountDomainProviders.repository.overrideWithValue(
          _FakeAccountRepository(),
        ),
        CategoryDomainProviders.repository.overrideWithValue(
          _FakeCategoryRepository(),
        ),
        WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('w1'),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReconciliationHistoryPicker(
            initialQuery: TransactionQuery(),
            onSelected: (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();

  return AppLocalizations.delegate.load(const Locale('pt'));
}

void main() {
  testWidgets('lançamento sem descrição mostra "Sem descrição" traduzido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final l10n = await _pump(tester, [_parcela(description: '')]);

    expect(find.text(l10n.noDescription), findsOneWidget);
    // E não a categoria vazia tampouco.
    expect(find.text(l10n.noCategory), findsOneWidget);
  });

  testWidgets('descrição de verdade continua aparecendo como está', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final l10n = await _pump(tester, [_parcela(description: 'Mercado')]);

    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text(l10n.noDescription), findsNothing);
  });
}
