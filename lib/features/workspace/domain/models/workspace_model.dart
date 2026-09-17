import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'workspace_model.freezed.dart';

part 'workspace_model.g.dart';

enum WorkspaceType {
  @JsonValue('personal')
  personal,
  @JsonValue('business')
  business,
}

enum OnboardingSteps { type, name, accounts, planning, invites, success, done }

@freezed
sealed class WorkspaceModel with _$WorkspaceModel {
  const factory WorkspaceModel({
    required String id,
    required String name,
    required WorkspaceType type,
    @Default([]) List<String> members,
    required DateTime createdAt,
    OnboardingSteps? lastOnboardingStep,
    @Default(0) int xp,
    @Default(1) int level,
    DateTime? lastLevelUpAt,
    @Default({}) Map<String, String> unlockedBadges,
    @Default(false) bool onboardingCompleted,
    @Default(0) int weeklyStreaks,

    /// Semana corrente (`YYYY-Www`) segundo o SERVIDOR.
    ///
    /// A identidade da semana é uma só e mora no backend
    /// (`week_sync.service.ts`): o app lê daqui em vez de calcular, porque as
    /// duas aritméticas divergiam no sábado à noite e as missões da semana
    /// apareciam num id que o `weekly_xp` não usava. `null` numa base
    /// anterior ao F1.9 — aí o app cai no fallback de `JourneyService`.
    String? currentWeekId,
  }) = _WorkspaceModel;

  factory WorkspaceModel.empty() {
    return WorkspaceModel(
      id: Uuid().v4(),
      name: "",
      type: WorkspaceType.personal,
      createdAt: DateTime.now(),
    );
  }

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceModelFromJson(json);
}
