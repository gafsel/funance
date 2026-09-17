import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'goal_model.freezed.dart';

part 'goal_model.g.dart';

enum GoalType {
  @JsonValue('save_money')
  saveMoney,
  @JsonValue('reduce_expense')
  reduceExpense,
  @JsonValue('reduce_credit_card')
  reduceCreditCard,
  @JsonValue('pay_debt')
  payDebt,
}

enum GoalStatus { onTrack, atRisk, behind, lost }

/// Desfecho gravado pelo SERVIDOR quando a meta acaba.
///
/// Numa meta de redução, passar do teto é `failed` — nunca conclusão. Numa de
/// acúmulo, vencer o prazo sem alcançar o alvo também é `failed`. O app só lê:
/// as rules negam a escrita destes campos pelo cliente.
enum GoalOutcome {
  @JsonValue('success')
  success,
  @JsonValue('failed')
  failed,
}

@freezed
sealed class GoalProgress with _$GoalProgress {
  const factory GoalProgress({
    required double percent,
    required double predictionPercent,
    required GoalStatus status,
    required bool isLost,
  }) = _GoalProgress;
}

@freezed
sealed class GoalModel with _$GoalModel {
  const GoalModel._();

  @JsonSerializable(explicitToJson: true)
  const factory GoalModel.payDebt({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    required String accountId,
    required DateTime startDate,

    /// Desfecho gravado pelo SERVIDOR (`null` = ainda em andamento), com o
    /// instante em [completedAt] (sucesso) ou [failedAt] (falha). O app só lê:
    /// as rules negam a escrita e o repositório remove os campos antes de
    /// salvar.
    /// `nullForUndefinedEnumValue`: um desfecho que só um servidor mais novo
    /// conhece lê como "em andamento" em vez de derrubar a tela de metas.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GoalOutcome? outcome,
    DateTime? completedAt,
    DateTime? failedAt,
    @Default(false) bool isDeleted,
  }) = _GoalModelPayDebt;

  @JsonSerializable(explicitToJson: true)
  const factory GoalModel.reduceCreditCard({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    required String accountId,
    required DateTime startDate,

    /// Desfecho gravado pelo SERVIDOR (`null` = ainda em andamento), com o
    /// instante em [completedAt] (sucesso) ou [failedAt] (falha). O app só lê:
    /// as rules negam a escrita e o repositório remove os campos antes de
    /// salvar.
    /// `nullForUndefinedEnumValue`: um desfecho que só um servidor mais novo
    /// conhece lê como "em andamento" em vez de derrubar a tela de metas.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GoalOutcome? outcome,
    DateTime? completedAt,
    DateTime? failedAt,
    @Default(false) bool isDeleted,
  }) = _GoalModelCreditCard;

  @JsonSerializable(explicitToJson: true)
  const factory GoalModel.reduceExpense({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    required CategoryModel category,
    required DateTime startDate,

    /// Desfecho gravado pelo SERVIDOR (`null` = ainda em andamento), com o
    /// instante em [completedAt] (sucesso) ou [failedAt] (falha). O app só lê:
    /// as rules negam a escrita e o repositório remove os campos antes de
    /// salvar.
    /// `nullForUndefinedEnumValue`: um desfecho que só um servidor mais novo
    /// conhece lê como "em andamento" em vez de derrubar a tela de metas.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GoalOutcome? outcome,
    DateTime? completedAt,
    DateTime? failedAt,
    @Default(false) bool isDeleted,
  }) = _GoalModelReduceExpense;

  @JsonSerializable(explicitToJson: true)
  const factory GoalModel.saveMoney({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    required String accountId,
    required DateTime startDate,

    /// Desfecho gravado pelo SERVIDOR (`null` = ainda em andamento), com o
    /// instante em [completedAt] (sucesso) ou [failedAt] (falha). O app só lê:
    /// as rules negam a escrita e o repositório remove os campos antes de
    /// salvar.
    /// `nullForUndefinedEnumValue`: um desfecho que só um servidor mais novo
    /// conhece lê como "em andamento" em vez de derrubar a tela de metas.
    @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    GoalOutcome? outcome,
    DateTime? completedAt,
    DateTime? failedAt,
    @Default(false) bool isDeleted,
  }) = _GoalModelSaveMoney;

