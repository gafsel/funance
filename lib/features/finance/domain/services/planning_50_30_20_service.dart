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

  Stream<({List<CategoryPlanning503020Item> items, double totalIncomes})> watchPlanningItems(DateTime date) {
    final currentMonth = date.formated("yyyy-MM");

    return periodSummaryService.watchMonth(date.year, date.month).asyncMap((summary) async {
      final categories = await categoryService.getCategories().first;
      final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
      
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

      final totalIncomes = categories
          .where((c) => c.type == CategoryType.income)
          .fold<double>(0, (sum, category) {
        final summaryCategory = summary?.categories[category.id];
        return sum + (summaryCategory?.specificPlannedAmount ?? 0.0);
      });

      return (items: items, totalIncomes: totalIncomes);
    });
  }

  Future<void> savePlanning(List<CategoryPlanning503020Item> items) async {
    final now = DateTime.now();
    final currentMonth = now.formated("yyyy-MM");
    final endMonth = now.add(const Duration(days: 365 * 99)).formated("yyyy-MM");
    final previousMonth = now.subtract(const Duration(days: 30)).formated("yyyy-MM");

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
            existingPlanning.copyWith(endMonth: previousMonth),
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
