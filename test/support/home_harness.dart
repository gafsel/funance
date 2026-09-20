import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'journey_fakes.dart';

/// Monta a Home de verdade num teste de widget.
///
/// A Jornada puxa oito blocos, cada um com o seu provider e o seu Firebase.
/// Sem um lugar comum para os dublês, cada teste da Home recomeçaria do zero
/// — e foi exatamente por isso que a ORDEM dos blocos, que é a decisão
/// principal da tela, nunca teve teste nenhum.

/// Dia fixo. A Home fala de "hoje" e "amanhã" em três blocos.
final homeToday = DateTime(2026, 3, 15, 9);

mixin _NaoUsado {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado na Home');
}

class _FinanceFake with _NaoUsado implements IFinanceRepository {
  _FinanceFake(this.installments);

  final List<InstallmentModel> installments;

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) => Stream.value(installments);

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
  }) async => QueryChunk(items: installments);
}

class _AccountsFake with _NaoUsado implements IAccountRepository {
  _AccountsFake(this.accounts);

  final List<AccountModel> accounts;

  @override
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  }) => Stream.value(
    type == null ? accounts : accounts.where((a) => a.type == type).toList(),
  );
}

class _CategoriesFake with _NaoUsado implements ICategoryRepository {
  _CategoriesFake(this.categories);

  final List<CategoryModel> categories;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) =>
      Stream.value(categories);
}

class _SummaryFake with _NaoUsado implements IPeriodSummaryRepository {
  _SummaryFake(this.summary);

  final PeriodSummaryModel? summary;

  @override
  Stream<PeriodSummaryModel?> watchMonth(
    String workspaceId,
    int year,
    int month,
  ) => Stream.value(summary);
}

class _AutomaticFake implements IAutomaticTransactionRepository {
  _AutomaticFake(this.pending);

  final List<AutomaticTransactionModel> pending;

  @override
  Future<List<AutomaticTransactionModel>> getPendingTransactions(
    String workspaceId,
  ) async => pending;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _GoalsFake with _NaoUsado implements IGoalRepository {
  _GoalsFake(this.goals);

  final List<GoalModel> goals;

  @override
  Stream<List<GoalModel>> watchGoals(String workspaceId) => Stream.value(goals);
}

class _CoachingFake with _NaoUsado implements ICoachingRepository {
  _CoachingFake(this.last);

  final CoachingModel? last;

