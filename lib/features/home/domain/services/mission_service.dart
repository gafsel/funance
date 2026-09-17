import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:rxdart/rxdart.dart';
import 'package:funances/core/money/money.dart';

/// O CHECKLIST da semana (parcelas pendentes, atrasadas e pagas) e a saúde da
/// Party por categoria.
///
/// F2.4: este serviço não é mais um segundo sistema de missões. Ele não conta
/// XP nem inventa alvo nenhum — quem define missão e XP é o servidor
/// (`weekly_missions`, `weekly_xp`), lido por `JourneyService`. O que sobrou
/// aqui é a leitura do que o usuário tem para fazer nesta semana.
class MissionService {
  final FinanceService financeService;
  final PeriodSummaryService summaryService;
  final CategoryService categoryService;

  /// Fonte do "hoje". Injetável para o cálculo da semana ser testável e para
  /// a virada do dia chegar aqui pelo `todayProvider`.
  final Clock now;

  MissionService({
    required this.financeService,
    required this.summaryService,
    required this.categoryService,
    Clock? now,
  }) : now = now ?? DateTime.now;

  /// O realizado respeitou o planejado da categoria?
  ///
  /// Era o ÚLTIMO ponto do checklist a comparar dinheiro em `double`, com uma
  /// tolerância de um centavo — contra todo o resto do app já migrado para
  /// centavos inteiros. A tolerância nunca descreveu regra nenhuma: era o
  /// medo do resto do ponto flutuante, e em [Money] a comparação é exata.
  ///
  /// Numa categoria de DESPESA, aderir é não passar do planejado; numa de
  /// RECEITA, é alcançá-lo.
  static bool isAdherentTo({
    required CategoryType type,
    required double actualAmount,
    required double plannedAmount,
  }) {
    final actual = actualAmount.asMoney;
    final planned = plannedAmount.asMoney;

    return type == CategoryType.expense ? actual <= planned : actual >= planned;
  }

  /// Semana corrente (domingo a sábado) que contém [reference].
  ///
  /// Os limites andam por calendário: somar `Duration(days: n)` são 24h
  /// absolutas e escorrega uma hora na semana em que o horário de verão entra
  /// ou sai, deixando de fora (ou incluindo a mais) os lançamentos da última
  /// hora do sábado.
  static ({DateTime start, DateTime end}) weekWindow(DateTime reference) {
    final start = ProductWeek.startOf(reference);

    return (
      start: start,
      // Véspera do início da semana seguinte.
      end: start.addCalendarDays(7).subtract(const Duration(milliseconds: 1)),
    );
  }

  Stream<MissionModel> watchMissions() {
    final now = this.now();
    final (start: startOfWeek, end: endOfWeek) = weekWindow(now);

    // Determinar semana e ano para o summary semanal
    final weekNumber = ProductWeek.numberOf(startOfWeek);
    final weekYear = ProductWeek.yearOf(startOfWeek);

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

      for (final MapEntry<String, PeriodSummaryCategoryModel> entry
          in weeklySummaries?.categories.entries ?? []) {
        final summary = entry.value;

        if (summary.generalPlannedAmount <= 0) continue;

        final progress = summary.actualAmount / summary.generalPlannedAmount;

        bool isAdherent = true;

        final category = categories
            .where((cat) => cat.id == entry.key)
            .firstOrNull;

        if (category != null) {
          isAdherent = isAdherentTo(
            type: category.type,
            actualAmount: summary.actualAmount,
            plannedAmount: summary.generalPlannedAmount,
          );

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
              hp: hp,
              status: status,
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
          .map((inst) => InstallmentMission(installment: inst))
          .toList();
      overdueMissions.sort(
        (a, b) =>
            a.installment.description.compareTo(b.installment.description),
      );

      // Processar Week Installments
      final pendingMissions = <InstallmentMission>[];
      final completedMissions = <InstallmentMission>[];

      for (final inst in weekInsts) {
        if (inst.status == InstallmentStatus.removed || inst.amount <= 0) {
          continue;
        }
        final isCompleted =
            inst.status == InstallmentStatus.settled ||
            inst.status == InstallmentStatus.paid;
        final mission = InstallmentMission(
          installment: inst,
          isAdherent: isCompleted,
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
          totalPlanned = Money.sumOf(
            expenseMissions,
            (m) => m.weeklyPlannedAmount,
          ).toDouble();
          totalActual = Money.sumOf(
            expenseMissions,
            (m) => m.weeklyActualAmount,
          ).toDouble();

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
}
