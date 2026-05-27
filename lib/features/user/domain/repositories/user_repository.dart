import '../models/user_model.dart';

abstract class IUserRepository {
  Future<UserModel?> getUserById(String id);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(String id, Map<String, dynamic> data);
}
