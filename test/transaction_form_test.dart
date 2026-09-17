import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_selection_screen.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class _StubAnalyticsService implements AnalyticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _RecordingAnalytics implements AnalyticsService {
  Map<String, Object>? transactionSaved;

  @override
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  }) async {
    transactionSaved = {
      'status': status,
      'had_planning': hadPlanning,
      'type': type,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Só os métodos que o formulário toca; qualquer outro grita em vez de
/// devolver null silencioso.
class _FakeFinanceRepository implements IFinanceRepository {
  _FakeFinanceRepository({this.installments = const [], this.gate});

  final List<InstallmentModel> installments;

  /// Segura a resposta da busca até o teste liberar, para observar o
  /// formulário no intervalo em que a oferta ainda não chegou.
  final Completer<void>? gate;
  final List<
    ({
      String? categoryId,
      OrderType? type,
      int? limit,
      InstallmentStatus? status,
      DateTime? startDate,
      DateTime? endDate,
    })
  >
  queryCalls = [];

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
    if (gate != null) await gate!.future;

    queryCalls.add((
      categoryId: categoryId,
      type: type,
      limit: limit,
      status: status,
      startDate: startDate,
      endDate: endDate,
    ));

    // O Firestore filtra por status e janela; o fake precisa filtrar também,
    // senão a busca de agendamentos "acharia" parcelas já pagas.
    final matching = installments.where((installment) {
      if (status != null && installment.status != status) return false;
      if (categoryId != null && installment.category?.id != categoryId) {
        return false;
      }
      if (startDate != null && installment.dueDate.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && installment.dueDate.isAfter(endDate)) return false;
      return true;
    }).toList();

    return QueryChunk(
      items: limit == null ? matching : matching.take(limit).toList(),
    );
  }

  final List<OrderModel> savedOrders = [];

  /// O que o servidor respondeu à criação. Os testes que exercitam o caminho
  /// offline trocam isto por `pending`.
  WriteOutcome addOrderOutcome = WriteOutcome.confirmed;

  /// O mesmo, para as edições.
  WriteOutcome updateOutcome = WriteOutcome.confirmed;

  @override
  Future<Written<OrderModel>> addOrder(
    String workspaceId,
    OrderModel order,
  ) async {
    savedOrders.add(order);
    return (value: order, outcome: addOrderOutcome);
  }

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  }) async => const [];

  @override
  Future<WriteOutcome> updateOrder(String workspaceId, OrderModel order) async {
    return updateOutcome;
  }

  @override
  Future<WriteOutcome> updateInstallment(
    String workspaceId,
    InstallmentModel entry,
  ) async {
    return updateOutcome;
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
  IFinanceRepository? repository,
}) => FinanceService(
  workspaceId: 'ws-test',
  repository: repository ?? _FakeFinanceRepository(installments: installments),
  accountRepository: _FakeAccountRepository(accounts: accounts),
  categoryRepository: _FakeCategoryRepository(),
);

/// Um dia fixo, para as janelas de busca não dependerem de quando o teste
/// roda: março/2026, com fevereiro como "mês anterior".
final _hoje = DateTime(2026, 3, 15);

TransactionFormNotifier _notifierFor(
  TransactionFormState state, {
  FinanceService? financeService,
  AnalyticsService? analytics,
}) => TransactionFormNotifier(
  state,
  financeService: financeService ?? _financeService(),
  analytics: analytics ?? _StubAnalyticsService(),
  today: _hoje,
);

Widget _hostedForm(Widget screen, {required List<Override> overrides}) {
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

/// Agendamento vencido em março, no mês do relógio fixo dos testes.
InstallmentModel _agendamentoDeMarco() => _installment(
  id: 'inst-agendada',
  description: 'Aluguel de março',
  amount: 2000,
  dueDate: DateTime(2026, 3, 5),
  status: InstallmentStatus.pending,
  installmentType: InstallmentType.single,
  installmentCount: null,
);

Widget _hostedRouter(GoRouter router, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        routerConfig: router,
      ),
    );

