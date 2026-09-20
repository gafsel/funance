import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/coaching/domain/repositories/coaching_repository.dart';
import 'package:funances/features/coaching/domain/services/coaching_service.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/repositories/planning_analysis_repository.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/planning_analysis_service.dart';
import 'package:funances/features/finance/domain/services/reconciliation_service.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/domain/repositories/goal_repository.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// Nenhum teste aqui chama método de repositório: os serviços só guardam a
/// referência. Um `noSuchMethod` que explode deixa isso explícito.
mixin _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

class _FakeWorkspaceRepository with _Unimplemented
    implements IWorkspaceRepository {}

class _FakeFinanceRepository with _Unimplemented
    implements IFinanceRepository {}

class _FakeAccountRepository with _Unimplemented
    implements IAccountRepository {}

class _FakeCategoryRepository with _Unimplemented
    implements ICategoryRepository {}

class _FakePeriodSummaryRepository with _Unimplemented
    implements IPeriodSummaryRepository {}

class _FakeReconciliationRepository with _Unimplemented
    implements IReconciliationRepository {}

class _FakeAutomaticTransactionRepository with _Unimplemented
    implements IAutomaticTransactionRepository {}

class _FakePlanningAnalysisRepository with _Unimplemented
    implements IPlanningAnalysisRepository {}

class _FakeCoachingRepository with _Unimplemented
    implements ICoachingRepository {}

class _FakeGoalRepository with _Unimplemented implements IGoalRepository {}

/// Substitui o `WorkspaceNotifier` real (que assina o Firestore) por um que
/// o teste controla diretamente.
class _TestWorkspaceNotifier extends WorkspaceNotifier {
  _TestWorkspaceNotifier(WorkspaceState initial)
    : super(_FakeWorkspaceRepository()) {
    state = initial;
  }

  void emit(WorkspaceState next) => state = next;
}

WorkspaceState _stateFor(String id, {required int xp, int level = 1}) {
  final workspace = WorkspaceModel(
    id: id,
    name: 'Casa',
    type: WorkspaceType.personal,
    createdAt: DateTime(2026, 1, 1),
    xp: xp,
    level: level,
    unlockedBadges: const {'first_transaction': '2026-01-02'},
  );

  return WorkspaceState(
    currentWorkspace: workspace,
    availableWorkspaces: [workspace],
    initialLoadDone: true,
  );
}

