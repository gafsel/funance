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
/// A sequência mora em DOIS campos do documento, porque o backend escreve os
/// dois: `weeklyStreaks` como NÚMERO (o histórico, que `updateWorkspaceStreaks`
/// sempre gravou) e `streaks` como MAPA `{missions, plan}` (o placar novo, e o
/// único lugar onde a sequência de planejamento existe).
///
/// O app lê os dois e continua aceitando `weeklyStreaks` em formato de mapa,
/// que é como uma versão anterior do cliente o escrevia. Um `as int` direto
/// derrubaria a Home de todo mundo no dia do deploy do backend, e ler só o
/// mapa quebraria o app antes desse deploy.
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

/// Junta o campo de topo `streaks` com o `weeklyStreaks` antes da desserialização.
///
/// O `streaks` manda no que ele souber dizer: é o campo que o backend mantém
/// e o único que conhece a sequência de planejamento. O que faltar nele vem do
/// `weeklyStreaks`, que numa base anterior ao placar novo é tudo o que existe.
Map<String, dynamic> mergeWorkspaceStreaks(Map<String, dynamic> json) {
  final Object? top = json['streaks'];
  if (top is! Map) return json;

  final WorkspaceStreaks legacy = workspaceStreaksFromJson(
    json['weeklyStreaks'],
  );

  int pick(String key, int fallback) {
    final Object? value = top[key];
    return value is num ? value.toInt() : fallback;
  }

  return <String, dynamic>{
    ...json,
    'weeklyStreaks': <String, dynamic>{
      'missions': pick('missions', legacy.missions),
      'plan': pick('plan', legacy.plan),
    },
  };
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
///
/// O `streaks` não sai no `toJson` por isso mesmo: ele é campo do servidor, e
/// o app que o escrevesse na criação só conseguiria zerar o que o backend
/// acabou de calcular.
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
      _$WorkspaceModelFromJson(mergeWorkspaceStreaks(json));
}
