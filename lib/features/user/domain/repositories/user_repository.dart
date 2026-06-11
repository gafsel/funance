import 'dart:io';
import '../models/user_model.dart';

abstract class IUserRepository {
  Stream<UserModel?> watchUser(String id);
  Future<UserModel?> getUserById(String id);
  Future<void> createUser(UserModel user);
  Future<void> updateUser(String id, Map<String, dynamic> data);
  Future<String> uploadUserAvatar(String userId, File file);
}