  @override
  Future<CoachingModel?> getLastInsight(String workspaceId) async => last;
}

/// Uma parcela pendente com vencimento em [dueDate].
InstallmentModel homeInstallment({
  String id = 'i1',
  String description = 'Aluguel',
  double amount = 1800,
  required DateTime dueDate,
  InstallmentStatus status = InstallmentStatus.pending,
}) => InstallmentModel(
  id: id,
  orderId: 'o-$id',
  amount: amount,
  description: description,
  dueDate: dueDate,
  status: status,
  type: OrderType.expense,
  installmentType: InstallmentType.single,
);

/// As três missões da semana, como o servidor as escreve: uma cumprida, uma
/// em andamento com botão e uma ainda no começo.
List<WeeklyMissionModel> homeTypicalMissions() => const [
  WeeklyMissionModel(
    id: 'm1',
    name: 'Planejar 5 categorias',
    type: WeeklyMissionType.consistency,
    status: WeeklyMissionStatus.completed,
    weekId: '2026-W37',
    target: 5,
    progress: 5,
    xp: 40,
    actionPath: '/planning',
  ),
  WeeklyMissionModel(
    id: 'm2',
    name: 'Ficar no limite de Mercado por 5 dias',
    type: WeeklyMissionType.discipline,
    status: WeeklyMissionStatus.active,
    weekId: '2026-W37',
    target: 5,
    progress: 3,
    xp: 60,
    actionPath: '/planning-50-30-20',
  ),
  WeeklyMissionModel(
    id: 'm3',
    name: 'Conciliar 8 lançamentos',
    type: WeeklyMissionType.organization,
    status: WeeklyMissionStatus.active,
    weekId: '2026-W37',
    target: 8,
    progress: 1,
    xp: 50,
    actionPath: '/reconciliation',
  ),
];

/// Uma semana típica de parcelas: o que alimenta o checklist e o bloco de
/// "vence hoje e amanhã".
List<InstallmentModel> homeTypicalInstallments() => [
  homeInstallment(
    id: 'i1',
    description: 'Aluguel',
    amount: 1800,
    dueDate: homeToday,
  ),
  homeInstallment(
    id: 'i2',
    description: 'Luz',
    amount: 210,
    dueDate: homeToday.add(const Duration(days: 1)),
  ),
  homeInstallment(
    id: 'i3',
    description: 'Internet',
    amount: 99,
    dueDate: homeToday.add(const Duration(days: 3)),
  ),
  homeInstallment(
    id: 'i4',
    description: 'Academia',
    amount: 120,
    dueDate: homeToday.add(const Duration(days: 4)),
  ),
];

/// Uma pendência do leitor de notificação, esperando consolidação.
List<AutomaticTransactionModel> homeTypicalPending() => [
  AutomaticTransactionModel(
    id: 'auto-1',
    description: 'COMPRA CARTAO 4412',
    amount: 89.9,
    date: homeToday,
    type: OrderType.expense,
  ),
];

/// Um mês típico: renda prevista, despesas planejadas e o que já saiu. É o
/// que faz o cabeçalho "quanto sobra" mostrar o NÚMERO em vez do convite para
/// cadastrar renda — e é o estado em que a Home passa a maior parte da vida.
final homeTypicalCategories = <CategoryModel>[
  const CategoryModel(
    id: 'salario',
    name: 'Salário',
    icon: 'payments',
    color: '#00695C',
    type: CategoryType.income,
  ),
  const CategoryModel(
    id: 'moradia',
    name: 'Moradia',
    icon: 'home',
    color: '#1565C0',
    allocation: CategoryAllocation.essential,
  ),
  const CategoryModel(
    id: 'mercado',
    name: 'Mercado',
    icon: 'shopping_cart',
    color: '#2E7D32',
    allocation: CategoryAllocation.essential,
  ),
];

PeriodSummaryModel homeTypicalSummary() => PeriodSummaryModel.month(
  year: homeToday.year,
  month: homeToday.month,
  categories: const {
    'salario': PeriodSummaryCategoryModel(
      specificPlannedAmount: 6000,
      actualAmount: 6000,
    ),
    'moradia': PeriodSummaryCategoryModel(
      specificPlannedAmount: 1800,
      actualAmount: 1800,
    ),
    'mercado': PeriodSummaryCategoryModel(
      specificPlannedAmount: 900,
      actualAmount: 640,
    ),
  },
  lastUpdate: homeToday,
);

/// Uma meta EM ANDAMENTO.
///
/// O prazo é relativo ao relógio de verdade, e não ao [homeToday]: quem
/// decide se a meta ainda corre é `GoalProgressUi.isAwaitingOutcome`, que lê
/// `DateTime.now()` direto. Com um prazo fixo no calendário a meta virava
/// "aguardando apuração" assim que a data passasse, e a fixture de "uma meta
/// em andamento" passaria a medir o estado vazio sem ninguém notar.
List<GoalModel> homeTypicalGoals() => [
  GoalModel.saveMoney(
    id: 'g1',
    name: 'Reserva de emergência',
    targetAmount: 12000,
    currentAmount: 4200,
    deadline: DateTime.now().add(const Duration(days: 120)),
    accountId: 'acc-1',
    startDate: DateTime(2026, 1, 1),
  ),
];

Widget homeApp(Widget home, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Scaffold(body: home),
      ),
    );

List<Override> homeOverrides({
  List<WeeklyMissionModel> missions = const [],
  List<InstallmentModel> installments = const [],
  List<AccountModel> accounts = const [],
  List<GoalModel> goals = const [],
  List<CategoryModel> categories = const [],
  List<AutomaticTransactionModel> pendingAutomatic = const [],
  PeriodSummaryModel? summary,
  CoachingModel? lastInsight,
  List<Override> extra = const [],
}) => [
  clockProvider.overrideWithValue(() => homeToday),
  WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('ws-home'),
  WorkspaceViewProviders.workspace.overrideWith(
    (ref) => TestWorkspaceNotifier(workspaceStateFor()),
  ),
  WorkspaceDomainProviders.repository.overrideWithValue(
    FakeWorkspaceRepository(),
  ),
  AuthDomainProviders.currentUser.overrideWithValue(null),
  JourneyDomainProviders.repository.overrideWithValue(
    FakeJourneyRepository(missions: missions),
  ),
  FinanceDomainProviders.repository.overrideWithValue(
    _FinanceFake(installments),
  ),
  AccountDomainProviders.repository.overrideWithValue(_AccountsFake(accounts)),
  CategoryDomainProviders.repository.overrideWithValue(
    _CategoriesFake(categories),
  ),
  PeriodSummaryDomainProviders.repository.overrideWithValue(
    _SummaryFake(summary),
  ),
  AutomaticTransactionDomainProviders.repository.overrideWithValue(
    _AutomaticFake(pendingAutomatic),
  ),
  GoalDomainProvider.repository.overrideWithValue(_GoalsFake(goals)),
  CoachingDomainProviders.repository.overrideWithValue(
    _CoachingFake(lastInsight),
  ),
  ...extra,
];

/// Monta [home] e deixa os streams assentarem.
Future<void> pumpHome(
  WidgetTester tester,
  Widget home, {
  required List<Override> overrides,
  Size size = const Size(420, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(homeApp(home, overrides: overrides));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
