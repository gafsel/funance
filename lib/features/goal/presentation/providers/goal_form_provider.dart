import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Formulário de meta.
///
/// `currentAmount` NÃO é editável: quem o mantém é o servidor (pagamentos,
/// realizado da categoria ou saldo da conta de dívida). O estado ainda carrega
/// o valor para não zerá-lo numa edição, mas nada aqui o altera — por isso o
/// notifier também não precisa mais do `AccountService`, que só existia para
/// preencher esse campo com o saldo da conta escolhida.
class GoalFormNotifier extends FormNotifier<GoalFormState, void> {
  final GoalService goalService;

  GoalFormNotifier({
    required this.goalService,
    GoalModel? initialGoal,
  }) : super(GoalFormState.initial(initialGoal));

  void updateName(String value) => state = state.copyWith(name: value);

  void updateTargetAmount(double value) =>
      state = state.copyWith(targetAmount: value);

  void updateStartDate(DateTime value) =>
      state = state.copyWith(startDate: value);

  void updateDeadline(DateTime value) =>
      state = state.copyWith(deadline: value);

  void updateType(GoalType value) => state = state.copyWith(type: value);

  void updateCategory(CategoryModel? value) =>
      state = state.copyWith(category: value);

  void updateAccountId(String? value) =>
      state = state.copyWith(accountId: value);

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
