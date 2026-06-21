import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:logger/logger.dart';

import '../../domain/models/workspace_model.dart';
import '../../domain/repositories/workspace_repository.dart';

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

  Future<void> loadWorkspaces(
    String userUid, [
    String? workspaceIdToSelect,
    bool background = false,
  ]) async {
    state = state.copyWith(isLoading: !background);

    try {
      _logger.d("Carregando workspaces para o usuário: $userUid");
      final workspaces = await _repository.getUserWorkspaces(userUid);

      state = state.copyWith(
        availableWorkspaces: workspaces,
        currentWorkspace:
            workspaces
                .where(
                  (w) =>
                      w.id ==
                      (workspaceIdToSelect ?? state.currentWorkspace?.id),
                )
                .firstOrNull ??
            state.currentWorkspace ??
            workspaces.first,
        isLoading: false,
        initialLoadDone: true,
      );
    } catch (e) {
      _logger.e("Erro ao carregar workspaces: $e");
      state = state.copyWith(isLoading: false, initialLoadDone: true);
    }
  }
}
