import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/finance/domain/repositories/planning_repository.dart';
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
  final IPlanningRepository planningRepository;
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
    required this.planningRepository,
    required this.goalRepository,
  });

  Future<PlanningSuggestions> analysePlanning({
    required String workspaceId,
  }) async {
    return onboardingRepository.analysePlanning(workspaceId: workspaceId);
  }

  Future<WorkspaceModel> createWorkspace({
    required String name,
    required WorkspaceType type,
    required OnboardingSteps lastOnboardingStep,
  }) async {
    final workspace = WorkspaceModel(
      id: const Uuid().v4(),
      name: name,
      type: type,
      createdAt: DateTime.now(),
      lastOnboardingStep: lastOnboardingStep,
    );

    return await workspaceRepository.createWorkspace(workspace);
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

  Future<void> savePlanning(
    WorkspaceModel workspace,
    PlanningSuggestions suggestions,
  ) async {
    await Future.wait([
      ...suggestions.plannings.map(
        (planning) => planningRepository.addPlanning(workspace.id, planning),
      ),
      ...suggestions.goals.map(
        (goal) => goalRepository.addGoal(workspace.id, goal),
      ),
    ]);
  }
}
