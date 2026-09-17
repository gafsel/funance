import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/accounts_view.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F1.8 — a lista de contas mostra o que o SERVIDOR publicou em
/// `accounts/{id}.nextInvoice`, ou "calculando" enquanto ele não publicou.
/// Zero reais com cara de valor definitivo é o que estes testes impedem.

mixin _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

class _FakeWorkspaceRepository with _Unimplemented
    implements IWorkspaceRepository {}

class _FakeCategoryRepository with _Unimplemented
    implements ICategoryRepository {
  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      const Stream.empty();
}

class _FakeAccountRepository with _Unimplemented
    implements IAccountRepository {
  _FakeAccountRepository(this.accounts);

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(accounts);

  @override
  Stream<AccountBalanceModel?> getLatestAccountBalance(
    String workspaceId,
    String accountId,
  ) => Stream.value(
    AccountBalanceModel(id: '2025-03-10', balance: -800, updatedAt: DateTime(2025, 3, 10)),
  );
}

/// Desde F3.9 a lista de contas NÃO busca a parcela da fatura: o id dela vem
/// do resumo que o servidor grava na conta (`nextInvoice.installmentId`) e a
/// rota `/invoices/:id` carrega o resto. O fake continua aqui para provar que
/// a segunda consulta não acontece mais.
class _FakeFinanceRepository with _Unimplemented implements IFinanceRepository {
  _FakeFinanceRepository(this.invoice);

  final InstallmentModel? invoice;
  int watchCalls = 0;

  @override
  Stream<InstallmentModel?> watchNextInvoice(
    String workspaceId,
    String accountId,
  ) {
    watchCalls++;
    return Stream.value(invoice);
  }
}

DateTime _spNoon(String dateKey) {
  final parts = dateKey.split('-').map(int.parse).toList();
  return DateTime.utc(parts[0], parts[1], parts[2], 15).toLocal();
}

final _next = NextInvoice(
  dueDate: _spNoon('2025-03-10'),
  closingDate: DateTime.utc(2025, 3, 5, 3).toLocal(),
  cycleStart: DateTime.utc(2025, 2, 5, 3).toLocal(),
  cycleEnd: DateTime.utc(2025, 3, 5, 2, 59, 59, 999).toLocal(),
  amount: 1234.56,
  orderId: 'invoice-card-1-2025-03-10',
  installmentId: 'inst-fatura',
);

CreditCardAccount _card({NextInvoice? nextInvoice, String id = 'card-1'}) =>
    CreditCardAccount(
      id: id,
      name: 'Cartão',
      icon: 'credit_card',
      color: '#8A05BE',
      initialBalanceDate: DateTime(2025, 1, 1, 12),
      limit: 5000,
      dueDay: 10,
      closingDay: 5,
      nextInvoice: nextInvoice,
    );

InstallmentModel _invoiceInstallment() => InstallmentModel(
  id: 'inst-fatura',
  orderId: 'invoice-card-1-2025-03-10',
  amount: 1234.56,
  description: 'Fatura Cartão',
  dueDate: _spNoon('2025-03-10'),
  status: InstallmentStatus.pending,
  type: OrderType.transfer,
  installmentType: InstallmentType.single,
  accounts: const {'card-1': AccountImpact.credit},
  isInvoice: true,
  cycleStart: DateTime.utc(2025, 2, 5, 3).toLocal(),
  cycleEnd: DateTime.utc(2025, 3, 5, 2, 59, 59, 999).toLocal(),
);

Future<_FakeFinanceRepository> _pump(
  WidgetTester tester,
  List<AccountModel> accounts, {
  InstallmentModel? invoice,
}) async {
  final financeRepository = _FakeFinanceRepository(invoice);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        WorkspaceDomainProviders.repository.overrideWithValue(
          _FakeWorkspaceRepository(),
        ),
        AccountDomainProviders.repository.overrideWithValue(
          _FakeAccountRepository(accounts),
        ),
        CategoryDomainProviders.repository.overrideWithValue(
          _FakeCategoryRepository(),
        ),
        FinanceDomainProviders.repository.overrideWithValue(financeRepository),
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
        home: const Scaffold(
          body: SingleChildScrollView(child: AccountsView()),
        ),
      ),
    ),
  );

  // `pumpAndSettle` não serve aqui: o indicador de carregamento do total é uma
  // animação infinita e o teste nunca "assentaria".
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  return financeRepository;
}

/// Abre o grupo recolhido de cartões.
///
/// A view desenha um `ExpansionTile` por tipo de conta, então o alvo é
/// procurado pelo título — `.first` pegaria "Conta Corrente". A animação do
/// tile é finita, mas o spinner do total não: nada de `pumpAndSettle`.
Future<void> _expandCards(WidgetTester tester) async {
  await tester.tap(find.text('Cartão de Crédito'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('mostra valor e vencimento vindos do servidor', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final financeRepository = await _pump(
      tester,
      [_card(nextInvoice: _next)],
      invoice: _invoiceInstallment(),
    );

    // O grupo "Cartão de Crédito" começa recolhido: abre para ver a conta.
    await _expandCards(tester);

    expect(find.textContaining('1.234,56'), findsWidgets);
    expect(find.text('10/03/2025'), findsOneWidget);
    expect(find.text('calculando…'), findsNothing);

    // Nenhuma consulta extra: o id da parcela já estava no resumo da conta, e
    // é ele que a rota `/invoices/:id` recebe.
    expect(financeRepository.watchCalls, 0);
    expect(_next.installmentId, 'inst-fatura');
  });

  testWidgets('mostra "calculando" enquanto o servidor não publicou', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, [_card()]);

    await _expandCards(tester);

    // Sem resumo: nada de R$ 0,00 com cara de fatura fechada.
    expect(find.text('calculando…'), findsOneWidget);
    expect(find.text(r'R$ 0,00'), findsNothing);
  });

  testWidgets('o total do grupo espera todos os cartões responderem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(tester, [
      _card(nextInvoice: _next),
      _card(id: 'card-2'),
    ]);

    // Um cartão sem resumo deixa o total do grupo incompleto: o indicador de
    // carregamento é o que evita mostrar uma soma parcial como se fosse a
    // dívida do mês.
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('não serializa nextInvoice ao editar a conta', (tester) async {
    final card = _card(nextInvoice: _next);
    expect(card.toJson().containsKey('nextInvoice'), isFalse);
  });
}
