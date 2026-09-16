import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

part 'planning_503020_analysis.freezed.dart';

part 'planning_503020_analysis.g.dart';

enum Planning503020AnalysisStatus {
  @JsonValue('ok')
  ok,
  @JsonValue('above')
  above,
  @JsonValue('below')
  below,
}

@freezed
sealed class Planning503020AnalysisGroup with _$Planning503020AnalysisGroup {
  const factory Planning503020AnalysisGroup({
    required CategoryAllocation allocation,
    @Default(0.0) double currentPct,
    @Default(0.0) double targetPct,
    @Default(0.0) double deltaBRL,
  }) = _Planning503020AnalysisGroup;

  factory Planning503020AnalysisGroup.fromJson(Map<String, dynamic> json) =>
      _$Planning503020AnalysisGroupFromJson(json);
}

@freezed
sealed class Planning503020AnalysisCategory
    with _$Planning503020AnalysisCategory {
  const Planning503020AnalysisCategory._();

  const factory Planning503020AnalysisCategory({
    required String categoryId,
    @Default('') String categoryName,
    @Default(0.0) double idealMonthlyAmount,
    @Default(0.0) double idealPctOfIncome,
    @Default(Planning503020AnalysisStatus.ok)
    Planning503020AnalysisStatus status,
    @Default(CategoryAllocation.comfort) CategoryAllocation currentAllocation,
    CategoryAllocation? suggestedAllocation,
    @Default(false) bool shouldReclassify,
    @Default('') String reason,
    String? savingTip,
    @Default(0.0) double plannedAmount,
    @Default(0.0) double actualAmount,
  }) = _Planning503020AnalysisCategory;

  factory Planning503020AnalysisCategory.fromJson(Map<String, dynamic> json) =>
      _$Planning503020AnalysisCategoryFromJson(json);
}

@freezed
sealed class Planning503020Analysis with _$Planning503020Analysis {
  const Planning503020Analysis._();

  const factory Planning503020Analysis({
    required String id,
    @Default('') String month,
    @Default('') String summary,
    @Default(0.0) double projectedIncome,
    @Default([]) List<Planning503020AnalysisGroup> groups,
    @Default([]) List<Planning503020AnalysisCategory> categories,
    @Default([]) List<String> insights,
  }) = _Planning503020Analysis;

  factory Planning503020Analysis.fromJson(Map<String, dynamic> json) =>
      _$Planning503020AnalysisFromJson(json);

  List<Planning503020AnalysisCategory> get reclassifications =>
      categories.where((c) => c.shouldReclassify).toList();
}
