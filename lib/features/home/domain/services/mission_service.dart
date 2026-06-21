import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:rxdart/rxdart.dart';

class MissionService {
  final FinanceService financeService;
  final PeriodSummaryService summaryService;
  final CategoryService categoryService;

  MissionService({
    required this.financeService,
    required this.summaryService,
    required this.categoryService,
  });

  Stream<MissionModel> watchMissions() {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );

    // Determinar semana e ano para o summary semanal
    final weekNumber = _getWeekNumber(startOfWeek);
    final weekYear = _getWeekYear(startOfWeek);

    final weeklySummariesStream = summaryService.watchWeek(
      weekYear,
      weekNumber,
    );
    final categories = categoryService.getCategories();

    // Streams de installments
    final overdueStream = financeService.watchInstallments(
      limit: 100,
      endDate: startOfWeek.subtract(const Duration(seconds: 1)),
      status: InstallmentStatus.pending,
    );

    final currentWeekInstallmentsStream = financeService.watchInstallments(
      limit: 100,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );

    return CombineLatestStream.combine4<
      PeriodSummaryModel?,
      List<InstallmentModel>,
      List<InstallmentModel>,
      List<CategoryModel>,
      MissionModel
    >(weeklySummariesStream, overdueStream, currentWeekInstallmentsStream, categories, (
      weeklySummaries,
      overdueInsts,
      weekInsts,
      categories,
    ) {
      // Processar Plannings
      final planningMissions = <PlanningMission>[];

      const planningXpValue = 0.0;
      for (final MapEntry<String, PeriodSummaryCategoryModel> entry
          in weeklySummaries?.categories.entries ?? []) {
        final summary = entry.value;

        if (summary.generalPlannedAmount <= 0) continue;

        final progress = summary.actualAmount / summary.generalPlannedAmount;

        bool isAdherent = true;
        const double earnedXp = 0;

        final category = categories
            .where((cat) => cat.id == entry.key)
            .firstOrNull;

        if (category != null) {
          if (category.type == CategoryType.expense) {
            if (summary.actualAmount > (summary.generalPlannedAmount + 0.01)) {
              isAdherent = false;
            }
          } else {
            if (summary.actualAmount < (summary.generalPlannedAmount - 0.01)) {
              isAdherent = false;
            }
          }

          // Lógica de HP e Status do Desafio
          double hp = 1.0;
          ChallengeStatus status = ChallengeStatus.stable;

          if (category.type == CategoryType.expense) {
            hp = 1.0 - (progress > 1 ? 1 : progress);

            // Proporção da semana decorrida (0.0 a 1.0)
            final dayOfWeek = now.weekday % 7; // 0 (Dom) a 6 (Sab)
            // Se hoje é domingo (início da semana), consideramos um pequeno progresso para evitar divisão por zero ou alertas imediatos
            final weekElapsedRatio = (dayOfWeek + 1) / 7.0;

            if (progress > 1.0) {
              status = ChallengeStatus.critical;
              hp = 0.0;
            } else if (progress > weekElapsedRatio + 0.1) {
              // Gastou significativamente mais do que o proporcional ao tempo da semana
              status = ChallengeStatus.warning;
            } else {
              status = ChallengeStatus.stable;
            }
          } else if (category.type == CategoryType.income) {
            // Para receitas, HP é o progresso em direção à meta
            hp = progress > 1 ? 1 : progress;

            final dayOfWeek = now.weekday % 7;
            final weekElapsedRatio = (dayOfWeek + 1) / 7.0;

            if (progress >= 1.0) {
              status = ChallengeStatus.stable;
            } else if (progress < weekElapsedRatio - 0.2) {
              // Receita está muito abaixo do esperado para o ponto da semana
              status = ChallengeStatus.warning;
            } else {
              status = ChallengeStatus.stable;
            }
          }

          planningMissions.add(
            PlanningMission(
              category: category,
              summary: summary,
              weeklyPlannedAmount: summary.generalPlannedAmount,
              weeklyActualAmount: summary.actualAmount,
              progress: progress,
              isAdherent: isAdherent,
              earnedXp: earnedXp,
              hp: hp,
              status: status,
              xpValue: planningXpValue,
            ),
          );
        }
      }
      planningMissions.sort(
        (a, b) => a.category.name.compareTo(b.category.name),
      );

      // Processar Overdue
      final overdueMissions = overdueInsts
          .where(
            (inst) =>
                inst.status != InstallmentStatus.removed && inst.amount > 0,
          )
          .map(
            (inst) => InstallmentMission(
              installment: inst,
              xpValue: inst.xp?.toDouble() ?? 5.0,
              isAdherent: false,
              earnedXp: 0,
            ),
          )
          .toList();
      overdueMissions.sort(
        (a, b) =>
            a.installment.description.compareTo(b.installment.description),
      );

      // Processar Week Installments
      final pendingMissions = <InstallmentMission>[];
      final completedMissions = <InstallmentMission>[];

      for (final inst in weekInsts) {
        if (inst.status == InstallmentStatus.removed || inst.amount <= 0)
          continue;
        final isCompleted =
            inst.status == InstallmentStatus.settled ||
            inst.status == InstallmentStatus.paid;
        final mission = InstallmentMission(
          installment: inst,
          xpValue: inst.xp?.toDouble() ?? 15.0,
          isAdherent: isCompleted,
          earnedXp: isCompleted
              ? (inst.xp?.toDouble() ?? inst.xp?.toDouble() ?? 15.0)
              : 0,
        );
        if (isCompleted) {
          completedMissions.add(mission);
        } else {
          pendingMissions.add(mission);
        }
      }
      pendingMissions.sort(
        (a, b) =>
            a.installment.description.compareTo(b.installment.description),
      );
      completedMissions.sort(
        (a, b) =>
            a.installment.description.compareTo(b.installment.description),
      );

      // Novo cálculo de XP: baseado em installments e plannings (planejado vs realizado)
      final totalXp = [
        ...overdueMissions.map((m) => m.xpValue),
        ...pendingMissions.map((m) => m.xpValue),
        ...completedMissions.map((m) => m.xpValue),
        ...planningMissions.map((m) => m.xpValue),
      ].fold<double>(0, (sum, val) => sum + val);

      final currentXp = [
        ...overdueMissions.map((m) => m.earnedXp),
        ...pendingMissions.map((m) => m.earnedXp),
        ...completedMissions.map((m) => m.earnedXp),
        ...planningMissions.map((m) => m.earnedXp),
      ].fold<double>(0, (sum, val) => sum + val);

      // Calcular Status da Party
      double partyHp = 1.0;
      PartyStatus partyStatus = PartyStatus.healthy;
      double totalPlanned = 0;
      double totalActual = 0;

      if (planningMissions.isNotEmpty) {
        // Novo cálculo: Baseado no total de despesas da semana
        final expenseMissions = planningMissions
            .where((m) => m.category.type == CategoryType.expense)
            .toList();

        if (expenseMissions.isNotEmpty) {
          totalPlanned = expenseMissions.fold<double>(
            0,
            (sum, m) => sum + m.weeklyPlannedAmount,
          );
          totalActual = expenseMissions.fold<double>(
            0,
            (sum, m) => sum + m.weeklyActualAmount,
          );

          final totalProgress = totalPlanned > 0
              ? totalActual / totalPlanned
              : 0.0;
          partyHp = 1.0 - (totalProgress > 1 ? 1 : totalProgress);

          final dayOfWeek = now.weekday % 7;
          final weekElapsedRatio = (dayOfWeek + 1) / 7.0;

          if (totalProgress > 1.0) {
            partyStatus = PartyStatus.defeated;
            partyHp = 0.0;
          } else if (totalProgress > weekElapsedRatio + 0.1) {
            partyStatus = PartyStatus.strained;
          } else {
            partyStatus = PartyStatus.healthy;
          }

          // Mas se qualquer categoria individual estiver crítica (HP 0), a party já fica pelo menos strained
          final hasCritical = planningMissions.any(
            (m) => m.status == ChallengeStatus.critical,
          );
          if (hasCritical && partyStatus == PartyStatus.healthy) {
            partyStatus = PartyStatus.strained;
          }
        }
      }

      return MissionModel(
        pendingInstallments: pendingMissions,
        completedInstallments: completedMissions,
        overdueInstallments: overdueMissions,
        planningMissions: planningMissions,
        totalXp: totalXp,
        currentXp: currentXp,
        startDate: startOfWeek,
        endDate: endOfWeek,
        partyHp: partyHp,
        partyStatus: partyStatus,
        totalPlannedAmount: totalPlanned,
        totalActualAmount: totalActual,
      );
    });
  }

  Future<MissionModel> getFullMissionModel() async {
    return watchMissions().first;
  }

  // Métodos auxiliares de data (iguais aos do TS) para garantir consistência
  int _getWeekNumber(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    // Ajusta para o domingo mais próximo (início da semana)
    final sunday = date.subtract(Duration(days: date.weekday % 7));
    final firstDayOfYear = DateTime(sunday.year, 1, 1);
    final days = sunday.difference(firstDayOfYear).inDays;
    return (days / 7).floor() + 1;
  }

  int _getWeekYear(DateTime d) {
    final date = DateTime(d.year, d.month, d.day);
    // Ajusta para o domingo mais próximo
    final sunday = date.subtract(Duration(days: date.weekday % 7));
    return sunday.year;
  }
}
