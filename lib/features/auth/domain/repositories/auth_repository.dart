import 'package:funances/features/user/domain/models/user_model.dart';

abstract class IAuthRepository {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> signUpWithEmailAndPassword(String email, String password, String displayName);
  Future<void> signOut();
  UserModel? get currentUser;
}
