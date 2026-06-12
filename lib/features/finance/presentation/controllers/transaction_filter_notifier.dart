import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/model/transaction_filter_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFilterNotifier
    extends FormNotifier<TransactionFilterState, TransactionQuery> {
  TransactionFilterNotifier(super.initialState);

  void updateAccountId(String? value) {
    state = state.copyWith(accountId: value);
  }

  void updateDescription(String? value) {
    state = state.copyWith(description: value?.isEmpty ?? true ? null : value);
  }

  void updateCategory(CategoryModel? value) {
    state = state.copyWith(category: value);
  }

  void updateType(OrderType? value) {
    state = state.copyWith(type: value);
  }

  void updateStatus(InstallmentStatus? value) {
    state = state.copyWith(status: value);
  }

  void updateMinAmount(double? value) {
    state = state.copyWith(minAmount: value);
  }

  void updateMaxAmount(double? value) {
    state = state.copyWith(maxAmount: value);
  }

  void clear() {
    state = TransactionFilterState(
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  @override
  Future<TransactionQuery> submit() async {
    return state.toQuery();
  }
}
