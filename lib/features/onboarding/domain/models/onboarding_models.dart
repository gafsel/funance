import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';

part 'onboarding_models.g.dart';
part 'onboarding_models.freezed.dart';

@freezed
sealed class PlanningSuggestions with _$PlanningSuggestions {
  factory PlanningSuggestions({
    @Default([]) List<CategoryPlanningModel> plannings,
    @Default([]) List<GoalModel> goals,
  }) = _PlanningSuggestions;

  factory PlanningSuggestions.fromJson(Map<String, dynamic> json) =>
      _$PlanningSuggestionsFromJson(json);
}
