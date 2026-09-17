import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/exceptions/business_exception.dart';
import 'package:funances/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:funances/features/auth/domain/services/auth_service.dart';
import 'package:funances/features/auth/presentation/controller/login_form_notifier.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/user/presentation/providers/user_providers.dart';

class AuthDomainProviders {
  static final repository = Provider(
    (ref) => AuthRepositoryImpl(ref.read(UserDomainProviders.repository)),
  );

  static final service = Provider(
    (ref) => AuthService(repository: ref.read(repository)),
  );

  static final user = StreamProvider<UserModel?>((ref) {
    return ref.read(service).authStateChanges;
  });

  static final currentUser = Provider<UserModel?>((ref) {
    return ref.watch(user).value;
  });

  /// Erro que voltou junto com o redirect do Google, para a tela de login
  /// mostrar assim que ela reaparecer.
  static final redirectError = StreamProvider<ErrorCode>((ref) {
    return ref.read(service).redirectErrors;
  });
}

class AuthViewProviders {
  static final form = StateNotifierProvider.autoDispose(
    (ref) => LoginFormNotifier(service: ref.read(AuthDomainProviders.service)),
  );
}
