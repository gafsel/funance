import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/onboarding/domain/models/onboarding_models.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

part 'onboarding_view_models.freezed.dart';


@freezed
sealed class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  const factory OnboardingState({
    @Default(OnboardingSteps.type) OnboardingSteps currentStep,
    required WorkspaceModel workspace,
    @Default([]) List<String> inviteEmails,
    @Default([]) List<AccountModel> accounts,
    PlanningSuggestions? planningSuggestions,
  }) = _OnboardingState;
}
