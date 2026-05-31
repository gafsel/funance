import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';

class CategoryPlanningNotifier extends FormNotifier<CategoryPlanningState, void> {
  final FinanceService financeService;
  final CategoryService categoryService;
  final CategoryType type;

  CategoryPlanningNotifier({
    required this.financeService,
    required this.categoryService,
    required this.type,
  }) : super(CategoryPlanningState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await categoryService.getCategories().first;
      final filteredCategories = categories.where((c) {
        return type == c.type;
      }).toList();

      final currentMonth = DateTime.now().formated("yyyy-MM");
      final plannings = await financeService.getCategoryPlannings(startMonth: currentMonth);

      final items = filteredCategories.map((category) {
        final planning = plannings.where((p) => p.category.id == category.id).firstOrNull;
        return CategoryPlanningFormItem(
          category: category,
          amount: planning?.amount ?? 0.0,
          planningId: planning?.id,
        );
      }).toList();

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void updateAmount(String categoryId, double amount) {
    final newItems = state.items.map((item) {
      if (item.category.id == categoryId) {
        return item.copyWith(amount: amount, isDirty: true);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  @override
  Future<void> submit() async {
    final currentMonth = DateTime.now().formated("yyyy-MM");
    final endMonth = DateTime.now().add(const Duration(days: 365 * 99)).formated("yyyy-MM");
    final previousMonth = DateTime.now().subtract(const Duration(days: 30)).formated("yyyy-MM");

    for (final item in state.items) {
      if (!item.isDirty) continue;

      if (item.planningId == null && item.amount > 0) {
        // Novo planejamento
        await financeService.addCategoryPlanning(
          CategoryPlanningModel(
            id: const Uuid().v4(),
            category: item.category,
            amount: item.amount,
            startMonth: currentMonth,
            endMonth: endMonth,
          ),
        );
      } else if (item.planningId != null) {
        if (item.amount <= 0) {
          // "Remover" planejamento
          final existingPlanning = (await financeService.getCategoryPlannings(startMonth: currentMonth))
              .firstWhere((p) => p.id == item.planningId);
          
          await financeService.updateCategoryPlanning(
            existingPlanning.copyWith(endMonth: previousMonth),
          );
        } else {
          // Atualizar valor
          final existingPlanning = (await financeService.getCategoryPlannings(startMonth: currentMonth))
              .firstWhere((p) => p.id == item.planningId);

          await financeService.updateCategoryPlanning(
            existingPlanning.copyWith(amount: item.amount),
          );
        }
      }
    }
    await _init(); // Recarregar estado
  }
}
