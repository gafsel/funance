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

  @JsonSerializable(explicitToJson: true)
  const factory PlanningModel.unique({
    required String id,
    required CategoryModel category,
    required double amount,
    int? installmentsCount,
    required DateTime startDate,
    required DateTime endDate,
    String? accountId,
  }) = UniquePlanning;

  @JsonSerializable(explicitToJson: true)
  const factory PlanningModel.recurrent({
    required String id,
    required CategoryModel category,
    required double amount,
    int? installmentsCount,
    required DateTime startDate,
    required DateTime endDate,
    String? accountId,
  }) = RecurrentPlanning;

  @JsonSerializable(explicitToJson: true)
  const factory PlanningModel.parcelado({
    required String id,
    required CategoryModel category,
    required double amount,
    int? installmentsCount,
    required DateTime startDate,
    required DateTime endDate,
    String? accountId,
  }) = ParceladoPlanning;

  PlanningType get type => map(
    unique: (_) => PlanningType.unique,
    recurrent: (_) => PlanningType.recurrent,
    parcelado: (_) => PlanningType.parcelado,
  );

  factory PlanningModel.fromJson(Map<String, dynamic> json) => _$PlanningModelFromJson(json);
}
