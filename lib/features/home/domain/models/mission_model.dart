import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'mission_model.freezed.dart';

/// O CHECKLIST da semana: o que está pendente, o que atrasou e o que já foi
/// pago, mais a saúde da Party por categoria.
///
/// NÃO é o sistema de missões. As missões são as do servidor
/// (`weekly_missions`), e o XP da semana é o `weekly_xp` — os dois entram na
/// tela por `JourneyViewProviders`. Este modelo não tem mais `totalXp`,
/// `currentXp` nem `earnedXp`: eram valores inventados no cliente (15 XP por
/// parcela paga, 5 por atrasada) que nunca bateram com o XP que o servidor de
/// fato concedeu, e a barra de progresso da semana mostrava uma porcentagem
/// que não existia em lugar nenhum.
@freezed
sealed class MissionModel with _$MissionModel {
  const factory MissionModel({
    required List<InstallmentMission> pendingInstallments,
    required List<InstallmentMission> completedInstallments,
    required List<InstallmentMission> overdueInstallments,
    required List<PlanningMission> planningMissions,
    required DateTime startDate,
    required DateTime endDate,
    @Default(PartyStatus.healthy) PartyStatus partyStatus,
    @Default(1.0) double partyHp,
    @Default(0.0) double totalPlannedAmount,
    @Default(0.0) double totalActualAmount,
  }) = _MissionModel;

  const MissionModel._();

  /// Quantos itens do checklist já estão resolvidos.
  int get completedCount => completedInstallments.length;

  /// Tamanho do checklist da semana.
  int get totalCount =>
      pendingInstallments.length +
      overdueInstallments.length +
      completedInstallments.length;
}

/// Um item do checklist. O XP, quando existe, é o da PRÓPRIA parcela
/// (`installment.xp`, escrito pelo servidor) — o cliente não arbitra XP.
@freezed
sealed class InstallmentMission with _$InstallmentMission {
  const factory InstallmentMission({
    required InstallmentModel installment,
    @Default(false) bool isAdherent,
  }) = _InstallmentMission;
}

@freezed
sealed class PlanningMission with _$PlanningMission {
  const factory PlanningMission({
    required CategoryModel category,
    required PeriodSummaryCategoryModel summary,
    required double weeklyPlannedAmount,
    required double weeklyActualAmount,
    required double progress,
    required bool isAdherent,
    @Default(1.0) double hp,
    @Default(ChallengeStatus.stable) ChallengeStatus status,
  }) = _PlanningMission;
}

enum ChallengeStatus {
  stable, // Verde, feliz
  warning, // Amarelo, preocupado
  critical, // Vermelho, morto
}

enum PartyStatus {
  healthy, // Todos bem
  strained, // Alguns em perigo
  defeated, // Muitos mortos
}