  /// Metas de acúmulo: o progresso é uma conquista (juntar, quitar).
  /// Nas de redução, `currentAmount` é GASTO e 100% significa estourar o teto.
  bool get isAccumulation =>
      type == GoalType.saveMoney || type == GoalType.payDebt;

  /// Meta encerrada com sucesso. Numa de redução, quer dizer que o prazo
  /// acabou com o gasto dentro do teto — NÃO que o alvo foi "alcançado".
  bool get isCompleted => outcome == GoalOutcome.success;

  /// Meta encerrada sem sucesso: teto estourado, ou prazo vencido sem atingir.
  bool get isFailed => outcome == GoalOutcome.failed;

  /// Ainda em andamento: sem desfecho e dentro do prazo.
  bool get isActive => !isDeleted && outcome == null;

  GoalType get type => map(
    payDebt: (_) => GoalType.payDebt,
    saveMoney: (_) => GoalType.saveMoney,
    reduceCreditCard: (_) => GoalType.reduceCreditCard,
    reduceExpense: (_) => GoalType.reduceExpense,
  );

  double get monthlyRequirement {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;

    final monthsRemaining =
        (deadline.year - now.year) * 12 + deadline.month - now.month;
    final effectiveMonths = monthsRemaining <= 0 ? 1 : monthsRemaining;

    if (type == GoalType.saveMoney || type == GoalType.payDebt) {
      final remaining = (targetAmount - currentAmount).abs();
      return remaining > 0 ? remaining / effectiveMonths : 0;
    }

    return 0;
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) =>
      _$GoalModelFromJson(json);

  /// Onde a meta está: quanto do alvo já foi feito, quanto do prazo já
  /// passou, e se isso é bom.
  ///
  /// [now] existe para o teste: sem ele não havia como exercitar a escada
  /// `onTrack`/`atRisk`/`behind`/`lost`, que depende inteiramente de quanto
  /// do prazo já correu. Em produção ninguém passa nada.
  GoalProgress calculateProgress({DateTime? now}) {
    final double percent;
    final GoalStatus status;
    final bool isLost;

    now ??= DateTime.now();
    final totalDuration = deadline.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    final timePercent = totalDuration > 0
        ? (elapsedDuration / totalDuration).clamp(0.0, 1.0)
        : 1.0;

    if (type == GoalType.saveMoney || type == GoalType.payDebt) {
      // Alvo zero não é uma meta: `0 / 0` é NaN, e o NaN ATRAVESSA o `clamp`
      // (que só limita números), chega na barra de progresso e a faz explodir
      // — ou desaparecer, dependendo da plataforma. Sem alvo, não há o que
      // alcançar: a meta está cumprida.
      percent = targetAmount > 0
          ? (currentAmount / targetAmount).clamp(0.0, 1.0)
          : 1.0;

      isLost =
          percent < timePercent * 0.5 &&
          deadline.isBefore(now.add(const Duration(days: 7)));

      if (percent >= 1.0) {
        status = GoalStatus.onTrack;
      } else if (isLost) {
        status = GoalStatus.lost;
      } else if (percent < timePercent * 0.8) {
        status = GoalStatus.behind;
      } else if (percent < timePercent) {
        status = GoalStatus.atRisk;
      } else {
        status = GoalStatus.onTrack;
      }
    } else {
      // Redução de gastos
      final currentSpending = currentAmount;

      // Teto zero quer dizer "não gastar nada": qualquer gasto já é o teto
      // inteiro, e gasto nenhum é zero por cento. A divisão continuaria
      // devolvendo NaN ou infinito.
      percent = targetAmount > 0
          ? (currentSpending / targetAmount).clamp(0.0, 1.0)
          : (currentSpending > 0 ? 1.0 : 0.0);

      if (currentSpending > targetAmount) {
        status = GoalStatus.lost;
        isLost = true;
      } else if (currentSpending > targetAmount * 0.9) {
        status = GoalStatus.atRisk;
        isLost = false;
      } else {
        status = GoalStatus.onTrack;
        isLost = false;
      }
    }

    return GoalProgress(
      percent: percent,
      predictionPercent: timePercent,
      status: status,
      isLost: isLost,
    );
  }
}
