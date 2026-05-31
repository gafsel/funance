import 'package:funances/features/auth/domain/repositories/auth_repository.dart';
import 'package:funances/features/user/domain/models/user_model.dart';

class AuthService {
  final IAuthRepository repository;

  AuthService({required this.repository});

  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    return await repository.signUpWithEmailAndPassword(
      email,
      password,
      displayName,
    );
  }

  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }

  Future<UserModel> signInWithGoogle() async {
    return await repository.signInWithGoogle();
  }

  Stream<UserModel?> get authStateChanges => repository.authStateChanges;

  Future<void> signOut() async => await repository.signOut();
}
