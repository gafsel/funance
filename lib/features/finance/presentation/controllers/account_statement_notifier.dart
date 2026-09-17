import 'dart:async';
import 'package:funances/core/list/infinite_list_notifier.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/core/observability/app_logger.dart';

class AccountStatementNotifier
    extends InfiniteListNotifier<TransactionQuery, InstallmentModel> {
  final FinanceService financeiroService;

  Timer? _debounceTimer;

  AccountStatementNotifier({
    required this.financeiroService,
    required String accountId,
    required bool isFuture,
  }) : super(
         initialQuery: TransactionQuery(
           accountId: accountId,
           startDate: isFuture ? DateTime.now() : null,
           endDate: isFuture ? null : DateTime.now(),
           descending: !isFuture,
         ),
         executor: (query, {chunkRef}) async {
           AppLogger.debug(
             'Extrato ${isFuture ? 'futuro' : 'corrente'} da conta '
             '${query.accountId}: ${query.startDate} → ${query.endDate} '
             '(descendente: ${query.descending})',
             name: 'statement',
           );
           return await financeiroService.queryInstallments(
             limit: 20,
             accountId: query.accountId,
             startDate: query.startDate,
             endDate: query.endDate,
             categoryId: query.categoryId,
             type: query.type,
             description: query.description,
             minAmount: query.minAmount,
             maxAmount: query.maxAmount,
             status: query.status,
             descending: query.descending,
             chunkRef: chunkRef,
           );
         },
       ) {
    load();
  }

  @override
  Future<void> reset({TransactionQuery? query}) async {
    if (query?.description != state.query.description) {
      // Busca por texto é debounced: o reset real roda depois do timer, então
      // este caminho não tem o que aguardar.
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        unawaited(super.reset(query: query));
      });
      state = state.copyWith(query: query ?? state.query);
    } else {
      await super.reset(query: query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
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
