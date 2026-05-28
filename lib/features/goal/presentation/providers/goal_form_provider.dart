import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
import 'package:uuid/uuid.dart';

class GoalFormState {
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double averageSpending;
  final DateTime startDate;
  final DateTime deadline;
  final GoalType type;
  final String? selectedCategory;
  final String? selectedAccountId;
  final bool isLoading;

  GoalFormState({
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.averageSpending,
    required this.startDate,
    required this.deadline,
    required this.type,
    this.selectedCategory,
    this.selectedAccountId,
    this.isLoading = false,
  });

  factory GoalFormState.initial(GoalModel? goal) {
    return GoalFormState(
      name: goal?.name ?? '',
      targetAmount: goal?.targetAmount ?? 0.0,
      currentAmount: goal?.currentAmount ?? 0.0,
      averageSpending: goal?.metadata?['averageSpending'] ?? 0.0,
      startDate: goal?.startDate ?? DateTime.now(),
      deadline: goal?.deadline ?? DateTime.now().add(const Duration(days: 30)),
      type: goal?.type ?? GoalType.saveMoney,
      selectedCategory: goal?.metadata?['category'],
      selectedAccountId: goal?.accountId,
    );
  }

  GoalFormState copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    double? averageSpending,
    DateTime? startDate,
    DateTime? deadline,
    GoalType? type,
    String? selectedCategory,
    String? selectedAccountId,
    bool? isLoading,
  }) {
    return GoalFormState(
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      averageSpending: averageSpending ?? this.averageSpending,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      type: type ?? this.type,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GoalFormNotifier extends StateNotifier<GoalFormState> {
  final GoalModel? initialGoal;
  final Ref ref;

  GoalFormNotifier(this.ref, this.initialGoal)
      : super(GoalFormState.initial(initialGoal));

  void updateName(String value) => state = state.copyWith(name: value);
  void updateTargetAmount(double value) => state = state.copyWith(targetAmount: value);
  void updateCurrentAmount(double value) => state = state.copyWith(currentAmount: value);
  void updateAverageSpending(double value) => state = state.copyWith(averageSpending: value);
  void updateStartDate(DateTime value) => state = state.copyWith(startDate: value);
  void updateDeadline(DateTime value) => state = state.copyWith(deadline: value);
  void updateType(GoalType value) => state = state.copyWith(type: value);
  void updateCategory(String? value) => state = state.copyWith(selectedCategory: value);
  void updateAccountId(String? value) {
    state = state.copyWith(selectedAccountId: value);
    if (value != null) {
      ref.read(latestAccountBalanceProvider(value).stream).first.then((balance) {
        if (state.type == GoalType.reduceCreditCard) {
          updateCurrentAmount(balance.balance.abs());
        } else if (state.type == GoalType.payDebt) {
          // Se for uma conta de dívida, o saldo inicial (targetAmount) é a dívida total
          // e o currentAmount é o quanto já foi amortizado.
          // Geralmente o saldo da conta de dívida no app será negativo e irá para zero.
          // Mas para a meta, queremos saber o quanto falta.
          // Se targetAmount é 1000 e saldo é -800, então pagou 200.
          final paid = state.targetAmount + balance.balance; // Ex: 1000 + (-800) = 200
          updateCurrentAmount(paid > 0 ? paid : 0);
        } else {
          updateCurrentAmount(balance.balance);
        }
      });
    }
  }

  Future<bool> submit() async {
    state = state.copyWith(isLoading: true);
    
    final metadata = <String, dynamic>{};
    if (state.type == GoalType.reduceExpense) {
      metadata['category'] = state.selectedCategory;
      metadata['averageSpending'] = state.averageSpending;
    } else if (state.type == GoalType.reduceCreditCard) {
      metadata['averageSpending'] = state.averageSpending;
    }

    final goal = GoalModel(
      id: initialGoal?.id ?? const Uuid().v4(),
      name: state.name,
      targetAmount: state.targetAmount,
      currentAmount: state.currentAmount,
      startDate: state.startDate,
      deadline: state.deadline,
      type: state.type,
      accountId: state.selectedAccountId,
      metadata: metadata.isEmpty ? null : metadata,
    );

    try {
      if (initialGoal == null) {
        await ref.read(goalsProvider.notifier).addGoal(goal);
      } else {
        await ref.read(goalsProvider.notifier).updateGoal(goal);
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final goalFormProvider = StateNotifierProvider.family<GoalFormNotifier, GoalFormState, GoalModel?>((ref, goal) {
  return GoalFormNotifier(ref, goal);
});
