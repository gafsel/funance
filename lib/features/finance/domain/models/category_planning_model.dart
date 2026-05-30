import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'category_planning_model.freezed.dart';

part 'category_planning_model.g.dart';

@freezed
sealed class CategoryPlanningModel with _$CategoryPlanningModel {
  @JsonSerializable(explicitToJson: true)
  const factory CategoryPlanningModel({
    required String id,
    required CategoryModel category,
    required double amount,
    required String startMonth,
    required String endMonth,
  }) = _CategoryPlanningModel;

  factory CategoryPlanningModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryPlanningModelFromJson(json);
}
