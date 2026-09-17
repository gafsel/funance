import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:uuid/uuid.dart';

import '../../../finance/domain/repositories/account_repository.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../goal/domain/repositories/goal_repository.dart';
import '../../../workspace/domain/models/invite_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../../workspace/domain/repositories/category_repository.dart';
import '../../../workspace/domain/repositories/invite_repository.dart';
import '../../../workspace/domain/repositories/workspace_repository.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingService {
  final UserModel user;

  final IAccountRepository accountRepository;
  final ICategoryRepository categoryRepository;
  final IFinanceRepository financeRepository;
  final IInviteRepository inviteRepository;
  final IGoalRepository goalRepository;

  final IAuthRepository authRepository;
  final OnboardingRepository onboardingRepository;
  final IWorkspaceRepository workspaceRepository;

  OnboardingService({
    required this.user,
    required this.accountRepository,
    required this.categoryRepository,
    required this.financeRepository,
    required this.authRepository,
    required this.onboardingRepository,
    required this.workspaceRepository,
    required this.inviteRepository,
    required this.goalRepository,
  });

  Future<PlanningSuggestions> analysePlanning({
    required String workspaceId,
  }) async {
    return onboardingRepository.analysePlanning(workspaceId: workspaceId);
  }

  Future<WorkspaceModel> createWorkspace({required WorkspaceType type}) async {
    final workspace = WorkspaceModel(
      id: const Uuid().v4(),
      name: "(novo)",
      type: type,
      createdAt: DateTime.now(),
      lastOnboardingStep: OnboardingSteps.name,
      members: [user.id],
    );

    return (await workspaceRepository.createWorkspace(workspace)).value;
  }

  Future<void> updateWorkspace(WorkspaceModel workspace) async {
    await workspaceRepository.updateWorkspace(workspace);
  }

  Future<void> sendInvitations({
    required WorkspaceModel workspace,
    required List<String> inviteEmails,
  }) async {
    await Future.wait(
      inviteEmails.map(
        (email) => inviteRepository.sendInvite(
          InviteModel(
            id: const Uuid().v4(),
            workspace: workspace,
            senderId: user.id,
            senderName: user.displayName ?? "",
            receiverEmail: email,
            status: InviteStatus.pending,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  /// Grava os planejamentos e metas sugeridos no onboarding.
  ///
  /// Os limites passam pelo `CategoryPlanningService` — o mesmo caminho das
  /// telas de planejamento —, então o documento nasce com a janela que o
  /// resto do app espera (`startMonth` = mês corrente, `endMonth` aberto) em
  /// vez do intervalo que a sugestão trouxe.
  ///
  /// O serviço é montado aqui com o id do workspace recém-criado: ele ainda
  /// não é o workspace corrente do app quando o onboarding chega neste passo.
  Future<void> savePlanning(
    WorkspaceModel workspace,
    PlanningSuggestions suggestions, {
    required DateTime today,
  }) async {
    final planningService = CategoryPlanningService(
      workspaceId: workspace.id,
      repository: financeRepository,
    );

    await planningService.setLimits(
      month: today.monthKey,
      limits: suggestions.plannings
          .map(
            (planning) =>
                (category: planning.category, amount: planning.amount),
          )
          .toList(),
    );

    await Future.wait(
      suggestions.goals.map(
        (goal) => goalRepository.addGoal(workspace.id, goal),
      ),
    );
  }
}
