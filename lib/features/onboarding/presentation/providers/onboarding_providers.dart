import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../../workspace/presentation/providers/workspace_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class OnboardingState {
  final int currentStep;
  final WorkspaceType? workspaceType;
  final String workspaceName;
  final bool isSubmitting;
  final String createdWorkspaceId;

  OnboardingState({
    this.currentStep = 0,
    this.workspaceType,
    this.workspaceName = '',
    this.isSubmitting = false,
    this.createdWorkspaceId = '',
  });

  OnboardingState copyWith({
    int? currentStep,
    WorkspaceType? workspaceType,
    String? workspaceName,
    bool? isSubmitting,
    String? createdWorkspaceId,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      workspaceType: workspaceType ?? this.workspaceType,
      workspaceName: workspaceName ?? this.workspaceName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createdWorkspaceId: createdWorkspaceId ?? this.createdWorkspaceId,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(OnboardingState());

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

  Future<bool> createWorkspace() async {
    final user = _ref.read(authStateProvider).value;
    if (user == null || state.workspaceType == null || state.workspaceName.isEmpty) {
      return false;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final workspace = WorkspaceModel(
        id: const Uuid().v4(),
        name: state.workspaceName,
        type: state.workspaceType!,
        members: [user.id],
        createdAt: DateTime.now(),
      );

      final repository = _ref.read(workspaceRepositoryProvider);
      final createdWorkspace = await repository.createWorkspace(workspace);
      
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
