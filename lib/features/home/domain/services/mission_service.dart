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

    final weeklyXpStream = financeService.watchWeeklyXp(weekYear, weekNumber);
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

    return CombineLatestStream.combine5<
      double,
      PeriodSummaryModel?,
      List<InstallmentModel>,
      List<InstallmentModel>,
      List<CategoryModel>,
      MissionModel
    >(
      weeklyXpStream,
      weeklySummariesStream,
      overdueStream,
      currentWeekInstallmentsStream,
      categories,
      (currentXp, weeklySummaries, overdueInsts, weekInsts, categories) {
        // Processar Plannings
        final planningMissions = <PlanningMission>[];
        double planningsTotalXp = 0;

        const xpValue = 10.0;
        for (final MapEntry<String, PeriodSummaryCategoryModel> entry
            in weeklySummaries?.categories.entries ?? []) {
          final summary = entry.value;
          planningsTotalXp += xpValue;

          if (summary.generalPlannedAmount <= 0) continue;

          final progress = summary.actualAmount / summary.generalPlannedAmount;

          bool isAdherent = true;
          double earnedXp = 0;

          final category = categories.firstWhere(
            (cat) => cat.id == entry.key,
            orElse: () => CategoryModel(
              id: entry.key,
              name: 'Unknown',
              icon: 'help',
              color: '0xFF000000',
            ),
          );

          if (category.type == CategoryType.expense) {
            if (summary.actualAmount > (summary.generalPlannedAmount + 0.01)) {
              isAdherent = false;
              final excess =
                  summary.actualAmount - summary.generalPlannedAmount;
              final excessRatio = summary.generalPlannedAmount > 0
                  ? excess / summary.generalPlannedAmount
                  : 0.0;
              earnedXp = -(excessRatio * xpValue);
            } else {
              earnedXp = (progress > 1 ? 1 : progress) * xpValue;
            }
          } else {
            if (summary.actualAmount < (summary.generalPlannedAmount - 0.01)) {
              isAdherent = false;
            }

            earnedXp = isAdherent ? (progress > 1 ? 1 : progress) * xpValue : 0;
          }

          planningMissions.add(
            PlanningMission(
              category: category,
              summary: summary,
              weeklyPlannedAmount: summary.generalPlannedAmount,
              weeklyActualAmount: summary.actualAmount,
              xpValue: xpValue,
              progress: progress,
              isAdherent: isAdherent,
              earnedXp: earnedXp,
            ),
          );
        }
        planningMissions.sort(
          (a, b) => a.category.name.compareTo(b.category.name),
        );

        // Processar Overdue
        final overdueMissions = overdueInsts
            .where((inst) => inst.status != InstallmentStatus.removed)
            .map(
              (inst) => InstallmentMission(
                installment: inst,
                xpValue: 5.0,
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
          if (inst.status == InstallmentStatus.removed) continue;
          final isCompleted =
              inst.status == InstallmentStatus.settled ||
              inst.status == InstallmentStatus.paid;
          final mission = InstallmentMission(
            installment: inst,
            xpValue: 15.0,
            isAdherent: isCompleted,
            earnedXp: inst.xp ?? 0,
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

        final totalInstallmentsXp =
            (pendingMissions.length + completedMissions.length) * 15.0;
        final totalOverdueXp = overdueMissions.length * 5.0;

        return MissionModel(
          pendingInstallments: pendingMissions,
          completedInstallments: completedMissions,
          overdueInstallments: overdueMissions,
          planningMissions: planningMissions,
          totalXp: planningsTotalXp + totalInstallmentsXp + totalOverdueXp,
          currentXp: currentXp,
          startDate: startOfWeek,
          endDate: endOfWeek,
        );
      },
    );
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
