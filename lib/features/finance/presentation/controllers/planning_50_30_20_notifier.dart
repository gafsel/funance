import 'dart:async';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/services/planning_50_30_20_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class Planning503020Notifier extends FormNotifier<CategoryPlanning503020State, void> {
  final Planning503020Service planning503020Service;

  StreamSubscription? _subscription;

  Planning503020Notifier({
    required this.planning503020Service,
  }) : super(CategoryPlanning503020State(isLoading: true)) {
    _init();
  }

  void _init() {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    
    _subscription?.cancel();
    _subscription = planning503020Service.watchPlanningItems(now).listen((data) {
      state = state.copyWith(items: data.items, totalIncomes: data.totalIncomes, isLoading: false);
    });
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
      await planning503020Service.savePlanning(state.items);
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
