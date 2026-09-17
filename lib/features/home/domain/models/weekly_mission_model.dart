import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_mission_model.freezed.dart';

/// Tipo da missão semanal, como o servidor a nomeia em
/// `gamification.service.ts` (`createWeeklyMission`).
///
/// Um tipo que o app não conhece (missão nova publicada por um servidor mais
/// novo) cai em [unknown] e continua aparecendo na lista com o nome que o
/// servidor mandou — some do agrupamento, não da tela.
enum WeeklyMissionType {
  consistency,
  discipline,
  organization,
  unknown;

  static WeeklyMissionType parse(Object? raw) {
    return switch (raw) {
      'consistency' => consistency,
      'discipline' => discipline,
      'organization' => organization,
      _ => unknown,
    };
  }
}

/// Estado da missão semanal.
///
/// O servidor grava `pending` ao criar e ao atualizar o progresso, e
/// `completed` quando a missão fecha (ver `completeMissionAndAwardXp`). O
/// contrato do produto também prevê `active` e `failed`; os quatro são aceitos
/// aqui para o app não precisar de deploy quando o servidor passar a usá-los.
/// Qualquer outro valor vira [unknown] e é tratado como em andamento.
enum WeeklyMissionStatus {
  pending,
  active,
  completed,
  failed,
  unknown;

  static WeeklyMissionStatus parse(Object? raw) {
    return switch (raw) {
      'pending' => pending,
      'active' => active,
      'completed' => completed,
      'failed' => failed,
      _ => unknown,
    };
  }

  bool get isCompleted => this == completed;

  bool get isFailed => this == failed;
}

/// Uma missão semanal do servidor (`workspaces/{w}/weekly_missions/{weekId}_{type}`).
///
/// O app NÃO calcula missão: o cliente tinha uma segunda lista de "missões",
/// inventada a partir das parcelas da semana, com XP fabricado que nunca
/// coincidia com o XP que o servidor de fato concedia. Este modelo é a leitura
/// da única fonte que existe.
@freezed
sealed class WeeklyMissionModel with _$WeeklyMissionModel {
  const WeeklyMissionModel._();

  const factory WeeklyMissionModel({
    required String id,
    required String name,
    required WeeklyMissionType type,
    required WeeklyMissionStatus status,
    required String weekId,

    /// Alvo da missão (3 categorias planejadas, 5 dias no limite, ...).
    @Default(0) int target,
    @Default(0) int progress,

    /// XP que a missão paga. O servidor chama o campo de `rewardXp`; o
    /// contrato do produto fala em `xp`. O mapper aceita os dois.
    @Default(0) int xp,
  }) = _WeeklyMissionModel;

  /// Progresso de 0 a 1. Sem alvo declarado não há barra para desenhar:
  /// devolve 1 quando a missão está concluída e 0 no resto, em vez de
  /// dividir por zero.
  double get completion {
    if (target <= 0) return status.isCompleted ? 1 : 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  /// Missão concluída conta o alvo cheio: o servidor grava o progresso com o
  /// valor que fechou a missão, que pode ser maior que o alvo.
  int get displayProgress => status.isCompleted ? target : progress;
}
