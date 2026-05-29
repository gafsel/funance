import 'package:freezed_annotation/freezed_annotation.dart';

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

enum GoalStatus {
  onTrack,
  atRisk,
  behind,
  lost,
}

@freezed
sealed class GoalProgress with _$GoalProgress {
  const factory GoalProgress({
    required double percent,
    required GoalStatus status,
    required bool isLost,
  }) = _GoalProgress;
}

@freezed
sealed class GoalModel with _$GoalModel {
  const GoalModel._();

  const factory GoalModel({
    required String id,
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
    String? icon,
    required GoalType type,
    String? accountId,
    required DateTime startDate,
    Map<String, dynamic>? metadata,
    @Default(false) bool isDeleted,
  }) = _GoalModel;

  double get monthlyRequirement {
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 0;
    
    final monthsRemaining = (deadline.year - now.year) * 12 + deadline.month - now.month;
    final effectiveMonths = monthsRemaining <= 0 ? 1 : monthsRemaining;
    
    if (type == GoalType.saveMoney || type == GoalType.payDebt) {
      final remaining = targetAmount - currentAmount;
      return remaining > 0 ? remaining / effectiveMonths : 0;
    }
    
    return 0;
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);

  GoalProgress calculateProgress() {
    final double percent;
    final GoalStatus status;
    final bool isLost;

    final now = DateTime.now();
    final totalDuration = deadline.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    final timePercent = totalDuration > 0 ? (elapsedDuration / totalDuration).clamp(0.0, 1.0) : 1.0;

    if (type == GoalType.saveMoney || type == GoalType.payDebt) {
      percent = (currentAmount / targetAmount).clamp(0.0, 1.0);
      
      isLost = percent < timePercent * 0.5 && deadline.isBefore(now.add(const Duration(days: 7)));

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

      percent = (currentSpending / targetAmount).clamp(0.0, 1.0);

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
      status: status,
      isLost: isLost,
    );
  }
}
