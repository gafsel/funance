import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';

class TransactionListNotifier
    extends InfiniteListNotifier<TransactionQuery, InstallmentModel> {
  final FinanceService financeiroService;

  TransactionListNotifier({required this.financeiroService})
    : super(
        initialQuery: TransactionQuery(endDate: DateTime.now()),
        executor: (query, {chunkRef}) async {
          return await financeiroService.queryInstallments(
            limit: 10,
            accountId: query.accountId,
            startDate: query.startDate,
            endDate: query.endDate,
            lastOrderId: chunkRef,
          );
        },
      ) {
    load();
  }

  Future<void> delete(
    String id, {
    required ReplicationCascade replicationCascade,
  }) async {
    await financeiroService.cancelInstallment(
      id,
      replicationCascade: replicationCascade,
    );

    state = state.copyWith(
      items: [...state.items.where((item) => item.id != id)],
    );
  }
}
