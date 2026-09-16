import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

class _StubAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Só os métodos que o formulário toca; qualquer outro grita em vez de
/// devolver null silencioso.
class _FakeFinanceRepository implements IFinanceRepository {
  _FakeFinanceRepository({this.installments = const []});

  final List<InstallmentModel> installments;
  final List<({String? categoryId, OrderType? type, int? limit})> queryCalls = [];

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
  }) async {
    queryCalls.add((categoryId: categoryId, type: type, limit: limit));
    return QueryChunk(items: installments);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeAccountRepository implements IAccountRepository {
  _FakeAccountRepository({this.accounts = const []});

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(accounts);

  @override
  Future<AccountModel> getAccount(String workspaceId, String accountId) async =>
      accounts.firstWhere((account) => account.id == accountId);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeCategoryRepository implements ICategoryRepository {
  _FakeCategoryRepository({this.categories = const []});

  final List<CategoryModel> categories;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeWorkspaceRepository implements IWorkspaceRepository {
  @override
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

CategoryModel _category({String id = 'cat-1'}) => const CategoryModel(
  id: 'cat-1',
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#FF0000',
).copyWith(id: id);

AccountModel _account({required String id, required String name}) =>
    AccountModel.checking(
      id: id,
      name: name,
      icon: 'account_balance',
      color: '#0000FF',
      initialBalanceDate: DateTime(2026, 1, 1),
    );

AccountModel _investmentAccount({required String id, required String name}) =>
    AccountModel.investment(
      id: id,
      name: name,
      icon: 'savings',
      color: '#00FF00',
      interestRate: 0,
      initialBalanceDate: DateTime(2026, 1, 1),
    );

InstallmentModel _installment({
  String id = 'inst-1',
  double amount = 100,
  String description = 'Aluguel',
  DateTime? dueDate,
  InstallmentType installmentType = InstallmentType.installment,
  int? installmentCount = 3,
  InstallmentStatus status = InstallmentStatus.pending,
  String accountId = 'acc-1',
}) => InstallmentModel(
  id: id,
  orderId: 'order-1',
  amount: amount,
  description: description,
  dueDate: dueDate ?? DateTime(2026, 3, 10),
  status: status,
  type: OrderType.expense,
  installmentType: installmentType,
  installmentCount: installmentCount,
  installmentNumber: 1,
  category: _category(),
  accounts: {accountId: AccountImpact.debt},
);

FinanceService _financeService({
  List<InstallmentModel> installments = const [],
  List<AccountModel> accounts = const [],
}) => FinanceService(
  workspaceId: 'ws-test',
  repository: _FakeFinanceRepository(installments: installments),
  accountRepository: _FakeAccountRepository(accounts: accounts),
  categoryRepository: _FakeCategoryRepository(),
);

TransactionFormNotifier _notifierFor(
  TransactionFormState state, {
  FinanceService? financeService,
}) => TransactionFormNotifier(
  state,
  financeService: financeService ?? _financeService(),
  analytics: _StubAnalyticsService(),
);

Widget _hostedForm(
  Widget screen, {
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: screen,
    ),
  );
}

List<Override> _overrides({
  List<AccountModel> accounts = const [],
  List<CategoryModel> categories = const [],
  List<InstallmentModel> installments = const [],
}) => [
  WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-test'),
  analyticsServiceProvider.overrideWithValue(_StubAnalyticsService()),
  WorkspaceDomainProviders.repository.overrideWithValue(
    _FakeWorkspaceRepository(),
  ),
  AuthDomainProviders.currentUser.overrideWithValue(null),
  FinanceDomainProviders.repository.overrideWithValue(
    _FakeFinanceRepository(installments: installments),
  ),
  AccountDomainProviders.repository.overrideWithValue(
    _FakeAccountRepository(accounts: accounts),
  ),
  CategoryDomainProviders.repository.overrideWithValue(
    _FakeCategoryRepository(categories: categories),
  ),
];

void main() {
  group('regra da cascata', () {
    test('não pergunta ao criar um lançamento', () {
      final notifier = _notifierFor(
        TransactionFormState.creation(type: OrderType.expense),
      );
      addTearDown(notifier.dispose);

      expect(notifier.shouldAskCascade, isFalse);
    });

    test('não pergunta numa parcela única, mesmo com campos alterados', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(
          _installment(
            installmentType: InstallmentType.single,
            installmentCount: null,
          ),
        ),
      );
      addTearDown(notifier.dispose);

      notifier.updateAmount(999);

      expect(notifier.shouldAskCascade, isFalse);
    });

    test('não pergunta num parcelamento de uma parcela só', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(
          _installment(installmentCount: 1),
        ),
      );
      addTearDown(notifier.dispose);

      notifier.updateAmount(999);

      expect(notifier.shouldAskCascade, isFalse);
    });

    test('não pergunta quando nada replicável mudou', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
      );
      addTearDown(notifier.dispose);

      expect(notifier.shouldAskCascade, isFalse);
    });

    test('quitar a parcela não é motivo para perguntar', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
      );
      addTearDown(notifier.dispose);

      notifier.updateStatus(InstallmentStatus.paid);
      notifier.updatePaidAmount(120);

      expect(notifier.shouldAskCascade, isFalse);
    });

    test('pergunta quando o valor muda numa série parcelada', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
      );
      addTearDown(notifier.dispose);

      notifier.updateAmount(250);

      expect(notifier.shouldAskCascade, isTrue);
    });

    test('pergunta quando a descrição muda numa recorrência', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(
          _installment(
            installmentType: InstallmentType.recurring,
            installmentCount: null,
          ),
        ),
      );
      addTearDown(notifier.dispose);

      notifier.updateDescription('Aluguel reajustado');

      expect(notifier.shouldAskCascade, isTrue);
    });

    test('pergunta quando a categoria muda', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
      );
      addTearDown(notifier.dispose);

      notifier.updateCategory(_category(id: 'cat-2'));

      expect(notifier.shouldAskCascade, isTrue);
    });

    test('pergunta quando a conta muda', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
      );
      addTearDown(notifier.dispose);

      notifier.updateAccountIdSource('acc-2');

      expect(notifier.shouldAskCascade, isTrue);
    });

    test('voltar o campo ao valor original desarma a pergunta', () {
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment(amount: 100)),
      );
      addTearDown(notifier.dispose);

      notifier.updateAmount(250);
      expect(notifier.shouldAskCascade, isTrue);

      notifier.updateAmount(100);
      expect(notifier.shouldAskCascade, isFalse);
    });
  });

  group('conta padrão do lançamento', () {
    test('usa a última conta usada na categoria', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [_installment(accountId: 'acc-ultima')],
          accounts: [
            _account(id: 'acc-ultima', name: 'Nubank'),
            _account(id: 'acc-outra', name: 'Itaú'),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, 'acc-ultima');
      expect(notifier.state.resolvingAccount, isFalse);
    });

    test('cai na única conta quando a categoria não tem histórico', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
        ),
        financeService: _financeService(
          accounts: [_account(id: 'acc-unica', name: 'Nubank')],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, 'acc-unica');
    });

    test('não escolhe nada quando há várias contas e nenhum histórico', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
        ),
        financeService: _financeService(
          accounts: [
            _account(id: 'acc-1', name: 'Nubank'),
            _account(id: 'acc-2', name: 'Itaú'),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, isNull);
      expect(notifier.state.resolvingAccount, isFalse);
    });

    test('a conta vinda do ponto de entrada não é sobrescrita', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
          accountIdSource: 'acc-escolhida',
        ),
        financeService: _financeService(
          installments: [_installment(accountId: 'acc-ultima')],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, 'acc-escolhida');
    });
  });

  group('construtores do formulário', () {
    testWidgets('criação abre sem seletor de status e com conta obrigatória', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.creation(
            type: OrderType.expense,
            status: InstallmentStatus.paid,
            category: _category(),
          ),
          overrides: _overrides(
            accounts: [_account(id: 'acc-1', name: 'Nubank')],
            categories: [_category()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Título reflete o ponto de entrada: despesa já realizada.
      expect(find.text('Lançar Despesa'), findsOneWidget);
      // O seletor "Tipo de Cadastro"/"Status" não existe mais no formulário.
      expect(find.text('Status'), findsNothing);
      expect(find.text('Conta'), findsOneWidget);
    });

    testWidgets('agendamento também exige conta', (tester) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.creation(
            type: OrderType.expense,
            status: InstallmentStatus.pending,
            category: _category(),
          ),
          overrides: _overrides(
            accounts: [_account(id: 'acc-unica', name: 'Nubank')],
            categories: [_category()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Planejar Despesa'), findsOneWidget);
      expect(find.text('Status'), findsNothing);

      // Agendamento deixou de ser exceção: o campo de conta rejeita vazio
      // como em qualquer outro lançamento.
      final accountField = tester.widget<AccountFormField>(
        find.byType(AccountFormField).first,
      );

      expect(accountField.validator, isNotNull);
      expect(accountField.validator!(null), 'Campo obrigatório.');

      // Com uma conta só, ela já vem escolhida e o seletor não abre sozinho.
      expect(accountField.initialValue, 'acc-unica');
      expect(accountField.autoOpen, isFalse);
      expect(find.byType(AccountSelectionScreen), findsNothing);
    });

    testWidgets('edição de parcela mostra o cabeçalho de edição', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.updateInstallment(
            installment: _installment(status: InstallmentStatus.pending),
          ),
          overrides: _overrides(
            accounts: [_account(id: 'acc-1', name: 'Nubank')],
            categories: [_category()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Status'), findsNothing);
    });

    testWidgets('transferência avisa em qual pool vai cair', (tester) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.creation(
            type: OrderType.transfer,
            status: InstallmentStatus.paid,
            accountIdSource: 'acc-corrente',
            accountIdTarget: 'acc-investimento',
          ),
          overrides: _overrides(
            accounts: [
              _account(id: 'acc-corrente', name: 'Nubank'),
              _investmentAccount(id: 'acc-investimento', name: 'Tesouro'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A categoria não é trocada por baixo dos panos: o formulário explica
      // em qual pool a transferência vai cair.
      expect(find.text('Vai contar como Investimentos'), findsOneWidget);
    });
  });
}