List<Override> _overrides({
  List<AccountModel> accounts = const [],
  List<CategoryModel> categories = const [],
  List<InstallmentModel> installments = const [],
  Completer<void>? gate,
}) => [
  WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-test'),
  analyticsServiceProvider.overrideWithValue(_StubAnalyticsService()),
  WorkspaceDomainProviders.repository.overrideWithValue(
    _FakeWorkspaceRepository(),
  ),
  AuthDomainProviders.currentUser.overrideWithValue(null),
  // Dia fixo: as janelas de busca de agendamento não podem depender de
  // quando o teste roda.
  clockProvider.overrideWithValue(() => _hoje),
  FinanceDomainProviders.repository.overrideWithValue(
    _FakeFinanceRepository(installments: installments, gate: gate),
  ),
  AccountDomainProviders.repository.overrideWithValue(
    _FakeAccountRepository(accounts: accounts),
  ),
  CategoryDomainProviders.repository.overrideWithValue(
    _FakeCategoryRepository(categories: categories),
  ),
];

void main() {
  group('lançamento que o servidor ainda não confirmou', () {
    /// Offline o pedido entra no cache local, mas as PARCELAS nascem de um
    /// trigger no servidor: elas não existem em lugar nenhum enquanto a
    /// escrita não subir. A tela lê parcelas, então dizer "salvo!" fazia o
    /// usuário procurar na lista algo que ainda não estava lá — o lançamento
    /// parecia ter sumido.
    Future<TransactionFormNotifier> salvar(WriteOutcome outcome) async {
      final repository = _FakeFinanceRepository()..addOrderOutcome = outcome;
      final notifier = _notifierFor(
        TransactionFormState.creation(type: OrderType.expense),
        financeService: _financeService(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.submit();

      return notifier;
    }

    test('escrita pendente é reportada como pendente', () async {
      final notifier = await salvar(WriteOutcome.pending);

      expect(notifier.lastWriteOutcome, WriteOutcome.pending);
    });

    test('com o servidor confirmando, o save é um save normal', () async {
      final notifier = await salvar(WriteOutcome.confirmed);

      expect(notifier.lastWriteOutcome, WriteOutcome.confirmed);
    });

    test('a EDIÇÃO também reporta pendência', () async {
      // Só o ramo de criação gravava o resultado; editar offline dizia
      // "salvo!" com a mesma cara de sempre.
      final repository = _FakeFinanceRepository()
        ..updateOutcome = WriteOutcome.pending;
      final notifier = _notifierFor(
        TransactionFormState.updateInstallment(_installment()),
        financeService: _financeService(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.submit();

      expect(notifier.lastWriteOutcome, WriteOutcome.pending);
    });

    test('um save novo não herda o resultado do anterior', () async {
      // Sem zerar no início do submit, quem salvasse offline e depois com
      // rede continuaria vendo "salvo neste dispositivo".
      final repository = _FakeFinanceRepository()
        ..addOrderOutcome = WriteOutcome.pending;
      final notifier = _notifierFor(
        TransactionFormState.creation(type: OrderType.expense),
        financeService: _financeService(repository: repository),
      );
      addTearDown(notifier.dispose);

      await notifier.submit();
      expect(notifier.lastWriteOutcome, WriteOutcome.pending);

      // A rede voltou.
      repository.addOrderOutcome = WriteOutcome.confirmed;
      repository.updateOutcome = WriteOutcome.confirmed;

      await notifier.submit();

      expect(notifier.lastWriteOutcome, WriteOutcome.confirmed);
    });
  });

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
          installments: [
            _installment(
              accountId: 'acc-ultima',
              status: InstallmentStatus.paid,
            ),
          ],
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

    test('parcela liquidada também conta como conta já usada', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            _installment(
              accountId: 'acc-liquidada',
              status: InstallmentStatus.settled,
            ),
          ],
          accounts: [
            _account(id: 'acc-liquidada', name: 'Nubank'),
            _account(id: 'acc-outra', name: 'Itaú'),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, 'acc-liquidada');
    });

    test('agendamento pendente não é histórico de conta usada', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            _installment(
              accountId: 'acc-agendada',
              status: InstallmentStatus.pending,
            ),
          ],
          accounts: [
            _account(id: 'acc-agendada', name: 'Nubank'),
            _account(id: 'acc-outra', name: 'Itaú'),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state.accountIdSource,
        isNull,
        reason: 'pendente não saiu de conta nenhuma ainda',
      );
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

    test(
      'não escolhe nada quando há várias contas e nenhum histórico',
      () async {
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
      },
    );

    test('a conta vinda do ponto de entrada não é sobrescrita', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          category: _category(),
          accountIdSource: 'acc-escolhida',
        ),
        financeService: _financeService(
          installments: [
            _installment(
              accountId: 'acc-ultima',
              status: InstallmentStatus.paid,
            ),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.accountIdSource, 'acc-escolhida');
    });
  });

  group('casamento com agendamento', () {
    InstallmentModel agendamento({
      String id = 'inst-agendada',
      String description = 'Aluguel',
      DateTime? dueDate,
    }) => _installment(
      id: id,
      description: description,
      dueDate: dueDate ?? DateTime(2026, 3, 5),
      status: InstallmentStatus.pending,
      installmentType: InstallmentType.single,
      installmentCount: null,
    );

    test('oferece os pendentes da categoria no mês e no anterior', () async {
      final repository = _FakeFinanceRepository(
        installments: [
          agendamento(),
          agendamento(id: 'inst-mes-passado', dueDate: DateTime(2026, 2, 5)),
        ],
      );

      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: FinanceService(
          workspaceId: 'ws-test',
          repository: repository,
          accountRepository: _FakeAccountRepository(),
          categoryRepository: _FakeCategoryRepository(),
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.pendingMatches, hasLength(2));
      expect(notifier.state.hasPendingMatches, isTrue);
      expect(notifier.state.loadingMatches, isFalse);

      final matchCall = repository.queryCalls.firstWhere(
        (call) => call.status == InstallmentStatus.pending,
      );
      expect(matchCall.limit, TransactionFormNotifier.maxPendingMatches);
      expect(matchCall.categoryId, 'cat-1');
      expect(matchCall.type, OrderType.expense);
      // Janela: do primeiro dia do mês anterior ao último do mês corrente.
      expect(matchCall.startDate, DateTime(2026, 2, 1));
      expect(matchCall.endDate, DateTime(2026, 3, 31, 23, 59, 59));
    });

    test('sem pendente na categoria, nada a oferecer', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            _installment(status: InstallmentStatus.paid),
            agendamento().copyWith(category: _category(id: 'outra-cat')),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.pendingMatches, isEmpty);
      expect(notifier.state.hasPendingMatches, isFalse);
      expect(notifier.state.matchedInstallmentId, isNull);
    });

    test('agendar não oferece casamento', () async {
      final repository = _FakeFinanceRepository(installments: [agendamento()]);

      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.pending,
          category: _category(),
        ),
        financeService: FinanceService(
          workspaceId: 'ws-test',
          repository: repository,
          accountRepository: _FakeAccountRepository(),
          categoryRepository: _FakeCategoryRepository(),
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.pendingMatches, isEmpty);
      expect(
        repository.queryCalls.where(
          (call) => call.status == InstallmentStatus.pending,
        ),
        isEmpty,
        reason: 'agendar em cima de agendamento não é casamento',
      );
    });

    test('escolher um agendamento leva a tela para a edição dele', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(installments: [agendamento()]),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      notifier.selectMatch(notifier.state.pendingMatches.single);

      expect(notifier.state.matchedInstallment, isNotNull);
      expect(notifier.state.matchedInstallmentId, 'inst-agendada');
    });

    test('a oferta vem do mais antigo para o mais novo', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            agendamento(id: 'inst-marco', dueDate: DateTime(2026, 3, 5)),
            agendamento(id: 'inst-fevereiro', dueDate: DateTime(2026, 2, 5)),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      // O atrasado vem primeiro: é o candidato mais provável e é o que vira
      // missão vencida se ficar para trás.
      expect(notifier.state.pendingMatches.map((match) => match.id), [
        'inst-fevereiro',
        'inst-marco',
      ]);
    });

    test('desfazer o casamento devolve o que já estava digitado', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(installments: [agendamento()]),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      notifier.updateAmount(187.4);
      notifier.updateDescription('Luz de março');
      notifier.selectMatch(notifier.state.pendingMatches.single);

      notifier.clearMatch();

      expect(notifier.state.matchedInstallment, isNull);
      expect(notifier.state.amount, 187.4);
      expect(notifier.state.description, 'Luz de março');
      expect(
        notifier.state.hasPendingMatches,
        isTrue,
        reason: 'tocar no agendamento errado não é dizer que o gasto é novo',
      );
    });

    test('valor digitado destaca o pendente de mesmo valor', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            agendamento(id: 'inst-luz').copyWith(amount: 187.4),
            agendamento(
              id: 'inst-aluguel',
              dueDate: DateTime(2026, 3, 8),
            ).copyWith(amount: 2000),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.likelyMatchId, isNull, reason: 'nada digitado');

      notifier.updateAmount(187.4);
      expect(notifier.state.likelyMatchId, 'inst-luz');

      // Um centavo de diferença continua sendo a mesma conta.
      notifier.updateAmount(187.41);
      expect(notifier.state.likelyMatchId, 'inst-luz');

      notifier.updateAmount(45);
      expect(
        notifier.state.likelyMatchId,
        isNull,
        reason: 'valor que não bate com nenhum pendente não destaca nada',
      );
    });

    test('dois pendentes de mesmo valor não destacam nenhum', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(
          installments: [
            agendamento(id: 'inst-a').copyWith(amount: 100),
            agendamento(
              id: 'inst-b',
              dueDate: DateTime(2026, 3, 8),
            ).copyWith(amount: 100),
          ],
        ),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      notifier.updateAmount(100);

      expect(
        notifier.state.likelyMatchId,
        isNull,
        reason: 'apontar uma das duas seria chute com cara de resposta',
      );
    });

    test('dispensar deixa o lançamento seguir como novo', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(installments: [agendamento()]),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      notifier.dismissMatches();

      expect(notifier.state.dismissedMatch, isTrue);
      expect(notifier.state.hasPendingMatches, isFalse);
      expect(notifier.state.matchedInstallmentId, isNull);
      expect(
        notifier.state.creation,
        isTrue,
        reason: 'continua criando uma order',
      );
    });

    test('trocar de categoria refaz a oferta e desfaz a recusa', () async {
      final notifier = _notifierFor(
        TransactionFormState.creation(
          type: OrderType.expense,
          status: InstallmentStatus.paid,
          category: _category(),
        ),
        financeService: _financeService(installments: [agendamento()]),
      );
      addTearDown(notifier.dispose);

      await Future<void>.delayed(Duration.zero);
      notifier.dismissMatches();
      expect(notifier.state.dismissedMatch, isTrue);

      notifier.updateCategory(_category(id: 'outra-cat'));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.dismissedMatch, isFalse);
      expect(notifier.state.pendingMatches, isEmpty);
    });

    test(
      'lançamento novo sem casar e sem limite emite had_planning=false',
      () async {
        final analytics = _RecordingAnalytics();
        final notifier = _notifierFor(
          TransactionFormState.creation(
            type: OrderType.expense,
            status: InstallmentStatus.paid,
            category: _category(),
            amount: 100,
            description: 'Compra do mês',
            accountIdSource: 'acc-1',
          ),
          financeService: _financeService(installments: [agendamento()]),
          analytics: analytics,
        );
        addTearDown(notifier.dispose);

        await Future<void>.delayed(Duration.zero);
        notifier.dismissMatches();
        await notifier.submit();

        expect(analytics.transactionSaved?['had_planning'], isFalse);
      },
    );
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

      expect(find.text('Agendar Despesa'), findsOneWidget);
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

    testWidgets('banner oferece o agendamento e some ao dispensar', (
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
            installments: [_agendamentoDeMarco()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Existe um agendamento nesta categoria. Quitar este?'),
        findsOneWidget,
      );
      expect(find.text('Aluguel de março'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pending-match-inst-agendada')),
        findsOneWidget,
      );

      await tester.tap(find.text('É um gasto novo'));
      await tester.pumpAndSettle();

      expect(
        find.text('Existe um agendamento nesta categoria. Quitar este?'),
        findsNothing,
      );
      // Continua sendo um lançamento novo: o cabeçalho é o de criação.
      expect(find.text('Lançar Despesa'), findsOneWidget);
    });

    testWidgets('tocar no agendamento passa a tela para a quitação dele', (
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
            installments: [_agendamentoDeMarco()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('pending-match-inst-agendada')),
      );
      await tester.pumpAndSettle();

      // Deixou de criar uma order: agora é edição da parcela agendada.
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Lançar Despesa'), findsNothing);
      expect(
        find.text('Existe um agendamento nesta categoria. Quitar este?'),
        findsNothing,
      );
    });

    testWidgets('"Não era esse" volta ao formulário com o que foi digitado', (
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
            installments: [_agendamentoDeMarco()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.ancestor(
          of: find.text('Descrição'),
          matching: find.byType(TextFormField),
        ),
        'Aluguel pago hoje',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('pending-match-inst-agendada')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('unmatch-action')));
      await tester.pumpAndSettle();

      // Voltou a criar uma order, e o que o usuário já tinha digitado
      // continua lá: desfazer um toque errado não pode custar o formulário.
      expect(find.text('Lançar Despesa'), findsOneWidget);
      expect(find.text('Aluguel pago hoje'), findsOneWidget);
      // E a oferta continua de pé, para ele escolher o agendamento certo.
      expect(
        find.byKey(const ValueKey('pending-match-inst-agendada')),
        findsOneWidget,
      );
    });

    testWidgets('a quitação normal não oferece "Não era esse"', (tester) async {
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

      expect(
        find.byKey(const ValueKey('unmatch-action')),
        findsNothing,
        reason: 'quem abriu a parcela pela lista não casou nada para desfazer',
      );
    });

    testWidgets('o espaço da oferta é reservado enquanto a busca corre', (
      tester,
    ) async {
      final gate = Completer<void>();

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
            installments: [_agendamentoDeMarco()],
            gate: gate,
          ),
        ),
      );
      await tester.pump();

      // O banner já ocupa o espaço, então o campo de valor nasce onde vai
      // ficar: a oferta não vai empurrá-lo quando a resposta chegar.
      expect(find.text('Procurando agendamentos…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      final antes = tester.getTopLeft(find.byType(MoneyFormField)).dy;

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Procurando agendamentos…'), findsNothing);
      expect(find.text('Aluguel de março'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(MoneyFormField)).dy,
        antes,
        reason: 'a oferta não pode empurrar o campo sob o dedo do usuário',
      );
    });

    testWidgets('o pendente de mesmo valor vem destacado', (tester) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.creation(
            type: OrderType.expense,
            status: InstallmentStatus.paid,
            category: _category(),
            amount: 2000,
          ),
          overrides: _overrides(
            accounts: [_account(id: 'acc-1', name: 'Nubank')],
            categories: [_category()],
            installments: [_agendamentoDeMarco()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // O rótulo diz em texto por que a linha está destacada: a cor sozinha
      // não serve a quem não a distingue.
      expect(find.textContaining('mesmo valor'), findsOneWidget);
    });

    testWidgets('consolidação de transação automática abre como realizada', (
      tester,
    ) async {
      // Mesma rota que `_handleConsolidate` monta: status paid e a data da
      // notificação bancária.
      final router = GoRouter(
        initialLocation:
            '/transactions/form?type=expense&status=paid'
            '&description=Compra&amount=87.9'
            '&date=2026-03-12T10%3A30%3A00.000',
        routes: [
          GoRoute(
            path: '/transactions/form',
            builder: (context, state) {
              final status = InstallmentStatus.values
                  .where((e) => e.name == state.uri.queryParameters['status'])
                  .firstOrNull;

              return TransactionFormScreen.creation(
                type: OrderType.expense,
                status: status,
                category: _category(),
                description: state.uri.queryParameters['description'],
                amount: double.tryParse(
                  state.uri.queryParameters['amount'] ?? '',
                ),
                dueDate: DateTime.tryParse(
                  state.uri.queryParameters['date'] ?? '',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        _hostedRouter(
          router,
          overrides: _overrides(
            accounts: [_account(id: 'acc-1', name: 'Nubank')],
            categories: [_category()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Já aconteceu: título de realizado, não de agendamento.
      expect(find.text('Lançar Despesa'), findsOneWidget);
      expect(find.text('Agendar Despesa'), findsNothing);

      final state =
          ProviderScope.containerOf(
            tester.element(find.byType(TransactionFormScreen)),
          ).read(
            FinanceViewProviders.creationForm(
              TransactionCreationArgs(
                type: OrderType.expense,
                status: InstallmentStatus.paid,
                category: _category(),
                description: 'Compra',
                amount: 87.9,
                date: DateTime(2026, 3, 12, 10, 30),
              ),
            ),
          );

      expect(state.status, InstallmentStatus.paid);
      expect(state.paidDate, DateTime(2026, 3, 12, 10, 30));
      expect(state.paidAmount, 87.9);
    });

    testWidgets('sem status no ponto de entrada o lançamento nasce realizado', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hostedForm(
          TransactionFormScreen.creation(
            type: OrderType.expense,
            category: _category(),
          ),
          overrides: _overrides(
            accounts: [_account(id: 'acc-1', name: 'Nubank')],
            categories: [_category()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lançar Despesa'), findsOneWidget);
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
