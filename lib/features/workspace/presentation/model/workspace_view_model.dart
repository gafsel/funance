
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

part 'workspace_view_model.freezed.dart';


@freezed
sealed class WorkspaceState with _$WorkspaceState {
  const factory WorkspaceState({
    WorkspaceModel? currentWorkspace,
    @Default([]) List<WorkspaceModel> availableWorkspaces,
    @Default(false) bool isLoading,
    @Default(false) bool initialLoadDone,
  }) = _WorkspaceState;
}
