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
    String? avatar,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['displayName'] = displayName;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (avatar != null) data['avatar'] = avatar;

    if (data.isNotEmpty) {
      await _repository.updateUser(id, data);
    }
  }

  /// Grava SÓ o avatar.
  ///
  /// Existe separado do [updateProfile] por causa do onboarding: lá o
  /// documento do usuário já existe (o login o criou) e o que o passo tem em
  /// mãos é a escolha do boneco, mais nada. Mandar o resto do perfil junto
  /// significaria reescrever nome e foto com o que estivesse em memória.
  Future<void> updateAvatar({required String id, required String avatar}) {
    return _repository.updateUser(id, {'avatar': avatar});
  }
}
