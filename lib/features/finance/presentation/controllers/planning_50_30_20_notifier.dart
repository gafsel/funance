import 'dart:async';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class Planning503020Notifier extends FormNotifier<CategoryPlanning503020State, void> {
  final Planning503020Service planning503020Service;

  // Só usamos a assinatura para cancelar, então o tipo do elemento é irrelevante.
  StreamSubscription<void>? _subscription;

  Planning503020Notifier({
    required this.planning503020Service,
  }) : super(CategoryPlanning503020State(isLoading: true, date: DateTime(DateTime.now().year, DateTime.now().month))) {
    _init();
  }

  void _init() {
    state = state.copyWith(isLoading: true);
    
    _subscription?.cancel();
    _subscription = planning503020Service.watchPlanningItems(state.date).listen((data) {
      state = state.copyWith(
        items: data.items,
        totalIncomes: data.totalIncomes,
        totalActualIncomes: data.totalActualIncomes,
        isLoading: false,
      );
    });
  }

  void previousMonth() {
    _changeMonth(DateTime(state.date.year, state.date.month - 1));
  }

  void nextMonth() {
    _changeMonth(DateTime(state.date.year, state.date.month + 1));
  }

  void _changeMonth(DateTime newDate) {
    if (state.date.year == newDate.year && state.date.month == newDate.month) return;
    state = state.copyWith(date: newDate);
    _init();
  }

  void updateAmount(String categoryId, double amount) {
    final newItems = state.items.map((item) {
      if (item.category.id == categoryId) {
        return item.copyWith(generalAmount: amount, isDirty: true);
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void moveCategory(String categoryId, CategoryAllocation newAllocation) {
    final newItems = state.items.map((item) {
      if (item.category.id == categoryId) {
        return item.copyWith(
          category: item.category.copyWith(allocation: newAllocation),
          isDirty: true,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  @override
  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await planning503020Service.savePlanning(state.items, state.date);
      _init();
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
