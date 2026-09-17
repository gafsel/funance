import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'monthly_available_model.freezed.dart';

/// "Quanto posso gastar até o fim do mês" — a pergunta que a Jornada responde
/// com um número só.
///
/// Renda prevista vem do PLANEJAMENTO (a expectativa que o usuário declarou),
/// não do que já entrou: a pergunta é sobre o mês inteiro, e quem é pago no
/// dia 30 não tem zero disponível no dia 2. As despesas descontadas são as
/// duas que já estão decididas — o que já saiu (`actualAmount`) e o que está
/// agendado para sair até o fim do mês.
@freezed
sealed class MonthlyAvailable with _$MonthlyAvailable {
  const MonthlyAvailable._();

  const factory MonthlyAvailable({
    /// Soma de `max(generalPlannedAmount, specificPlannedAmount)` das
    /// categorias de receita no `period_summaries` do mês.
    required double expectedIncome,

    /// Soma de `actualAmount` das categorias de despesa (sem as de sistema).
    required double realizedExpenses,

    /// Parcelas de despesa ainda `pending` com vencimento até o fim do mês.
    required double pendingExpenses,

    /// Soma dos limites de despesa do mês, para a linha "realizado/previsto".
    required double plannedExpenses,
  }) = _MonthlyAvailable;

  /// O número grande.
  double get available => expectedIncome - realizedExpenses - pendingExpenses;

  /// Sem expectativa de receita não há o que dividir: a tela convida a
  /// declará-la em vez de mostrar um disponível negativo que só reflete a
  /// ausência do dado.
  bool get hasIncomeExpectation => expectedIncome > 0;

  /// Quanto do previsto já foi gasto, de 0 a 1. Sem previsão, 0.
  double get spentFraction =>
      plannedExpenses > 0 ? (realizedExpenses / plannedExpenses).clamp(0.0, 1.0) : 0.0;

  /// Calcula a partir do resumo do mês e das parcelas pendentes.
  ///
  /// Categorias de sistema ficam de fora: o saldo inicial de um cartão entra
  /// no resumo como receita/despesa e não é escolha de consumo de ninguém —
  /// é a mesma exclusão que `evaluateMonthlyMissionsCron` faz no servidor.
  factory MonthlyAvailable.from({
    required List<OverviewCategorySummary> summaries,
    required List<InstallmentModel> pendingInstallments,
  }) {
    var expectedIncome = 0.0;
    var realizedExpenses = 0.0;
    var plannedExpenses = 0.0;

    for (final summary in summaries) {
      if (summary.category.isSystem) continue;

      if (summary.category.type == CategoryType.income) {
        expectedIncome += summary.plannedAmount;
      } else {
        realizedExpenses += summary.actualAmount;
        plannedExpenses += summary.plannedAmount;
      }
    }

    var pendingExpenses = 0.0;
    for (final installment in pendingInstallments) {
      if (installment.type != OrderType.expense) continue;
      if (installment.status != InstallmentStatus.pending) continue;
      if (installment.category?.isSystem ?? false) continue;

      pendingExpenses += installment.referenceAmount;
    }

    return MonthlyAvailable(
      expectedIncome: expectedIncome,
      realizedExpenses: realizedExpenses,
      pendingExpenses: pendingExpenses,
      plannedExpenses: plannedExpenses,
    );
  }
}
