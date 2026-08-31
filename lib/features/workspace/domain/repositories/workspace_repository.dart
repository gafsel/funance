import 'package:funances/features/user/domain/models/user_model.dart';

import '../models/workspace_model.dart';

abstract class IWorkspaceRepository {
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid);
  Future<WorkspaceModel> createWorkspace(WorkspaceModel workspace);
  Future<WorkspaceModel?> getWorkspace(String id);
  Stream<WorkspaceModel?> watchWorkspace(String id);
  Future<void> updateWorkspace(WorkspaceModel workspace);
  Future<void> deleteWorkspace(String workspaceId);
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId);
}
