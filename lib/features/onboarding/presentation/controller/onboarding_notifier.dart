import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/onboarding/presentation/model/onboarding_view_models.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';

import '../../../finance/domain/models/account_model.dart';
import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../domain/services/onboarding_service.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingService onboardingService;
  final IAccountRepository accountRepository;
  final WorkspaceNotifier workspaceNotifier;

  OnboardingNotifier({
    required this.onboardingService,
    required this.accountRepository,
    required this.workspaceNotifier,
  }) : super(OnboardingState(workspace: WorkspaceModel.empty()));

  void reset() {
    state = OnboardingState(workspace: WorkspaceModel.empty());
  }

  Future<void> nextStep() async {
    if (state.currentStep != OnboardingSteps.done) {
      var nextStep = OnboardingSteps.values[state.currentStep.index + 1];

      if (nextStep == OnboardingSteps.planning) {
        if (state.accounts.isNotEmpty) {
          await _analyzePlanning();
        } else {
          nextStep = OnboardingSteps.invites;
        }
      } else if (nextStep == OnboardingSteps.done) {
        await _finalize();
      } else if (nextStep == OnboardingSteps.accounts) {
        await _createWorkspace();
      }

      state = state.copyWith(currentStep: nextStep);
    }
  }

  void previousStep() {
    if (state.currentStep != OnboardingSteps.type) {
      state = state.copyWith(
        currentStep: OnboardingSteps.values[state.currentStep.index - 1],
      );
    }
  }

  void setWorkspaceType(WorkspaceType type) {
    state = state.copyWith(workspace: state.workspace.copyWith(type: type));

    nextStep();
  }

  void setWorkspaceName(String name) {
    state = state.copyWith(workspace: state.workspace.copyWith(name: name));
  }

  Future<void> _analyzePlanning() async {
    final suggestions = await onboardingService.analysePlanning(
      workspaceId: state.workspace.id,
    );

    state = state.copyWith(planningSuggestions: suggestions);
  }

  Future<void> addOnboardingAccount(AccountModel account) async {
    state = state.copyWith(accounts: [...state.accounts, account]);
  }

  Future<void> removeOnboardingAccount(String accountId) async {
    await accountRepository.deleteAccount(state.workspace.id, accountId);

    state = state.copyWith(
      accounts: state.accounts.where((a) => a.id != accountId).toList(),
    );
  }

  Future<void> removeGoal(GoalModel goal) async {
    state = state.copyWith(
      planningSuggestions: state.planningSuggestions?.copyWith(
        goals:
            state.planningSuggestions?.goals.where((g) => g != goal).toList() ??
            [],
      ),
    );
  }

  void addInviteEmail(String email) {
    if (state.inviteEmails.contains(email)) return;

    state = state.copyWith(inviteEmails: [...state.inviteEmails, email]);
  }

  void removeInviteEmail(String email) {
    state = state.copyWith(
      inviteEmails: state.inviteEmails.where((e) => e != email).toList(),
    );
  }

  Future<void> _finalize() async {
    onboardingService.savePlanning(
      state.workspace,
      state.planningSuggestions ?? PlanningSuggestions(),
    );

    workspaceNotifier.loadWorkspaces(onboardingService.user.id);
  }

  Future<void> _createWorkspace() async {
    await onboardingService.createWorkspace(
      name: state.workspace.name,
      type: state.workspace.type,
    );
  }
}
