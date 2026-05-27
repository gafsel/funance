import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal_model.g.dart';

enum GoalType {
  @JsonValue('save_money')
  saveMoney,
  @JsonValue('reduce_expense')
  reduceExpense,
  @JsonValue('reduce_credit_card')
  reduceCreditCard,
}

enum GoalStatus {
  onTrack,
  atRisk,
  behind,
  lost,
}

class GoalProgress {
  final double percent;
  final GoalStatus status;
  final bool isLost;

  GoalProgress({
    required this.percent,
    required this.status,
    required this.isLost,
  });
}

@JsonSerializable()
class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String? icon;
  final GoalType type;
  @JsonKey(name: 'accountId')
  final String? accountId;
  final DateTime startDate;
  final Map<String, dynamic>? metadata;
  final bool isDeleted;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.icon,
    required this.type,
    this.accountId,
    DateTime? startDate,
    this.metadata,
    this.isDeleted = false,
  }) : startDate = startDate ?? DateTime.now();

  factory GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);
  Map<String, dynamic> toJson() => _$GoalModelToJson(this);

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Goal data is null');

    return GoalModel.fromJson({
      'type': 'save_money',
      ...data,
      'id': doc.id,
      'startDate': (data['startDate'] as Timestamp?)?.toDate().toIso8601String() ?? (data['start_date'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'deadline': (data['deadline'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  GoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? deadline,
    String? icon,
    String? accountId,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
  }) {
    return GoalModel(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      type: type,
      accountId: accountId ?? this.accountId,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  GoalProgress calculateProgress() {
    final double percent;
    final GoalStatus status;
    final bool isLost;

    final now = DateTime.now();
    final totalDuration = deadline.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    final timePercent = totalDuration > 0 ? (elapsedDuration / totalDuration).clamp(0.0, 1.0) : 1.0;

    if (type == GoalType.saveMoney) {
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
