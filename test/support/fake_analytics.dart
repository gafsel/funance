import 'package:funances/core/analytics/analytics_service.dart';

/// Registro de chamadas do analytics, para verificar o que o formulário emite.
class FakeAnalyticsService implements AnalyticsService {
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  }) async {
    events.add((
      name: AnalyticsEvents.transactionSaved,
      params: {'status': status, 'had_planning': hadPlanning, 'type': type},
    ));
  }

  @override
  Future<void> logInstallmentPaid() async {
    events.add((name: AnalyticsEvents.installmentPaid, params: {}));
  }

  @override
  Future<void> logMissionCompleted() async {
    events.add((name: AnalyticsEvents.missionCompleted, params: {}));
  }

  @override
  Future<void> logOnboardingStep(String step) async {}

  @override
  Future<void> logAccountCreated(String type) async {}

  @override
  Future<void> logPlanningCreated() async {}

  @override
  Future<void> logCoachingOpened() async {}

  @override
  Future<void> logReconciliationDone() async {}

  @override
  Future<void> logMemberRemoved() async {}

  @override
  Future<void> logUnplannedNudgeShown() async {
    events.add((name: AnalyticsEvents.unplannedNudgeShown, params: {}));
  }

  @override
  Future<void> logUnplannedNudgeConverted(String action) async {
    events.add((
      name: AnalyticsEvents.unplannedNudgeConverted,
      params: {'action': action},
    ));
  }

  ({String name, Map<String, Object> params})? find(String name) =>
      events.where((e) => e.name == name).firstOrNull;
}
