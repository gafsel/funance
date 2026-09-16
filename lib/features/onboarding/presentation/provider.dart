import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:funances/features/onboarding/domain/services/onboarding_service.dart';
import 'package:funances/features/onboarding/presentation/controller/onboarding_notifier.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class OnboardingDomainProviders {
  static final repository = Provider((ref) => OnboardingRepositoryImpl());

  static final service = Provider(
    (ref) => OnboardingService(
      user: ref.watch(AuthDomainProviders.user).value!,
      accountRepository: ref.read(AccountDomainProviders.repository),
      categoryRepository: ref.read(CategoryDomainProviders.repository),
      financeRepository: ref.read(FinanceDomainProviders.repository),
      authRepository: ref.read(AuthDomainProviders.repository),
      onboardingRepository: ref.read(repository),
      workspaceRepository: ref.read(WorkspaceDomainProviders.repository),
      inviteRepository: ref.read(inviteRepositoryProvider),
      goalRepository: ref.read(GoalDomainProvider.repository),
    ),
  );
}

class OnboardingViewProviders {
  static final onboarding = StateNotifierProvider.autoDispose((ref) {
    return OnboardingNotifier(
      onboardingService: ref.read(OnboardingDomainProviders.service),
      accountRepository: ref.read(AccountDomainProviders.repository),
      workspaceNotifier: ref.read(WorkspaceViewProviders.workspace.notifier),
      categoryService: ref.read(CategoryDomainProviders.service),
      analytics: ref.read(analyticsServiceProvider),
      today: ref.watch(todayProvider),
    );
  });
}
