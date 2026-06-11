import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/user/presentation/controller/user_profile_notifier.dart';
import 'package:funances/features/user/presentation/model/user_view_models.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/services/user_service.dart';

sealed class UserDomainProviders {
  static final repository = Provider<IUserRepository>((ref) {
    return UserRepositoryImpl();
  });

  static final service = Provider<UserService>((ref) {
    final repository = ref.watch(UserDomainProviders.repository);
    return UserService(repository);
  });
}

sealed class UserViewProviders {
  static final profileForm = StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileFormState>((ref) {
    final userService = ref.watch(UserDomainProviders.service);
    return UserProfileNotifier(userService: userService);
  });
}
