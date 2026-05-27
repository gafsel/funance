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
    this.metadata,
    this.isDeleted = false,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);
  Map<String, dynamic> toJson() => _$GoalModelToJson(this);

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Goal data is null');

    return GoalModel.fromJson({
      'type': 'save_money',
      ...data,
      'id': doc.id,
      'deadline': (data['deadline'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }

  GoalModel copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
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
      deadline: deadline ?? this.deadline,
      icon: icon ?? this.icon,
      type: type,
      accountId: accountId ?? this.accountId,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
