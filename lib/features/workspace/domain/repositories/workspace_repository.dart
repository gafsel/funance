import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

import '../models/workspace_model.dart';

abstract class IWorkspaceRepository {
  Future<List<WorkspaceModel>> getUserWorkspaces(String userUid);
  Future<Written<WorkspaceModel>> createWorkspace(WorkspaceModel workspace);
  Future<WorkspaceModel?> getWorkspace(String id);
  Stream<WorkspaceModel?> watchWorkspace(String id);
  Future<WriteOutcome> updateWorkspace(WorkspaceModel workspace);
  Future<void> deleteWorkspace(String workspaceId);
  Future<List<UserModel>> getWorkspaceMembers(String workspaceId);

  /// Tira um membro do workspace.
  ///
  /// Vai por callable: `members` é a base de toda permissão do workspace e as
  /// rules não deixam o cliente escrever nessa lista.
  Future<void> removeWorkspaceMember(String workspaceId, String memberId);
}
