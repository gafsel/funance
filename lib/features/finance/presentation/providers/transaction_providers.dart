import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_month_summary_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/planning_repository.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/providers/planning_providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';

enum TransactionType { expense, income, plannedExpense, plannedIncome }

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final IFinanceRepository _repository;
  final IPlanningRepository _planningRepository;
  final String? _workspaceId;
  final Ref _ref;

  TransactionNotifier(
    this._repository,
    this._planningRepository,
    this._workspaceId,
    this._ref,
  ) : super(const AsyncValue.data(null));

  Future<AsyncValue<void>> saveTransaction({
    required String description,
    required double amount,
    required CategoryModel? category,
    required DateTime date,
    required OrderType type,
    required OrderStatus status,
    int installments = 1,
    Map<String, dynamic>? metadata,
    String? existingOrderId,
    bool isPlannedFlow = false,
    PlanningType? planningType,
    int? planningInstallments,
    DateTime? startDate,
    DateTime? endDate,
    String? planningId,
  }) async {
    if (_workspaceId == null) return const AsyncValue.data(null);

    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      if (isPlannedFlow) {
        if (category == null)
          throw Exception('Category is required for planning');

        final planning = PlanningModel(
          id: existingOrderId ?? '',
          category: category,
          amount: amount,
          type: planningType ?? PlanningType.unique,
          installmentsCount: planningInstallments,
          startDate: startDate ?? date,
          endDate: endDate ?? date,
        );

        if (existingOrderId != null && existingOrderId.isNotEmpty) {
          await _planningRepository.updatePlanning(_workspaceId!, planning);
        } else {
          await _planningRepository.addPlanning(_workspaceId!, planning);
        }
      } else {
        final finalCategory =
            category ??
            CategoryModel(
              id: 'transfer',
              name: 'Transfer',
              icon: 'swap_horiz',
              color: '#25D3D0',
              type: CategoryType.both,
            );

        final order = OrderModel(
          id: existingOrderId ?? '',
          description: description,
          totalAmount: amount,
          category: finalCategory,
          installmentsCount: installments,
          date: date,
          status: status,
          type: type,
          planningId: planningId,
          metadata: metadata,
        );

        if (existingOrderId != null && existingOrderId.isNotEmpty) {
          await _repository.updateOrder(_workspaceId!, order);
        } else {
          await _repository.addOrder(_workspaceId!, order);
        }
      }
    });

    state = result;
    return result;
  }

  Future<void> deleteTransaction(String orderId) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Exclusão lógica é tratada alterando o status para cancelled
      // Mas o requisito diz "excluído logicamente", vamos verificar se temos status de excluído
      // No OrderStatus enum temos active, paid, cancelled.
      // Vou sugerir usar cancelled ou adicionar um campo is_deleted se necessário.
      // Como o blueprint diz "exclusão lógica", vou usar updateOrder para marcar como cancelled ou similar.
      final order = await _repository.getOrder(_workspaceId!, orderId);
      if (order != null) {
        final updatedOrder = OrderModel(
          id: order.id,
          description: order.description,
          totalAmount: order.totalAmount,
          category: order.category,
          installmentsCount: order.installmentsCount,
          date: order.date,
          status: OrderStatus.cancelled,
          type: order.type,
          planningId: order.planningId,
          metadata: {...?(order.metadata), 'is_deleted': true},
        );
        await _repository.updateOrder(_workspaceId!, updatedOrder);
      }
    });
  }

  Future<List<OrderModel>> getPlannedOrders(OrderType type) async {
    return [];
  }
}

class HistoryState {
  final List<OrderModel> orders;
  final bool isLoading;
  final bool hasMore;
  final OrderModel? lastOrder;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;

  HistoryState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastOrder,
    this.accountId,
    this.startDate,
    this.endDate,
  });

  HistoryState copyWith({
    List<OrderModel>? orders,
    bool? isLoading,
    bool? hasMore,
    OrderModel? lastOrder,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return HistoryState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastOrder: lastOrder ?? this.lastOrder,
      accountId: accountId ?? this.accountId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final IFinanceRepository _repository;
  final String? _workspaceId;
  static const int _pageSize = 20;

  HistoryNotifier(this._repository, this._workspaceId) : super(HistoryState()) {
    // Inicializar com o mês atual por padrão
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    state = state.copyWith(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
    
    loadOrders();
  }

  Future<void> setFilters({
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      orders: [],
      lastOrder: null,
      hasMore: true,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
    await loadOrders(isRefresh: true);
  }

  Future<void> loadOrders({bool isRefresh = false}) async {
    if (_workspaceId == null) return;
    if (state.isLoading || (!state.hasMore && !isRefresh)) return;

    if (isRefresh) {
      state = state.copyWith(
        orders: [],
        lastOrder: null,
        hasMore: true,
        isLoading: true,
      );
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final newOrders = await _repository.getOrders(
        _workspaceId!,
        limit: _pageSize,
        lastOrder: state.lastOrder,
        accountId: state.accountId,
        startDate: state.startDate,
        endDate: state.endDate,
      );

      // Filtra ordens excluídas logicamente
      final activeOrders = newOrders
          .where((o) => o.metadata?['is_deleted'] != true)
          .toList();

      state = state.copyWith(
        orders: isRefresh ? activeOrders : [...state.orders, ...activeOrders],
        isLoading: false,
        hasMore: newOrders.length == _pageSize,
        lastOrder: newOrders.isNotEmpty ? newOrders.last : state.lastOrder,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
}

final planningsForPeriodProvider = StreamProvider<List<PlanningModel>>((ref) {
  final repository = ref.watch(planningRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;
  final date =
      DateTime.now(); // Período corrente para simplificar o preenchimento

  if (workspaceId == null) {
    return const Stream.empty();
  }

  final start = DateTime(date.year, date.month, 1);
  final end = DateTime(date.year, date.month + 1, 0);

  return repository.watchPlannings(workspaceId, startDate: start, endDate: end);
});

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;
  return HistoryNotifier(repository, workspaceId);
});

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(financeRepositoryProvider);
      final planningRepository = ref.watch(planningRepositoryProvider);
      final workspaceId = ref
          .watch(workspaceNotifierProvider)
          .currentWorkspace
          ?.id;
      return TransactionNotifier(
        repository,
        planningRepository,
        workspaceId,
        ref,
      );
    });

final plannedOrdersProvider =
    FutureProvider.family<List<OrderModel>, OrderType>((ref, type) async {
      final notifier = ref.watch(transactionNotifierProvider.notifier);
      return notifier.getPlannedOrders(type);
    });

// Providers para Sumários e Relatórios
// O financeRepositoryProvider já está definido em account_providers.dart

final overviewDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final categorySummariesProvider =
    StreamProvider<List<CategoryMonthSummaryModel>>((ref) {
      final repository = ref.watch(financeRepositoryProvider);
      final workspaceId = ref
          .watch(workspaceNotifierProvider)
          .currentWorkspace
          ?.id;
      final date = ref.watch(overviewDateProvider);

      if (workspaceId == null) return Stream.value([]);

      return repository.watchCategorySummaries(
        workspaceId,
        date.year,
        date.month,
      );
    });

final overviewAccountTypeProvider = StateProvider<AccountType?>((ref) => null);

final overviewViewTypeProvider = StateProvider<OverviewViewType>(
  (ref) => OverviewViewType.effective,
);

enum OverviewViewType { planning, effective, comparison }
