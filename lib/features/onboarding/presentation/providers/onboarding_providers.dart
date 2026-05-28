import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../finance/domain/models/account_model.dart';
import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../finance/domain/models/order_model.dart';
import '../../../finance/domain/models/planning_model.dart';
import '../../domain/services/onboarding_service.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../data/services/onboarding_service_impl.dart';
import '../../data/repositories/firebase_ai_repository.dart';
import '../../../finance/presentation/providers/account_providers.dart';
import '../../../goal/presentation/providers/goal_providers.dart';
import '../../../workspace/presentation/providers/workspace_providers.dart';
import '../../../workspace/presentation/providers/invite_providers.dart';
import '../../../workspace/presentation/providers/category_providers.dart';

// Providers de Serviço
final aiRepositoryProvider = Provider<IAIRepository>((ref) {
  return FirebaseAIRepository();
});

final onboardingServiceProvider = Provider<IOnboardingService>((ref) {
  return OnboardingService(
    workspaceRepository: ref.watch(workspaceRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    goalRepository: ref.watch(goalRepositoryProvider),
    inviteRepository: ref.watch(inviteRepositoryProvider),
    aiRepository: ref.watch(aiRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    financeRepository: ref.watch(financeRepositoryProvider),
  );
});

class OnboardingState {
  final int currentStep;
  final int currentSubStep; // Para navegar dentro de passos complexos
  final WorkspaceType? workspaceType;
  final String workspaceName;
  final bool isSubmitting;
  final String createdWorkspaceId;
  final bool isFinalizing;
  final List<String> inviteEmails;
  final List<AccountModel> onboardingAccounts;
  final List<GoalModel> onboardingGoals;
  final List<OrderModel> onboardingOrders;
  final List<PlanningModel> onboardingPlannings;
  final bool isAnalyzing;
  final String? analysisError;

  OnboardingState({
    this.currentStep = 0,
    this.currentSubStep = 0,
    this.workspaceType,
    this.workspaceName = '',
    this.isSubmitting = false,
    this.createdWorkspaceId = '',
    this.isFinalizing = false,
    this.inviteEmails = const [],
    this.onboardingAccounts = const [],
    this.onboardingGoals = const [],
    this.onboardingOrders = const [],
    this.onboardingPlannings = const [],
    this.isAnalyzing = false,
    this.analysisError,
  });

  OnboardingState copyWith({
    int? currentStep,
    int? currentSubStep,
    WorkspaceType? workspaceType,
    String? workspaceName,
    bool? isSubmitting,
    String? createdWorkspaceId,
    bool? isFinalizing,
    List<String>? inviteEmails,
    List<AccountModel>? onboardingAccounts,
    List<GoalModel>? onboardingGoals,
    List<OrderModel>? onboardingOrders,
    List<PlanningModel>? onboardingPlannings,
    bool? isAnalyzing,
    String? analysisError,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      currentSubStep: currentSubStep ?? this.currentSubStep,
      workspaceType: workspaceType ?? this.workspaceType,
      workspaceName: workspaceName ?? this.workspaceName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdWorkspaceId: createdWorkspaceId ?? this.createdWorkspaceId,
      isFinalizing: isFinalizing ?? this.isFinalizing,
      inviteEmails: inviteEmails ?? this.inviteEmails,
      onboardingAccounts: onboardingAccounts ?? this.onboardingAccounts,
      onboardingGoals: onboardingGoals ?? this.onboardingGoals,
      onboardingOrders: onboardingOrders ?? this.onboardingOrders,
      onboardingPlannings: onboardingPlannings ?? this.onboardingPlannings,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysisError: analysisError ?? this.analysisError,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(OnboardingState());

  void reset() {
    state = OnboardingState();
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setWorkspaceType(WorkspaceType type) {
    state = state.copyWith(workspaceType: type, currentStep: 1);
  }

  void setWorkspaceName(String name) {
    state = state.copyWith(workspaceName: name);
  }

  void setSubStep(int subStep) {
    state = state.copyWith(currentSubStep: subStep);
  }

  Future<void> analyzeAccounts() async {
    if (state.onboardingAccounts.isEmpty) return;
    
    state = state.copyWith(isAnalyzing: true, analysisError: null);
    try {
      final suggestions = await _ref.read(onboardingServiceProvider).analyzeAccounts(
        workspaceType: state.workspaceType ?? WorkspaceType.personal,
        transactions: state.onboardingOrders,
      );
      
      state = state.copyWith(
        onboardingGoals: suggestions,
        isAnalyzing: false,
      );
      nextStep();
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        analysisError: e.toString(),
      );
    }
  }

  void addOnboardingAccount(AccountModel account) {
    state = state.copyWith(
      onboardingAccounts: [...state.onboardingAccounts, account],
    );
  }

  void removeOnboardingAccount(String accountId) {
    state = state.copyWith(
      onboardingAccounts: state.onboardingAccounts.where((a) => a.id != accountId).toList(),
    );
  }

  void setOnboardingGoals(List<GoalModel> goals) {
    state = state.copyWith(onboardingGoals: goals);
  }

  void addOnboardingOrders(List<OrderModel> orders) {
    state = state.copyWith(
      onboardingOrders: [...state.onboardingOrders, ...orders],
    );
  }

  void addOnboardingPlannings(List<PlanningModel> plannings) {
    state = state.copyWith(
      onboardingPlannings: [...state.onboardingPlannings, ...plannings],
    );
  }

  void toggleOnboardingGoal(GoalModel goal) {
    final exists = state.onboardingGoals.any((g) => g.id == goal.id);
    if (exists) {
      state = state.copyWith(
        onboardingGoals: state.onboardingGoals.where((g) => g.id != goal.id).toList(),
      );
    } else {
      state = state.copyWith(
        onboardingGoals: [...state.onboardingGoals, goal],
      );
    }
  }

  void addInviteEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return;
    if (state.inviteEmails.contains(email)) return;
    state = state.copyWith(inviteEmails: [...state.inviteEmails, email]);
  }

  void removeInviteEmail(String email) {
    state = state.copyWith(
      inviteEmails: state.inviteEmails.where((e) => e != email).toList(),
    );
  }

  Future<void> finalize() async {
    final user = _ref.read(authStateProvider).value;
    final workspaceId = state.createdWorkspaceId;

    if (user != null && workspaceId.isNotEmpty) {
      state = state.copyWith(isSubmitting: true);
      try {
        await _ref.read(onboardingServiceProvider).finalizeOnboarding(
          userId: user.id,
          workspaceId: workspaceId,
          accounts: state.onboardingAccounts,
          goals: state.onboardingGoals,
          inviteEmails: state.inviteEmails,
          orders: state.onboardingOrders,
          plannings: state.onboardingPlannings,
        );
      } catch (e) {
        // Handle error
      } finally {
        state = state.copyWith(isSubmitting: false);
      }
    }

    state = state.copyWith(isFinalizing: true);
  }

  Future<bool> createWorkspace() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null || state.workspaceType == null || state.workspaceName.isEmpty) {
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final createdWorkspace = await _ref.read(onboardingServiceProvider).createWorkspace(
        userId: user.id,
        name: state.workspaceName,
        type: state.workspaceType!,
      );
      
      // Recarregar workspaces no provider global
      await _ref.read(workspaceNotifierProvider.notifier).loadWorkspaces(user.id);
      
      state = state.copyWith(
        isSubmitting: false,
        createdWorkspaceId: createdWorkspace.id,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final onboardingNotifierProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});
