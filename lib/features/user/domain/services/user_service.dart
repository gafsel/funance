import 'package:funances/core/files/picked_document.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/domain/repositories/user_repository.dart';

class UserService {
  final IUserRepository _repository;

  UserService(this._repository);

  Future<UserModel?> getUser(String id) async {
    return await _repository.getUserById(id);
  }

  Future<String> uploadAvatar(String userId, PickedDocument image) async {
    return await _repository.uploadUserAvatar(userId, image);
  }

  Future<void> updateProfile({
    required String id,
    String? displayName,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    if (data.isNotEmpty) {
      await _repository.updateUser(id, data);
    }
  }
}
