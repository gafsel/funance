import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';


/// Eventos do funil principal do produto.
///
/// Regra inegociável: nenhum parâmetro pode conter valor monetário, descrição
/// digitada pelo usuário ou id de documento. Só dimensões categóricas de baixa
/// cardinalidade, para não transformar o analytics em vazamento de dados
/// financeiros.
abstract class AnalyticsService {
  /// Usuário avançou uma etapa do onboarding.
  Future<void> logOnboardingStep(String step);

  /// Conta criada (corrente, cartão, etc.).
  Future<void> logAccountCreated(String type);

  /// Lançamento salvo no formulário.
  ///
  /// [hadPlanning] indica se a categoria já tinha planejamento vigente no mês
  /// ou se o lançamento casou com uma parcela pendente.
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  });

  /// Parcela marcada como paga/quitada.
  Future<void> logInstallmentPaid();

  /// Planejamento de categorias salvo.
  Future<void> logPlanningCreated();

  /// Usuário abriu o coaching.
  Future<void> logCoachingOpened();

  /// Missão semanal concluída.
  Future<void> logMissionCompleted();

  /// Conciliação de extrato confirmada.
  Future<void> logReconciliationDone();
}

/// Nomes dos eventos, em snake_case, centralizados para não divergirem entre
/// a implementação e os testes.
abstract final class AnalyticsEvents {
  static const onboardingStep = 'onboarding_step';
  static const accountCreated = 'account_created';
  static const transactionSaved = 'transaction_saved';
  static const installmentPaid = 'installment_paid';
  static const planningCreated = 'planning_created';
  static const coachingOpened = 'coaching_opened';
  static const missionCompleted = 'mission_completed';
  static const reconciliationDone = 'reconciliation_done';
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logOnboardingStep(String step) =>
      _log(AnalyticsEvents.onboardingStep, {'step': step});

  @override
  Future<void> logAccountCreated(String type) =>
      _log(AnalyticsEvents.accountCreated, {'type': type});

  @override
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  }) => _log(AnalyticsEvents.transactionSaved, {
    'status': status,
    // O Firebase Analytics não aceita bool como parâmetro; mandamos 1/0.
    'had_planning': hadPlanning ? 1 : 0,
    'type': type,
  });

  @override
  Future<void> logInstallmentPaid() => _log(AnalyticsEvents.installmentPaid);

  @override
  Future<void> logPlanningCreated() => _log(AnalyticsEvents.planningCreated);

  @override
  Future<void> logCoachingOpened() => _log(AnalyticsEvents.coachingOpened);

  @override
  Future<void> logMissionCompleted() => _log(AnalyticsEvents.missionCompleted);

  @override
  Future<void> logReconciliationDone() =>
      _log(AnalyticsEvents.reconciliationDone);

  /// Analytics nunca pode derrubar um fluxo de negócio: qualquer falha de
  /// envio é engolida e apenas registrada localmente.
  Future<void> _log(String name, [Map<String, Object>? parameters]) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error, stack) {
      developer.log(
        'Falha ao enviar evento $name',
        name: 'funances.analytics',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

/// Implementação inerte, usada em testes e em ambientes sem Analytics.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logOnboardingStep(String step) async {}

  @override
  Future<void> logAccountCreated(String type) async {}

  @override
  Future<void> logTransactionSaved({
    required String status,
    required bool hadPlanning,
    required String type,
  }) async {}

  @override
  Future<void> logInstallmentPaid() async {}

  @override
  Future<void> logPlanningCreated() async {}

  @override
  Future<void> logCoachingOpened() async {}

  @override
  Future<void> logMissionCompleted() async {}

  @override
  Future<void> logReconciliationDone() async {}
}
