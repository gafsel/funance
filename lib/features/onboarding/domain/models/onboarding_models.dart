import 'package:json_annotation/json_annotation.dart';
import '../../../finance/domain/models/order_model.dart';
import '../../../finance/domain/models/planning_model.dart';

part 'onboarding_models.g.dart';

@JsonSerializable(explicitToJson: true)
class ExtractedFinanceData {
  final List<OrderModel> transactions;
  final List<PlanningModel> planningSuggestions;
  final double initialBalance;
  final DateTime? initialDate;

  ExtractedFinanceData({
    required this.transactions,
    required this.planningSuggestions,
    required this.initialBalance,
    this.initialDate,
  });

  factory ExtractedFinanceData.fromJson(Map<String, dynamic> json) => _$ExtractedFinanceDataFromJson(json);
  Map<String, dynamic> toJson() => _$ExtractedFinanceDataToJson(this);
}
