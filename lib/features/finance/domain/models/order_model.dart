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

  @JsonSerializable(explicitToJson: true)
  const factory OrderModel.expense({
    required String id,
    required String description,
    required double totalAmount,
    required CategoryModel category,
    required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    String? planningId,
    String? accountId,
    bool? isDeleted,
  }) = ExpenseOrder;

  @JsonSerializable(explicitToJson: true)
  const factory OrderModel.income({
    required String id,
    required String description,
    required double totalAmount,
    required CategoryModel category,
    required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    String? planningId,
    String? accountId,
    bool? isDeleted,
  }) = IncomeOrder;

  @JsonSerializable(explicitToJson: true)
  const factory OrderModel.transfer({
    required String id,
    required String description,
    required double totalAmount,
    required CategoryModel category,
    required int installmentsCount,
    required DateTime date,
    required OrderStatus status,
    String? planningId,
    String? fromAccountId,
    String? toAccountId,
    @Default(false) bool isDeleted,
  }) = TransferOrder;

  OrderType get type => map(
        expense: (_) => OrderType.expense,
        income: (_) => OrderType.income,
        transfer: (_) => OrderType.transfer,
      );

  List<String> get computedAccountIds => map(
        expense: (o) => [if (o.accountId != null) o.accountId!],
        income: (o) => [if (o.accountId != null) o.accountId!],
        transfer: (o) => [
          if (o.fromAccountId != null) o.fromAccountId!,
          if (o.toAccountId != null) o.toAccountId!,
        ],
      );

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = map(
      expense: (o) => o.toJson(),
      income: (o) => o.toJson(),
      transfer: (o) => o.toJson(),
    );
    return {
      ...jsonMap,
      'accountIds': computedAccountIds,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
}
