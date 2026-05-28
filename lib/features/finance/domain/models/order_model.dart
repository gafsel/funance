import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

enum OrderStatus {
  @JsonValue('active')
  active,
  @JsonValue('paid')
  paid,
  @JsonValue('cancelled')
  cancelled,
}

enum OrderType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
  @JsonValue('transfer')
  transfer,
}

@JsonSerializable(explicitToJson: true)
class OrderModel {
  final String id;
  final String description;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final CategoryModel category;
  @JsonKey(name: 'installments_count')
  final int installmentsCount;
  final DateTime date;
  final OrderStatus status;
  final OrderType type;
  @JsonKey(name: 'planning_id')
  final String? planningId;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.category,
    required this.installmentsCount,
    required this.date,
    required this.status,
    required this.type,
    this.planningId,
    this.metadata,
  });

  OrderModel copyWith({
    String? id,
    String? description,
    double? totalAmount,
    CategoryModel? category,
    int? installmentsCount,
    DateTime? date,
    OrderStatus? status,
    OrderType? type,
    String? planningId,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: id ?? this.id,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      category: category ?? this.category,
      installmentsCount: installmentsCount ?? this.installmentsCount,
      date: date ?? this.date,
      status: status ?? this.status,
      type: type ?? this.type,
      planningId: planningId ?? this.planningId,
      metadata: metadata ?? this.metadata,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Order data is null');

    return OrderModel.fromJson({
      'type': 'expense',
      'status': 'active',
      ...data,
      'id': doc.id,
      'total_amount': (data['total_amount'] ?? data['totalAmount'] ?? 0.0).toDouble(),
      'installments_count': data['installments_count'] ?? data['installmentsCount'] ?? 1,
      'planning_id': data['planning_id'] ?? data['planningId'],
      'date': (data['date'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
