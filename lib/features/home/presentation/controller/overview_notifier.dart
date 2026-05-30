import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class SummaryNotifier extends Notifier<SummaryState> {
  @override
  SummaryState build() {
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final summaries =
        ref.watch(PeriodSummaryViewProviders.monthSummary(period)).value ?? [];

    // Ignorar categorias de receitas (income)
    final filteredSummaries = summaries
        .where((s) => s.category.type != CategoryType.income)
        .toList();

    // Ordenar por valor (de maior para menor) baseado no viewType
    final sortedSummaries = [...filteredSummaries];
    sortedSummaries.sort((a, b) {
      double valA = 0;
      double valB = 0;
      if (viewType == SummaryViewType.planning) {
        valA = a.plannedAmount;
        valB = b.plannedAmount;
      } else {
        valA = a.actualAmount;
        valB = b.actualAmount;
      }
      return valB.compareTo(valA);
    });

    // Limitar a 10 registros e agrupar o resto em "Outros"
    List<PeriodSummaryModel> displaySummaries = [];

    double specificPlannedAmountOthers = 0;
    double generalPlannedAmountOthers = 0;
    double actualAmountOthers = 0;

    if (sortedSummaries.length > 10) {
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
    } else if (viewType == SummaryViewType.effective) {
      totalAmount = filteredSummaries.fold<double>(
        0,
        (sum, item) => sum + item.actualAmount,
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
}
