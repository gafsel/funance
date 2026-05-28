import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'planning_model.freezed.dart';
part 'planning_model.g.dart';

enum PlanningType {
  @JsonValue('unique')
  unique,
  @JsonValue('recurrent')
  recurrent,
  @JsonValue('parcelado')
  parcelado,
}

@freezed
sealed class PlanningModel with _$PlanningModel {
  const PlanningModel._();

  const factory PlanningModel.unique({
    required String id,
    required CategoryModel category,
    required double amount,
    @JsonKey(name: 'installments_count') int? installmentsCount,
    @JsonKey(name: 'startDate') required DateTime startDate,
    @JsonKey(name: 'endDate') required DateTime endDate,
    String? accountId,
  }) = UniquePlanning;

  const factory PlanningModel.recurrent({
    required String id,
    required CategoryModel category,
    required double amount,
    @JsonKey(name: 'installments_count') int? installmentsCount,
    @JsonKey(name: 'startDate') required DateTime startDate,
    @JsonKey(name: 'endDate') required DateTime endDate,
    String? accountId,
  }) = RecurrentPlanning;

  const factory PlanningModel.parcelado({
    required String id,
    required CategoryModel category,
    required double amount,
    @JsonKey(name: 'installments_count') int? installmentsCount,
    @JsonKey(name: 'startDate') required DateTime startDate,
    @JsonKey(name: 'endDate') required DateTime endDate,
    String? accountId,
  }) = ParceladoPlanning;

  PlanningType get type => map(
    unique: (_) => PlanningType.unique,
    recurrent: (_) => PlanningType.recurrent,
    parcelado: (_) => PlanningType.parcelado,
  );

  factory PlanningModel.fromJson(Map<String, dynamic> json) => _$PlanningModelFromJson(json);
}
