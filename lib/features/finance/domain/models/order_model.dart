import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';
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

@freezed
sealed class OrderModel with _$OrderModel {
  const OrderModel._();

  const factory OrderModel.expense({
    required String id,
    required String description,
    @JsonKey(name: 'total_amount') required double totalAmount,
    required CategoryModel category,
    @JsonKey(name: 'installments_count') required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    @JsonKey(name: 'planning_id') String? planningId,
    String? accountId,
    @JsonKey(name: 'is_deleted') bool? isDeleted,
  }) = ExpenseOrder;

  const factory OrderModel.income({
    required String id,
    required String description,
    @JsonKey(name: 'total_amount') required double totalAmount,
    required CategoryModel category,
    @JsonKey(name: 'installments_count') required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    @JsonKey(name: 'planning_id') String? planningId,
    String? accountId,
    @JsonKey(name: 'is_deleted') bool? isDeleted,
  }) = IncomeOrder;

  const factory OrderModel.transfer({
    required String id,
    required String description,
    @JsonKey(name: 'total_amount') required double totalAmount,
    required CategoryModel category,
    @JsonKey(name: 'installments_count') required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    @JsonKey(name: 'planning_id') String? planningId,
    String? fromAccountId,
    String? toAccountId,
    @JsonKey(name: 'is_deleted') bool? isDeleted,
  }) = TransferOrder;

  OrderType get type => map(
    expense: (_) => OrderType.expense,
    income: (_) => OrderType.income,
    transfer: (_) => OrderType.transfer,
  );

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
}
