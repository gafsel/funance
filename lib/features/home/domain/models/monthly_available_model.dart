import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/core/money/money.dart';

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

  /// Janela das parcelas pendentes que entram na conta: do primeiro instante
  /// do dia 1 ao último instante do último dia do mês de [today].
  ///
  /// Pura e nomeada para ser testável sem Firestore: é ela que decide se a
  /// conta que vence dia 3 do mês que vem entra no "disponível" deste mês (não
  /// entra). O fim do dia é necessário porque `referenceDate` é normalizado às
  /// 12:00 — cortar na meia-noite perderia tudo o que vence no último dia.
  static ({DateTime start, DateTime end}) pendingWindow(DateTime today) => (
    start: DateTime(today.year, today.month, 1),
    // Dia 0 do mês seguinte é o último dia deste.
    end: DateTime(today.year, today.month + 1, 0, 23, 59, 59),
  );

  /// Calcula a partir do resumo do mês e das parcelas pendentes.
  ///
  /// Categorias de sistema ficam de fora: o saldo inicial de um cartão entra
  /// no resumo como receita/despesa e não é escolha de consumo de ninguém —
  /// é a mesma exclusão que `evaluateMonthlyMissionsCron` faz no servidor.
  factory MonthlyAvailable.from({
    required List<OverviewCategorySummary> summaries,
    required List<InstallmentModel> pendingInstallments,
  }) {
    var expectedIncome = Money.zero;
    var realizedExpenses = Money.zero;
    var plannedExpenses = Money.zero;

    for (final summary in summaries) {
      if (summary.category.isSystem) continue;

      if (summary.category.type == CategoryType.income) {
        expectedIncome += summary.plannedAmount.asMoney;
      } else {
        realizedExpenses += summary.actualAmount.asMoney;
        plannedExpenses += summary.plannedAmount.asMoney;
      }
    }

    var pendingExpenses = Money.zero;
    for (final installment in pendingInstallments) {
      if (installment.type != OrderType.expense) continue;
      if (installment.status != InstallmentStatus.pending) continue;
      if (installment.category?.isSystem ?? false) continue;

      pendingExpenses += installment.referenceAmount.asMoney;
    }

    return MonthlyAvailable(
      expectedIncome: expectedIncome.toDouble(),
      realizedExpenses: realizedExpenses.toDouble(),
      pendingExpenses: pendingExpenses.toDouble(),
      plannedExpenses: plannedExpenses.toDouble(),
    );
  }
}
