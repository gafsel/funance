import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';

part 'automatic_transaction_model.freezed.dart';
part 'automatic_transaction_model.g.dart';

@freezed
sealed class AutomaticTransactionModel with _$AutomaticTransactionModel {
  const factory AutomaticTransactionModel({
    required String id,
    required String description,
    required double amount,
    required DateTime date,
    required OrderType type,
    String? originNotificationId, // Para evitar duplicidade
    String? packageName, // App que originou a notificação
    String? accountId,
    String? categoryId,
    CategoryModel? suggestedCategory,
    AccountModel? suggestedAccount,
    @Default(false) bool isConsolidated,
    @Default(false) bool isIgnored,
    Map<String, dynamic>? metadata,
  }) = _AutomaticTransactionModel;

  factory AutomaticTransactionModel.fromJson(Map<String, dynamic> json) =>
      _$AutomaticTransactionModelFromJson(json);
}
