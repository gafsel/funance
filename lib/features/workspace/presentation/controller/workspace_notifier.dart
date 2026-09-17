import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/core/observability/app_logger.dart';

import '../../domain/models/workspace_model.dart';
import '../../domain/repositories/workspace_repository.dart';

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final IWorkspaceRepository _repository;
  StreamSubscription<WorkspaceModel?>? _workspaceSubscription;

  WorkspaceNotifier(this._repository) : super(WorkspaceState());

  void setCurrentWorkspace(WorkspaceModel workspace) {
    state = state.copyWith(currentWorkspace: workspace);
    AppLogger.info(
      'Contexto alterado para: ${workspace.name} (${workspace.id})',
      name: 'workspace',
    );
    _watchCurrentWorkspace(workspace.id);
  }

  /// Mantém o workspace corrente sincronizado em tempo real com o Firestore,
  /// para que XP, nível, badges e streaks concedidos pelo servidor apareçam
  /// imediatamente na UI.
  void _watchCurrentWorkspace(String workspaceId) {
    _workspaceSubscription?.cancel();
    _workspaceSubscription = _repository
        .watchWorkspace(workspaceId)
        .listen(
          (workspace) {
            if (workspace == null) return;
            if (state.currentWorkspace?.id != workspace.id) return;
            state = state.copyWith(
              currentWorkspace: workspace,
              availableWorkspaces: [
                for (final w in state.availableWorkspaces)
                  w.id == workspace.id ? workspace : w,
              ],
            );
          },
          onError: (Object e, StackTrace s) {
            AppLogger.error('Erro ao observar workspace $workspaceId', e, s);
          },
        );
  }

  void reset() {
    _workspaceSubscription?.cancel();
    _workspaceSubscription = null;
    state = WorkspaceState();
  }

  Future<void> loadWorkspaces(
    String userUid, [
    String? workspaceIdToSelect,
    bool background = false,
  ]) async {
    state = state.copyWith(isLoading: !background);

    try {
      AppLogger.debug(
        'Carregando workspaces para o usuário: $userUid',
        name: 'workspace',
      );
      final workspaces = await _repository.getUserWorkspaces(userUid);

      final current =
          workspaces
              .where(
                (w) =>
                    w.id == (workspaceIdToSelect ?? state.currentWorkspace?.id),
              )
              .firstOrNull ??
          state.currentWorkspace ??
          workspaces.firstOrNull;

      state = state.copyWith(
        availableWorkspaces: workspaces,
        currentWorkspace: current,
        isLoading: false,
        initialLoadDone: true,
      );

      if (current != null) {
        _watchCurrentWorkspace(current.id);
      }
    } catch (e, s) {
      AppLogger.error('Erro ao carregar workspaces', e, s);
      state = state.copyWith(isLoading: false, initialLoadDone: true);
    }
  }

  @override
  void dispose() {
    _workspaceSubscription?.cancel();
    super.dispose();
  }
}
