import '../models/workspace_model.dart';

abstract class IWorkspaceRepository {
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid);
  Future<WorkspaceModel> createWorkspace(WorkspaceModel workspace);
  Future<WorkspaceModel?> getWorkspace(String id);
  Future<void> updateWorkspace(WorkspaceModel workspace);
  Future<void> deleteWorkspace(String workspaceId);
}
