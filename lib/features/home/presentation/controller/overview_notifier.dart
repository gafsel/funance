import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class ExpenseSummaryNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    // Escutar mudanças no período e tipo de visualização
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    final summaries =
        ref.watch(PeriodSummaryViewProviders.monthSummary(period.monthKey)).value ?? [];

    return _buildSummary(
      summaries.where((s) => s.category.type == CategoryType.expense).toList(),
      viewType,
    );
  }
}

class IncomeSummaryNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    // Escutar mudanças no período e tipo de visualização
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    final summaries =
        ref.watch(PeriodSummaryViewProviders.monthSummary(period.monthKey)).value ?? [];

    return _buildSummary(
      summaries.where((s) => s.category.type == CategoryType.income).toList(),
      viewType,
    );
  }
}

class ExpenseSummaryFullNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    final summaries =
        ref.watch(PeriodSummaryViewProviders.monthSummary(period.monthKey)).value ?? [];

    return _buildSummary(
      summaries.where((s) => s.category.type == CategoryType.expense).toList(),
      viewType,
      limit: false,
    );
  }
}

class IncomeSummaryFullNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    final summaries =
        ref.watch(PeriodSummaryViewProviders.monthSummary(period.monthKey)).value ?? [];

    return _buildSummary(
      summaries.where((s) => s.category.type == CategoryType.income).toList(),
      viewType,
      limit: false,
    );
  }
}

SummaryState _buildSummary(
  List<OverviewCategorySummary> filteredSummaries,
  SummaryViewType viewType, {
  bool limit = true,
}) {
  // Ordenar por valor (de maior para menor) baseado no viewType
  final sortedSummaries = [...filteredSummaries];
  sortedSummaries.sort((a, b) {
    // Se um for virtual (pode ser o "Outros" real se implementado como virtual, 
    // mas aqui estamos lidando com as categorias vindas do banco)
    // Se o nome for "Outros", deve ficar por último
    final isAOthers = a.category.name.toLowerCase() == 'outros' || a.category.id == 'others';
    final isBOthers = b.category.name.toLowerCase() == 'outros' || b.category.id == 'others';

    if (isAOthers && !isBOthers) return 1;
    if (!isAOthers && isBOthers) return -1;

    double valA = 0;
    double valB = 0;

    if (viewType == SummaryViewType.planning) {
      valA = a.plannedAmount;
      valB = b.plannedAmount;
    } else if (viewType == SummaryViewType.effective) {
      valA = a.actualAmount;
      valB = b.actualAmount;
    } else {
      valA = a.plannedAmount > a.actualAmount ? a.plannedAmount : a.actualAmount;
      valB = b.plannedAmount > b.actualAmount ? b.plannedAmount : b.actualAmount;
    }
    
    return valB.compareTo(valA);
  });

  // Limitar a 10 registros e agrupar o resto em "Outros"
  List<OverviewCategorySummary> displaySummaries = [];

  double specificPlannedAmountOthers = 0;
  double generalPlannedAmountOthers = 0;
  double actualAmountOthers = 0;

  if (limit && sortedSummaries.length > 10) {
    displaySummaries = sortedSummaries.sublist(0, 9);
    final others = sortedSummaries.sublist(9);

    for (var s in others) {
      specificPlannedAmountOthers += s.specificPlannedAmount;
      generalPlannedAmountOthers += s.generalPlannedAmount;
      actualAmountOthers += s.actualAmount;
    }
  } else {
    displaySummaries = sortedSummaries;
  }

  double totalAmount = 0;
  if (viewType == SummaryViewType.planning) {
    totalAmount = filteredSummaries.fold<double>(
      0,
      (sum, item) => sum + item.plannedAmount,
    );
  } else {
    totalAmount = filteredSummaries.fold<double>(
      0,
      (sum, item) => sum + item.actualAmount,
    );
  }

  return SummaryState(
    summary: displaySummaries,
    actualAmountOthers: actualAmountOthers,
    specificPlannedAmountOthers: specificPlannedAmountOthers,
    generalPlannedAmountOthers: generalPlannedAmountOthers,
    totalAmount: totalAmount,
  );
}

class BalanceSummaryNotifier extends Notifier<BalanceState> {
  @override
  BalanceState build() {
    final period = ref.watch(HomeViewProviders.period);
    final summaries = ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .value ?? [];

    double totalPlannedIncomes = 0;
    double totalActualIncomes = 0;
    double totalPlannedExpenses = 0;
    double totalActualExpenses = 0;

    for (var s in summaries) {
      if (s.category.type == CategoryType.income) {
        totalPlannedIncomes += s.plannedAmount;
        totalActualIncomes += s.actualAmount;
      } else if (s.category.type == CategoryType.expense) {
        totalPlannedExpenses += s.plannedAmount;
        totalActualExpenses += s.actualAmount;
      }
    }

    return BalanceState(
      totalPlanned: totalPlannedIncomes - totalPlannedExpenses,
      totalActual: totalActualIncomes - totalActualExpenses,
    );
  }
}