void main() {
  // `AccountDomainProviders.service` observa o `todayProvider` desde que o
  // "saldo atual" virou "o último saldo até hoje": o teto de data precisa
  // acompanhar a virada da meia-noite, e o notifier da data escuta o ciclo de
  // vida do app pelo `WidgetsBinding`.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestWorkspaceNotifier notifier;
  late ProviderContainer container;

  setUp(() {
    notifier = _TestWorkspaceNotifier(_stateFor('ws-1', xp: 100));
    container = ProviderContainer(
      overrides: [
        WorkspaceViewProviders.workspace.overrideWith((ref) => notifier),
        WorkspaceDomainProviders.repository.overrideWithValue(
          _FakeWorkspaceRepository(),
        ),
        FinanceDomainProviders.repository.overrideWithValue(
          _FakeFinanceRepository(),
        ),
        AccountDomainProviders.repository.overrideWithValue(
          _FakeAccountRepository(),
        ),
        CategoryDomainProviders.repository.overrideWithValue(
          _FakeCategoryRepository(),
        ),
        PeriodSummaryDomainProviders.repository.overrideWithValue(
          _FakePeriodSummaryRepository(),
        ),
        ReconciliationDomainProviders.repository.overrideWithValue(
          _FakeReconciliationRepository(),
        ),
        AutomaticTransactionDomainProviders.repository.overrideWithValue(
          _FakeAutomaticTransactionRepository(),
        ),
        PlanningAnalysisDomainProviders.repository.overrideWithValue(
          _FakePlanningAnalysisRepository(),
        ),
        CoachingDomainProviders.repository.overrideWithValue(
          _FakeCoachingRepository(),
        ),
        GoalDomainProvider.repository.overrideWithValue(_FakeGoalRepository()),
      ],
    );

    // Providers autoDispose morreriam entre um `read` e outro sem um listener.
    for (final provider in <ProviderListenable<Object?>>[
      FinanceDomainProviders.service,
      AccountDomainProviders.service,
      CategoryDomainProviders.service,
      PeriodSummaryDomainProviders.service,
      ReconciliationDomainProviders.service,
      AutomaticTransactionDomainProviders.service,
      PlanningAnalysisDomainProviders.service,
      CoachingDomainProviders.service,
      GoalDomainProvider.service,
    ]) {
      container.listen<Object?>(provider, (_, _) {}, fireImmediately: true);
    }
  });

  tearDown(() => container.dispose());

  Map<String, Object> snapshotServices() => {
    'FinanceService': container.read(FinanceDomainProviders.service),
    'AccountService': container.read(AccountDomainProviders.service),
    'CategoryService': container.read(CategoryDomainProviders.service),
    'PeriodSummaryService': container.read(
      PeriodSummaryDomainProviders.service,
    ),
    'ReconciliationService': container.read(
      ReconciliationDomainProviders.service,
    ),
    'AutomaticTransactionService': container.read(
      AutomaticTransactionDomainProviders.service,
    ),
    'PlanningAnalysisService': container.read(
      PlanningAnalysisDomainProviders.service,
    ),
    'CoachingService': container.read(CoachingDomainProviders.service),
    'GoalService': container.read(GoalDomainProvider.service),
  };

  test('ganho de XP no mesmo workspace não recria os serviços', () {
    final before = snapshotServices();

    notifier.emit(_stateFor('ws-1', xp: 350, level: 2));

    final after = snapshotServices();

    for (final entry in before.entries) {
      expect(
        identical(entry.value, after[entry.key]),
        isTrue,
        reason: '${entry.key} foi recriado após um ganho de XP',
      );
    }
  });

  test('trocar de workspace recria os serviços com o novo id', () {
    final before = snapshotServices();

    notifier.emit(_stateFor('ws-2', xp: 0));

    final after = snapshotServices();

    for (final entry in before.entries) {
      expect(
        identical(entry.value, after[entry.key]),
        isFalse,
        reason: '${entry.key} não foi recriado ao trocar de workspace',
      );
    }

    expect(
      (after['FinanceService']! as FinanceService).workspaceId,
      'ws-2',
    );
    expect((after['AccountService']! as AccountService).workspaceId, 'ws-2');
    expect((after['CategoryService']! as CategoryService).workspaceId, 'ws-2');
    expect(
      (after['PeriodSummaryService']! as PeriodSummaryService).workspaceId,
      'ws-2',
    );
    expect(
      (after['ReconciliationService']! as ReconciliationService).workspaceId,
      'ws-2',
    );
    expect(
      (after['AutomaticTransactionService']! as AutomaticTransactionService)
          .workspaceId,
      'ws-2',
    );
    expect(
      (after['PlanningAnalysisService']! as PlanningAnalysisService)
          .workspaceId,
      'ws-2',
    );
    expect((after['CoachingService']! as CoachingService).workspaceId, 'ws-2');
    expect((after['GoalService']! as GoalService).workspaceId, 'ws-2');
  });

  test('o recorte de gamificação acompanha XP, nível e badges', () {
    expect(
      container.read(WorkspaceViewProviders.gamification),
      const WorkspaceGamification(
        workspaceId: 'ws-1',
        xp: 100,
        level: 1,
        unlockedBadges: {'first_transaction': '2026-01-02'},
      ),
    );

    notifier.emit(_stateFor('ws-1', xp: 350, level: 2));

    expect(container.read(WorkspaceViewProviders.gamification).xp, 350);
    expect(container.read(WorkspaceViewProviders.gamification).level, 2);
  });
}
