import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'goal_view_model.freezed.dart';

@freezed
sealed class GoalFormState with _$GoalFormState {
  const GoalFormState._();

  const factory GoalFormState({
    String? id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime startDate,
    required DateTime deadline,
    required GoalType type,
    CategoryModel? category,
    String? accountId,
  }) = _GoalFormState;

  factory GoalFormState.initial(GoalModel? goal) {
    return GoalFormState(
      id: goal?.id,
      name: goal?.name ?? '',
      targetAmount: goal?.targetAmount ?? 0.0,
      currentAmount: goal?.currentAmount ?? 0.0,
      startDate: goal?.startDate ?? DateTime.now(),
      deadline: goal?.deadline ?? DateTime.now().add(const Duration(days: 30)),
      type: goal?.type ?? GoalType.saveMoney,
      category: goal?.mapOrNull(reduceExpense: (goal) => goal.category),
      accountId: goal?.mapOrNull(
        saveMoney: (goal) => goal.accountId,
        reduceCreditCard: (goal) => goal.accountId,
        payDebt: (goal) => goal.accountId,
      ),
    );
  }

  bool get creation => id == null;

  GoalModel asGoalModel() {
    switch (type) {
      case GoalType.saveMoney:
        return GoalModel.saveMoney(
          id: id ?? "",
          name: name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          deadline: deadline,
          accountId: accountId!,
          startDate: startDate,
        );
      case GoalType.reduceExpense:
        return GoalModel.reduceExpense(
          id: id ?? "",
          name: name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          deadline: deadline,
          category: category!,
          startDate: startDate,
        );
      case GoalType.reduceCreditCard:
        return GoalModel.reduceCreditCard(
          id: id ?? "",
          name: name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          deadline: deadline,
          accountId: accountId!,
          startDate: startDate,
        );
      case GoalType.payDebt:
        return GoalModel.payDebt(
          id: id ?? "",
          name: name,
          targetAmount: targetAmount,
          currentAmount: currentAmount,
          deadline: deadline,
          accountId: accountId!,
          startDate: startDate,
        );
    }
  }
}
