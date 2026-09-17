import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/domain/repositories/journey_repository.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:rxdart/rxdart.dart';

/// Repositório da Jornada em memória, para os testes montarem a tela sem
/// Firestore.
class FakeJourneyRepository implements IJourneyRepository {
  FakeJourneyRepository({
    this.missions = const [],
    this.xp,
    this.health,
    this.history = const [],
  });

  final List<WeeklyMissionModel> missions;
  final double? xp;
  final FinancialHealth? health;
  final List<FinancialHealthPoint> history;

  /// Argumentos com que o app chamou o repositório — é o que prova que a
  /// semana lida é a do servidor e não uma calculada por engano.
  final List<(String workspaceId, String weekId)> missionCalls = [];
  final List<(String workspaceId, String weekId)> xpCalls = [];

  /// Os fluxos são `BehaviorSubject` e não `Stream.value` para que um teste
  /// possa EMITIR DE NOVO: celebrar uma missão que fecha depende de haver uma
  /// segunda emissão, e o valor sempre chega a quem assina depois — que é
  /// exatamente o que `Stream.value` também fazia.
  late final BehaviorSubject<List<WeeklyMissionModel>> _missions =
      BehaviorSubject<List<WeeklyMissionModel>>.seeded(missions);
  late final BehaviorSubject<FinancialHealth?> _health =
      BehaviorSubject<FinancialHealth?>.seeded(health);

  void emitMissions(List<WeeklyMissionModel> next) => _missions.add(next);

  void emitHealth(FinancialHealth? next) => _health.add(next);

  @override
  Stream<List<WeeklyMissionModel>> watchWeeklyMissions(
    String workspaceId,
    String weekId,
  ) {
    missionCalls.add((workspaceId, weekId));
    return _missions.stream;
  }

  @override
  Stream<double?> watchWeeklyXp(String workspaceId, String weekId) {
    xpCalls.add((workspaceId, weekId));
    return Stream.value(xp);
  }

  @override
  Stream<FinancialHealth?> watchFinancialHealth(String workspaceId) =>
      _health.stream;

  @override
  Stream<List<FinancialHealthPoint>> watchHealthHistory(
    String workspaceId, {
    int months = 6,
  }) => Stream.value(history);
}

class FakeWorkspaceRepository implements IWorkspaceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

/// Substitui o notifier real (que assina o Firestore) por um que o teste
/// controla. Mesmo padrão de `workspace_scoped_services_test.dart`.
class TestWorkspaceNotifier extends WorkspaceNotifier {
  TestWorkspaceNotifier(WorkspaceState initial)
    : super(FakeWorkspaceRepository()) {
    state = initial;
  }
}

WorkspaceState workspaceStateFor({
  String id = 'w1',
  String? currentWeekId = '2026-W37',
}) {
  final workspace = WorkspaceModel(
    id: id,
    name: 'Casa',
    type: WorkspaceType.personal,
    createdAt: DateTime(2026, 1, 1),
    currentWeekId: currentWeekId,
  );

  return WorkspaceState(
    currentWorkspace: workspace,
    availableWorkspaces: [workspace],
    initialLoadDone: true,
  );
}
