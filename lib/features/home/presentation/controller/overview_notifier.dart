import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/money/money.dart';

/// Os resumos do mês, com o ERRO preservado.
///
/// Estes notifiers liam `.value ?? []` do `monthSummary`: sem rede, o stream
/// falhava, a lista vazia tomava o lugar do erro e a Visão Geral afirmava
/// "nenhum lançamento no período" — com o saldo em R$ 0,00. `AsyncValue`
/// carrega o erro até a tela, que agora mostra o ErrorView com "tentar de
/// novo" no lugar do estado vazio.
class ExpenseSummaryNotifier extends Notifier<AsyncValue<SummaryState>> {
  @override
  AsyncValue<SummaryState> build() {
    // Escutar mudanças no período e tipo de visualização
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    return ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .whenData(
          (summaries) => _buildSummary(
            summaries
                .where((s) => s.category.type == CategoryType.expense)
                .toList(),
            viewType,
          ),
        );
  }
}

class IncomeSummaryNotifier extends Notifier<AsyncValue<SummaryState>> {
  @override
  AsyncValue<SummaryState> build() {
    // Escutar mudanças no período e tipo de visualização
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    return ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .whenData(
          (summaries) => _buildSummary(
            summaries
                .where((s) => s.category.type == CategoryType.income)
                .toList(),
            viewType,
          ),
        );
  }
}

class ExpenseSummaryFullNotifier extends Notifier<AsyncValue<SummaryState>> {
  @override
  AsyncValue<SummaryState> build() {
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    return ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .whenData(
          (summaries) => _buildSummary(
            summaries
                .where((s) => s.category.type == CategoryType.expense)
                .toList(),
            viewType,
            limit: false,
          ),
        );
  }
}

class IncomeSummaryFullNotifier extends Notifier<AsyncValue<SummaryState>> {
  @override
  AsyncValue<SummaryState> build() {
    final period = ref.watch(HomeViewProviders.period);
    final viewType = ref.watch(HomeViewProviders.viewType);

    return ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .whenData(
          (summaries) => _buildSummary(
            summaries
                .where((s) => s.category.type == CategoryType.income)
                .toList(),
            viewType,
            limit: false,
          ),
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
    // O agrupamento "Outros" vai para o fim. Pelo ID, não pelo nome: comparar
    // com a palavra "outros" quebrava em inglês — e ainda mandava para o fim
    // uma categoria de verdade que o usuário tivesse batizado assim.
    final isAOthers = a.category.id == CategoryModel.othersId;
    final isBOthers = b.category.id == CategoryModel.othersId;

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

  var specificPlannedAmountOthers = Money.zero;
  var generalPlannedAmountOthers = Money.zero;
  var actualAmountOthers = Money.zero;

  if (limit && sortedSummaries.length > 10) {
    displaySummaries = sortedSummaries.sublist(0, 9);
    final others = sortedSummaries.sublist(9);

    // "Outros" precisa fechar com a diferença entre o total e as nove linhas
    // mostradas. Somado em double, sobrava um centavo que não era de
    // ninguém — em centavos inteiros, a conta bate.
    specificPlannedAmountOthers = Money.sumOf(
      others,
      (s) => s.specificPlannedAmount,
    );
    generalPlannedAmountOthers = Money.sumOf(
      others,
      (s) => s.generalPlannedAmount,
    );
    actualAmountOthers = Money.sumOf(others, (s) => s.actualAmount);
  } else {
    displaySummaries = sortedSummaries;
  }

  final totalAmount = viewType == SummaryViewType.planning
      ? Money.sumOf(filteredSummaries, (item) => item.plannedAmount)
      : Money.sumOf(filteredSummaries, (item) => item.actualAmount);

  return SummaryState(
    summary: displaySummaries,
    actualAmountOthers: actualAmountOthers.toDouble(),
    specificPlannedAmountOthers: specificPlannedAmountOthers.toDouble(),
    generalPlannedAmountOthers: generalPlannedAmountOthers.toDouble(),
    totalAmount: totalAmount.toDouble(),
  );
}

class BalanceSummaryNotifier extends Notifier<AsyncValue<BalanceState>> {
  @override
  AsyncValue<BalanceState> build() {
    final period = ref.watch(HomeViewProviders.period);

    return ref
        .watch(PeriodSummaryViewProviders.monthSummary(period.monthKey))
        .whenData(_balanceOf);
  }
}

BalanceState _balanceOf(List<OverviewCategorySummary> summaries) {
    var totalPlannedIncomes = Money.zero;
    var totalActualIncomes = Money.zero;
    var totalPlannedExpenses = Money.zero;
    var totalActualExpenses = Money.zero;

    for (var s in summaries) {
      if (s.category.type == CategoryType.income) {
        totalPlannedIncomes += s.plannedAmount.asMoney;
        totalActualIncomes += s.actualAmount.asMoney;
      } else if (s.category.type == CategoryType.expense) {
        totalPlannedExpenses += s.plannedAmount.asMoney;
        totalActualExpenses += s.actualAmount.asMoney;
      }
    }

    // O saldo é a subtração de duas somas. Em double, "sobrou zero" podia
    // aparecer como -0,000000001 e a tela pintava de vermelho um mês fechado.
    return BalanceState(
      totalPlanned: (totalPlannedIncomes - totalPlannedExpenses).toDouble(),
      totalActual: (totalActualIncomes - totalActualExpenses).toDouble(),
    );
}
