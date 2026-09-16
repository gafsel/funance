import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';

class WorkspaceService {
  final IWorkspaceRepository _repository;

  WorkspaceService(this._repository);

  Future<List<UserModel>> getWorkspaceMembers(String workspaceId) {
    return _repository.getWorkspaceMembers(workspaceId);
  }

  Future<void> removeWorkspaceMember(String workspaceId, String memberId) {
    return _repository.removeWorkspaceMember(workspaceId, memberId);
  }
}
