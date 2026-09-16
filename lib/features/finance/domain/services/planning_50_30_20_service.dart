import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';

class Planning503020Service {
  final FinanceService financeService;
  final CategoryService categoryService;
  final PeriodSummaryService periodSummaryService;

  Planning503020Service({
    required this.financeService,
    required this.categoryService,
    required this.periodSummaryService,
  });

  Stream<({List<CategoryPlanning503020Item> items, double totalIncomes, double totalActualIncomes})> watchPlanningItems(DateTime date) {
    final currentMonth = date.formated("yyyy-MM");

    return periodSummaryService.watchMonth(date.year, date.month).asyncMap((summary) async {
      final categories = await categoryService.getCategories().first;
      // As pools do 50-30-20 são editáveis: só entram categorias que o
      // usuário pode de fato planejar.
      final expenseCategories = categories
          .where((c) => c.type == CategoryType.expense && c.isSelectable)
          .toList();
      
      final plannings = await financeService.getCategoryPlannings(startMonth: currentMonth);

      final items = expenseCategories.map((category) {
        final planning = plannings.where((p) => p.category.id == category.id).firstOrNull;
        final summaryCategory = summary?.categories[category.id];
        
        return CategoryPlanning503020Item(
          category: category,
          generalAmount: planning?.amount ?? 0.0,
          specificAmount: summaryCategory?.specificPlannedAmount ?? 0.0,
          actualAmount: summaryCategory?.actualAmount ?? 0.0,
          planningId: planning?.id,
        );
      }).toList();

      final incomes = categories.where(
        (c) => c.type == CategoryType.income && c.isSelectable,
      );
      
      final totalIncomes = incomes.fold<double>(0, (sum, category) {
        final summaryCategory = summary?.categories[category.id];
        return sum + (summaryCategory?.specificPlannedAmount ?? 0.0);
      });

      final totalActualIncomes = incomes.fold<double>(0, (sum, category) {
        final summaryCategory = summary?.categories[category.id];
        return sum + (summaryCategory?.actualAmount ?? 0.0);
      });

      return (items: items, totalIncomes: totalIncomes, totalActualIncomes: totalActualIncomes);
    });
  }

  Stream<Planning503020Distribution> watchDistribution(DateTime date) {
    return watchPlanningItems(date).map((data) {
      double plannedEssential = 0;
      double actualEssential = 0;
      double plannedComfort = 0;
      double actualComfort = 0;
      double plannedInvestment = 0;
      double actualInvestment = 0;

      for (final item in data.items) {
        final planned = item.effectiveAmount;
        final actual = item.actualAmount;

        switch (item.category.allocation) {
          case CategoryAllocation.essential:
            plannedEssential += planned;
            actualEssential += actual;
            break;
          case CategoryAllocation.comfort:
            plannedComfort += planned;
            actualComfort += actual;
            break;
          case CategoryAllocation.investment:
            plannedInvestment += planned;
            actualInvestment += actual;
            break;
        }
      }

      return Planning503020Distribution(
        totalIncome: data.totalIncomes,
        totalActualIncome: data.totalActualIncomes,
        essential: Planning503020DistributionGroup(
          plannedAmount: plannedEssential,
          actualAmount: actualEssential,
          idealPercentage: 0.5,
        ),
        comfort: Planning503020DistributionGroup(
          plannedAmount: plannedComfort,
          actualAmount: actualComfort,
          idealPercentage: 0.3,
        ),
        investment: Planning503020DistributionGroup(
          plannedAmount: plannedInvestment,
          actualAmount: actualInvestment,
          idealPercentage: 0.2,
        ),
      );
    });
  }

  Future<void> savePlanning(List<CategoryPlanning503020Item> items, DateTime date) async {
    final currentMonth = date.formated("yyyy-MM");
    final endMonth = date.add(const Duration(days: 365 * 99)).formated("yyyy-MM");

    // Note: For previousMonth, we want the month before 'date'.
    // date.subtract(const Duration(days: 30)) might not be reliable for all months.
    final prevDate = DateTime(date.year, date.month - 1);
    final prevMonthStr = prevDate.formated("yyyy-MM");

    for (final item in items) {
      if (!item.isDirty) continue;

      // Update category allocation if changed
      final categories = await categoryService.getCategories().first;
      final originalCategory = categories.firstWhere((c) => c.id == item.category.id);
      
      if (originalCategory.allocation != item.category.allocation) {
        await categoryService.update(item.category);
      }

      // Update planning
      if (item.planningId == null && item.generalAmount > 0) {
        await financeService.addCategoryPlanning(
          CategoryPlanningModel(
            id: const Uuid().v4(),
            category: item.category,
            amount: item.generalAmount,
            startMonth: currentMonth,
            endMonth: endMonth,
          ),
        );
      } else if (item.planningId != null) {
        final plannings = await financeService.getCategoryPlannings(startMonth: currentMonth);
        final existingPlanning = plannings.firstWhere((p) => p.id == item.planningId);

        if (item.generalAmount <= 0) {
          await financeService.updateCategoryPlanning(
            existingPlanning.copyWith(endMonth: prevMonthStr),
          );
        } else if (existingPlanning.amount != item.generalAmount) {
          await financeService.updateCategoryPlanning(
            existingPlanning.copyWith(amount: item.generalAmount),
          );
        }
      }
    }
  }
}
