// ─────────────────────────────────────────────────────────────────────────────
// Providers de DOMÍNIO de finanças: repositórios e serviços.
//
// Este arquivo nasceu de `presentation/providers.dart`, que tinha 811 linhas e
// era o registro central de TUDO — repositórios, serviços, providers de tela e
// os cálculos derivados do 50-30-20. O `providers.dart` continua existindo
// como barril de `export`s, então nenhum import do app mudou.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/platform/app_platform.dart';
import 'package:funances/features/finance/data/repositories/account_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/automatic_transaction_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:funances/features/finance/data/repositories/unplanned_nudge_store.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/automatic_transaction_service.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/notification_listener_service.dart';
import 'package:funances/features/finance/data/repositories/planning_analysis_repository_impl.dart';
import 'package:funances/features/finance/domain/repositories/planning_analysis_repository.dart';
import 'package:funances/features/finance/domain/services/planning_analysis_service.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/data/repositories/reconciliation_repository_impl.dart';
import 'package:funances/features/finance/domain/services/reconciliation_service.dart';
import 'package:funances/features/finance/presentation/controllers/automatic_transaction_notifier.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/finance/presentation/providers/period_summary_providers.dart';

class AutomaticTransactionDomainProviders {
  static final repository = Provider<IAutomaticTransactionRepository>((ref) {
    return AutomaticTransactionRepositoryImpl();
  });

  static final service = Provider<AutomaticTransactionService>((ref) {
    return AutomaticTransactionService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.watch(repository),
    );
  });

  /// O ouvinte de notificações é Android puro.
  ///
  /// Registrar o serviço real em toda plataforma fazia a web chamar um canal
  /// que não existe (`MissingPluginException`) assim que a tela de transações
  /// automáticas era construída.
  static final notificationService = Provider<INotificationListenerService>((
    ref,
  ) {
    if (!AppPlatform.isAndroid) return const NoopNotificationListenerService();

    return NotificationListenerService(service: ref.watch(service));
  });
}

class AutomaticTransactionViewProviders {
  static final automaticTransactions =
      StateNotifierProvider.autoDispose<
        AutomaticTransactionNotifier,
        AutomaticTransactionState
      >((ref) {
        return AutomaticTransactionNotifier(
          service: ref.watch(AutomaticTransactionDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          notificationService: ref.watch(
            AutomaticTransactionDomainProviders.notificationService,
          ),
        );
      });
}

/// Caminho único para limites e expectativas de categoria.
///
/// A tela simples `/planning`, a 50-30-20 e o onboarding passam todos por
/// aqui: eram três regras diferentes gravando na mesma coleção.
class CategoryPlanningDomainProviders {
  static final service = Provider<CategoryPlanningService>(
    (ref) => CategoryPlanningService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(FinanceDomainProviders.repository),
    ),
  );
}

/// Decide o convite de gasto não planejado (F3.2).
class UnplannedNudgeDomainProviders {
  static final store = Provider<IUnplannedNudgeStore>(
    (ref) => SharedPreferencesUnplannedNudgeStore(),
  );

  static final service = Provider<UnplannedNudgeService>((ref) {
    return UnplannedNudgeService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? '',
      planningService: ref.watch(CategoryPlanningDomainProviders.service),
      summaryService: ref.watch(PeriodSummaryDomainProviders.service),
      store: ref.watch(store),
    );
  });
}

class AccountDomainProviders {
  static final repository = Provider<IAccountRepository>((ref) {
    return AccountRepositoryImpl();
  });

  static final service = Provider<AccountService>(
    (ref) => AccountService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      workspaceRepository: ref.read(WorkspaceDomainProviders.repository),
      // O "saldo atual" é o último saldo ATÉ HOJE, e por isso o serviço
      // precisa do relógio do app — inclusive para o teste poder mentir a
      // data.
      now: ref.watch(clockProvider),
    ),
  );
}

class FinanceDomainProviders {
  static final repository = Provider<IFinanceRepository>(
    (ref) => FinanceRepositoryImpl(),
  );

  static final service = Provider(
    (ref) => FinanceService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      accountRepository: ref.read(AccountDomainProviders.repository),
      categoryRepository: ref.watch(CategoryDomainProviders.repository),
    ),
  );
}

class PlanningAnalysisDomainProviders {
  static final repository = Provider.autoDispose<IPlanningAnalysisRepository>((
    ref,
  ) {
    return PlanningAnalysisRepositoryImpl();
  });

  static final service = Provider.autoDispose<PlanningAnalysisService>((ref) {
    return PlanningAnalysisService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.watch(repository),
    );
  });
}

class ReconciliationDomainProviders {
  static final repository = Provider<IReconciliationRepository>((ref) {
    return ReconciliationRepositoryImpl();
  });

  static final service = Provider<ReconciliationService>((ref) {
    return ReconciliationService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
      accountService: ref.watch(AccountDomainProviders.service),
      financeService: ref.watch(FinanceDomainProviders.service),
      categoryService: ref.watch(CategoryDomainProviders.service),
    );
  });
}

/// Chave estável de uma fatura.
///
/// Chavear a família pelo `InstallmentModel` inteiro vazava um provider a
/// cada edição: freezed gera um valor novo (e portanto uma chave nova) quando
/// qualquer campo muda, e o provider antigo ficava para trás. O id identifica
/// a fatura; a conta, o vencimento e a janela do ciclo são o que o provider
/// precisa, e nenhum deles muda ao editar valor ou descrição.
///
/// F1.8: `cycleStart`/`cycleEnd` vêm PRONTOS do servidor, gravados na própria
/// parcela da fatura. Antes o app recalculava a janela com uma cópia Dart da
/// regra que já divergia da do servidor no clamp do dia — e, como o id da order
/// de fatura deriva da data, os dois podiam falar de faturas diferentes.
typedef InvoiceKey = ({
  String invoiceId,
  String accountId,
  DateTime dueDate,
  DateTime? cycleStart,
  DateTime? cycleEnd,
});

extension InvoiceKeyWindow on InvoiceKey {
  /// `true` quando o servidor já publicou a janela desta fatura.
  bool get hasServerCycle =>
      accountId.isNotEmpty && cycleStart != null && cycleEnd != null;
}

extension InvoiceKeyExtension on InstallmentModel {
  /// Usa a mesma cadeia de resolução de conta da tela de detalhe
  /// (`resolvedAccountId`): cair em string vazia aqui faria o provider
  /// consultar sem filtro de conta e listar o extrato inteiro.
  InvoiceKey get invoiceKey => (
    invoiceId: id,
    accountId: resolvedAccountId ?? "",
    dueDate: dueDate,
    cycleStart: cycleStart,
    cycleEnd: cycleEnd,
  );
}
