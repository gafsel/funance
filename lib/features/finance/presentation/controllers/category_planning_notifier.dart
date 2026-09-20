import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';

class CategoryPlanningNotifier
    extends FormNotifier<CategoryPlanningState, void> {
  final CategoryPlanningService planningService;
  final CategoryService categoryService;
  final CategoryType type;
  final AnalyticsService analytics;

  /// Mês a que os limites desta tela se referem.
  ///
  /// Vem de fora (do relógio injetado) em vez de `DateTime.now()` no corpo do
  /// notifier: a tela vive aberta e a leitura e a gravação precisam ser o
  /// mesmo mês, inclusive na virada.
  final String month;

  /// Categoria que o usuário veio definir, quando chegou por um atalho (o
  /// nudge de gasto não planejado). Sobe para o topo da lista e nasce
  /// destacada.
  final String? highlightCategoryId;

  /// Valor já preenchido para [highlightCategoryId]. Vem sugerido, não
  /// gravado: o usuário ainda precisa salvar, e pode trocar o número antes.
  final double? suggestedAmount;

  CategoryPlanningNotifier({
    required this.planningService,
    required this.categoryService,
    required this.analytics,
    required this.type,
    required DateTime date,
    this.highlightCategoryId,
    this.suggestedAmount,
  }) : month = date.monthKey,
       super(CategoryPlanningState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await categoryService.getCategories().first;
      final filteredCategories = categories.where((c) {
        // Não faz sentido planejar categoria de sistema ou já excluída.
        return type == c.type && c.isSelectable;
      }).toList();

      final plannings = await planningService.plannings(month: month);

      final items = filteredCategories.map((category) {
        final planning = plannings
            .where((p) => p.category.id == category.id)
            .firstOrNull;

        final isHighlighted = category.id == highlightCategoryId;
        final current = planning?.amount ?? 0.0;

        // A sugestão só entra numa categoria que ainda NÃO tem limite: se o
        // usuário já definiu um, sobrescrevê-lo com uma média seria desfazer
        // a decisão dele sem perguntar.
        final amount = isHighlighted && current <= 0
            ? (suggestedAmount ?? 0.0)
            : current;

        return CategoryPlanningFormItem(
          category: category,
          amount: amount,
          planningId: planning?.id,
          isDirty: amount != current,
        );
      }).toList();

      // A categoria que trouxe o usuário até aqui vem primeiro: numa lista de
      // trinta, procurar a sua desfaz o convite que o trouxe.
      if (highlightCategoryId != null) {
        items.sort((a, b) {
          final aFirst = a.category.id == highlightCategoryId ? 0 : 1;
          final bFirst = b.category.id == highlightCategoryId ? 0 : 1;
          return aFirst.compareTo(bFirst);
        });
      }

      state = state.copyWith(
        items: items,
        isLoading: false,
        highlightCategoryId: highlightCategoryId,
      );
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
    final changed = await planningService.setLimits(
      month: month,
      limits: state.items
          .where((item) => item.isDirty)
          .map((item) => (category: item.category, amount: item.amount))
          .toList(),
    );

    if (changed) {
      // Analytics não pode derrubar o salvamento do planejamento.
      try {
        await analytics.logPlanningCreated();
      } catch (_) {}
    }

    await _init(); // Recarregar estado
  }
}
