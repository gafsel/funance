import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class MissionService {
  final FinanceService financeService;
  final PeriodSummaryService summaryService;

  MissionService({
    required this.financeService,
    required this.summaryService,
  });

  Stream<MissionModel> watchMissions() async* {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    // Buscando installments atrasados (antes da semana atual, não removidos e pendentes)
    final overdueInstallmentsChunk = await financeService.queryInstallments(
      limit: 1000,
      endDate: startOfWeek.subtract(const Duration(seconds: 1)),
      status: InstallmentStatus.pending,
    );

    // Buscando installments da semana
    final installmentsChunk = await financeService.queryInstallments(
      limit: 1000,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );

    final summariesStream = summaryService.watchMonth(now.year, now.month);

    await for (final summaries in summariesStream) {
      final pendingInstallments = <InstallmentMission>[];
      final completedInstallments = <InstallmentMission>[];
      final overdueInstallments = <InstallmentMission>[];
      final planningMissions = <PlanningMission>[];
      
      double currentXp = 0;
      double totalXp = 0;

      // Processar atrasados
      for (final inst in overdueInstallmentsChunk.items) {
        if (inst.status == InstallmentStatus.removed) continue;
        
        // XP menor para atrasados (5XP em vez de 15XP)
        const xpValue = 5.0;
        final isCompleted = inst.status == InstallmentStatus.settled || inst.status == InstallmentStatus.paid;
        
        overdueInstallments.add(InstallmentMission(
          installment: inst, 
          xpValue: xpValue,
          isAdherent: isCompleted,
          earnedXp: isCompleted ? xpValue : 0,
        ));
        totalXp += xpValue;
        // Se por algum motivo já estivesse pago (não deveria pelo filtro), somaria ao currentXp
        if (isCompleted) {
          currentXp += xpValue;
        }
      }

      // Processar installments da semana
      for (final inst in installmentsChunk.items) {
        if (inst.status == InstallmentStatus.removed) continue;

        double xpValue = 15.0;
        double earnedXp = 0;
        final isCompleted = inst.status == InstallmentStatus.settled || inst.status == InstallmentStatus.paid;

        if (isCompleted) {
          final diff = (inst.paidAmount ?? 0) - inst.amount;
          if (diff != 0) {
            bool isPositive = false;
            if (inst.type == OrderType.income) {
              isPositive = diff > 0;
            } else if (inst.type == OrderType.expense) {
              isPositive = diff < 0;
            }
            
            if (isPositive) {
              xpValue += 1.5;
            } else {
              xpValue -= 1.5;
            }
          }
          earnedXp = xpValue;
          completedInstallments.add(InstallmentMission(
            installment: inst, 
            xpValue: xpValue,
            isAdherent: true,
            earnedXp: earnedXp,
          ));
        } else {
          pendingInstallments.add(InstallmentMission(
            installment: inst, 
            xpValue: xpValue,
            isAdherent: false,
            earnedXp: 0,
          ));
        }

        totalXp += xpValue;
        currentXp += earnedXp;
      }

      // Plannings
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      const daysInWeek = 7;

      for (final summary in summaries) {
        if (summary.generalPlannedAmount > 0) {
          final dailyLimit = summary.generalPlannedAmount / daysInMonth;
          final weeklyLimit = dailyLimit * daysInWeek;
          
          final weeklySpent = installmentsChunk.items
              .where((inst) => inst.category?.id == summary.category.id && 
                               (inst.status == InstallmentStatus.settled || inst.status == InstallmentStatus.paid))
              .fold(0.0, (sum, inst) => sum + (inst.paidAmount ?? inst.amount));

          const xpValue = 10.0;
          double earnedXp = 0;
          
          final progress = weeklyLimit > 0 ? weeklySpent / weeklyLimit : 0.0;
          
          bool isAdherent = true;
          if (summary.category.type == CategoryType.expense) {
            if (weeklySpent > (weeklyLimit + 0.01)) isAdherent = false;
          } else {
            if (weeklySpent < (weeklyLimit - 0.01)) isAdherent = false;
          }

          if (isAdherent) {
            earnedXp = (progress > 1 ? 1 : progress) * xpValue;
          } else {
            if (summary.category.type == CategoryType.expense) {
              // Punição proporcional para despesas que ultrapassam o limite
              final excess = weeklySpent - weeklyLimit;
              final excessRatio = weeklyLimit > 0 ? excess / weeklyLimit : 0.0;
              earnedXp = -(excessRatio * xpValue);
            } else {
              // Para ganhos, se não atingiu a meta, ganha 0 XP (sem punição negativa por enquanto)
              earnedXp = 0;
            }
          }

          planningMissions.add(PlanningMission(
            summary: summary,
            weeklyPlannedAmount: weeklyLimit,
            weeklyActualAmount: weeklySpent,
            xpValue: xpValue,
            progress: progress,
            isAdherent: isAdherent,
            earnedXp: earnedXp,
          ));

          totalXp += xpValue;
          currentXp += earnedXp;
        }
      }

      // Ordenar alfabeticamente
      overdueInstallments.sort((a, b) => a.installment.description.compareTo(b.installment.description));
      pendingInstallments.sort((a, b) => a.installment.description.compareTo(b.installment.description));
      completedInstallments.sort((a, b) => a.installment.description.compareTo(b.installment.description));
      planningMissions.sort((a, b) => a.summary.category.name.compareTo(b.summary.category.name));

      yield MissionModel(
        pendingInstallments: pendingInstallments,
        completedInstallments: completedInstallments,
        overdueInstallments: overdueInstallments,
        planningMissions: planningMissions,
        totalXp: totalXp,
        currentXp: currentXp,
        startDate: startOfWeek,
        endDate: endOfWeek,
      );
    }
  }
}
