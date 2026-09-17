import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/core/money/money.dart';

class Planning503020Service {
  final CategoryPlanningService planningService;
  final CategoryService categoryService;
  final PeriodSummaryService periodSummaryService;

  Planning503020Service({
    required this.planningService,
    required this.categoryService,
    required this.periodSummaryService,
  });

  Stream<({List<CategoryPlanning503020Item> items, double totalIncomes, double totalActualIncomes})> watchPlanningItems(DateTime date) {
    final currentMonth = date.monthKey;

    return periodSummaryService.watchMonth(date.year, date.month).asyncMap((summary) async {
      final categories = await categoryService.getCategories().first;
      // As pools do 50-30-20 são editáveis: só entram categorias que o
      // usuário pode de fato planejar.
      final expenseCategories = categories
          .where((c) => c.type == CategoryType.expense && c.isSelectable)
          .toList();
      
      final plannings = await planningService.plannings(month: currentMonth);

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
      
      // A renda é o denominador de todas as fatias do 50-30-20: um centavo de
      // resto aqui vira meio ponto percentual na tela.
      final totalIncomes = Money.sumOf(
        incomes,
        (category) =>
            summary?.categories[category.id]?.specificPlannedAmount ?? 0.0,
      );

      final totalActualIncomes = Money.sumOf(
        incomes,
        (category) => summary?.categories[category.id]?.actualAmount ?? 0.0,
      );

      return (
        items: items,
        totalIncomes: totalIncomes.toDouble(),
        totalActualIncomes: totalActualIncomes.toDouble(),
      );
    });
  }

  Stream<Planning503020Distribution> watchDistribution(DateTime date) {
    return watchPlanningItems(date).map((data) {
      var plannedEssential = Money.zero;
      var actualEssential = Money.zero;
      var plannedComfort = Money.zero;
      var actualComfort = Money.zero;
      var plannedInvestment = Money.zero;
      var actualInvestment = Money.zero;

      for (final item in data.items) {
        final planned = item.effectiveAmount.asMoney;
        final actual = item.actualAmount.asMoney;

        switch (item.category.allocation) {
          case CategoryAllocation.essential:
            plannedEssential += planned;
            actualEssential += actual;
          case CategoryAllocation.comfort:
            plannedComfort += planned;
            actualComfort += actual;
          case CategoryAllocation.investment:
            plannedInvestment += planned;
            actualInvestment += actual;
        }
      }

      return Planning503020Distribution(
        totalIncome: data.totalIncomes,
        totalActualIncome: data.totalActualIncomes,
        essential: Planning503020DistributionGroup(
          plannedAmount: plannedEssential.toDouble(),
          actualAmount: actualEssential.toDouble(),
          idealPercentage: 0.5,
        ),
        comfort: Planning503020DistributionGroup(
          plannedAmount: plannedComfort.toDouble(),
          actualAmount: actualComfort.toDouble(),
          idealPercentage: 0.3,
        ),
        investment: Planning503020DistributionGroup(
          plannedAmount: plannedInvestment.toDouble(),
          actualAmount: actualInvestment.toDouble(),
          idealPercentage: 0.2,
        ),
      );
    });
  }

  /// Grava as pools e os limites editados.
  ///
  /// A pool (`allocation`) é um atributo da categoria; o limite vai pelo
  /// `CategoryPlanningService`, que é o mesmo caminho da tela simples
  /// `/planning` — editar a mesma categoria nas duas telas produz o mesmo
  /// documento.
  Future<void> savePlanning(
    List<CategoryPlanning503020Item> items,
    DateTime date,
  ) async {
    final dirty = items.where((item) => item.isDirty).toList();
    if (dirty.isEmpty) return;

    final categories = await categoryService.getCategories().first;

    for (final item in dirty) {
      final originalCategory = categories
          .where((c) => c.id == item.category.id)
          .firstOrNull;

      if (originalCategory != null &&
          originalCategory.allocation != item.category.allocation) {
        await categoryService.update(item.category);
      }
    }

    await planningService.setLimits(
      month: date.monthKey,
      limits: dirty
          .map((item) => (category: item.category, amount: item.generalAmount))
          .toList(),
    );
  }
}
