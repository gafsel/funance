import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class GoalFormNotifier extends FormNotifier<GoalFormState, void> {
  final GoalService goalService;
  final AccountService accountService;

  GoalFormNotifier({
    required this.goalService,
    required this.accountService,
    GoalModel? initialGoal,
  }) : super(GoalFormState.initial(initialGoal));

  void updateName(String value) => state = state.copyWith(name: value);

  void updateTargetAmount(double value) =>
      state = state.copyWith(targetAmount: value);

  void updateCurrentAmount(double value) =>
      state = state.copyWith(currentAmount: value);

  void updateAverageSpending(double value) =>
      state = state.copyWith(averageSpending: value);

  void updateStartDate(DateTime value) =>
      state = state.copyWith(startDate: value);

  void updateDeadline(DateTime value) =>
      state = state.copyWith(deadline: value);

  void updateType(GoalType value) => state = state.copyWith(type: value);

  void updateCategory(CategoryModel? value) =>
      state = state.copyWith(category: value);

  void updateAccountId(String? value) {
    state = state.copyWith(accountId: value);
    if (value != null) {
      accountService.getLatestAccountBalance(value).first.then((balance) {
        if (state.type == GoalType.reduceCreditCard) {
          updateCurrentAmount(balance.balance.abs());
        } else if (state.type == GoalType.payDebt) {
          // Se for uma conta de dívida, o saldo inicial (targetAmount) é a dívida total
          // e o currentAmount é o quanto já foi amortizado.
          // Geralmente o saldo da conta de dívida no app será negativo e irá para zero.
          // Mas para a meta, queremos saber o quanto falta.
          // Se targetAmount é 1000 e saldo é -800, então pagou 200.
          final paid =
              state.targetAmount + balance.balance; // Ex: 1000 + (-800) = 200
          updateCurrentAmount(paid > 0 ? paid : 0);
        } else {
          updateCurrentAmount(balance.balance);
        }
      });
    }
  }

  @override
  Future<void> submit() async {
    final goal = state.asGoalModel();

    if (state.creation) {
      final saved = await goalService.addGoal(goal);

      state = state.copyWith(id: saved.id);
    } else {
      await goalService.updateGoal(goal);
    }
  }
}
