import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/models/workspace_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

part 'workspace_providers.freezed.dart';

final workspaceRepositoryProvider = Provider<IWorkspaceRepository>((ref) {
  return WorkspaceRepositoryImpl();
});

@freezed
sealed class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    WorkspaceModel? currentWorkspace,
    @Default([]) List<WorkspaceModel> availableWorkspaces,
    @Default(false) bool isLoading,
    @Default(false) bool initialLoadDone,
  }) = _WorkspaceState;
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final IWorkspaceRepository _repository;
  final Logger _logger = Logger();

  WorkspaceNotifier(this._repository) : super(WorkspaceState());

  void setCurrentWorkspace(WorkspaceModel workspace) {
    state = state.copyWith(currentWorkspace: workspace);
    _logger.i("Contexto alterado para: ${workspace.name} (${workspace.id})");
  }

  void reset() {
    state = WorkspaceState();
  }

  Future<void> loadWorkspaces(String userUid) async {
    state = state.copyWith(isLoading: true);

    try {
      _logger.d("Carregando workspaces para o usuário: $userUid");
      final workspaces = await _repository.getUserWorkspaces(userUid);
      
      state = state.copyWith(
        availableWorkspaces: workspaces,
        currentWorkspace: workspaces.isNotEmpty && state.currentWorkspace == null 
            ? workspaces.first 
            : state.currentWorkspace,
        isLoading: false,
        initialLoadDone: true,
      );
    } catch (e) {
      _logger.e("Erro ao carregar workspaces: $e");
      state = state.copyWith(isLoading: false, initialLoadDone: true);
    }
  }
}

final workspaceNotifierProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  final repository = ref.watch(workspaceRepositoryProvider);
  final notifier = WorkspaceNotifier(repository);
  
  // Reagir a mudanças de autenticação para carregar workspaces
  ref.listen(authStateProvider, (previous, next) {
    next.when(
      data: (user) {
        if (user != null) {
          notifier.loadWorkspaces(user.id);
        } else {
          notifier.reset();
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  });

  return notifier;
});
