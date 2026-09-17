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

/// Sequências de semanas perfeitas do workspace.
///
/// O campo `weeklyStreaks` do documento tem DOIS formatos em produção: um
/// número (o histórico, escrito por `updateWorkspaceStreaks`) e um mapa
/// `{missions, plan}` (o placar novo). O app aceita os dois — um `as int`
/// direto derrubaria a Home de todo mundo no dia do deploy do backend, e o
/// contrário aconteceria se o app fosse atualizado primeiro.
@freezed
sealed class WorkspaceStreaks with _$WorkspaceStreaks {
  const factory WorkspaceStreaks({
    /// Semanas seguidas com as três missões concluídas.
    @Default(0) int missions,

    /// Semanas seguidas dentro do planejamento. Zero no formato antigo, que
    /// não contava isso.
    @Default(0) int plan,
  }) = _WorkspaceStreaks;

  factory WorkspaceStreaks.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceStreaksFromJson(json);
}

/// Lê `weeklyStreaks` nos dois formatos. Número vira [WorkspaceStreaks.missions]
/// — é o que ele sempre significou.
WorkspaceStreaks workspaceStreaksFromJson(Object? raw) {
  if (raw is num) return WorkspaceStreaks(missions: raw.toInt());

  if (raw is Map) {
    int read(String key) {
      final value = raw[key];
      return value is num ? value.toInt() : 0;
    }

    return WorkspaceStreaks(missions: read('missions'), plan: read('plan'));
  }

  return const WorkspaceStreaks();
}

/// Escreve `weeklyStreaks` como NÚMERO.
///
/// O cliente nunca é dono deste campo: ele só aparece no `toJson` porque a
/// criação do workspace grava o documento inteiro, e as rules exigem
/// `weeklyStreaks == 0` ali — um mapa seria negado. O servidor sobrescreve com
/// o formato dele no primeiro cálculo.
int workspaceStreaksToJson(WorkspaceStreaks streaks) => streaks.missions;

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
    @JsonKey(fromJson: workspaceStreaksFromJson, toJson: workspaceStreaksToJson)
    @Default(WorkspaceStreaks())
    WorkspaceStreaks weeklyStreaks,

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
