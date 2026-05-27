import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../../user/domain/models/user_model.dart';

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthRepositoryImpl(userRepository);
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final IAuthRepository _repository;
  final Logger _logger = Logger();

  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmailAndPassword(email, password);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword(
      String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final user =
          await _repository.signUpWithEmailAndPassword(email, password, displayName);
      state = AsyncValue.data(user);
      return user != null;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      _logger.e("Erro ao sair: $e");
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
