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
    // Quando o servidor gerou esta análise (ISO-8601). Análises antigas,
    // persistidas antes deste campo existir, vêm nulas.
    DateTime? createdAt,
  }) = _Planning503020Analysis;

  factory Planning503020Analysis.fromJson(Map<String, dynamic> json) =>
      _$Planning503020AnalysisFromJson(json);

  List<Planning503020AnalysisCategory> get reclassifications =>
      categories.where((c) => c.shouldReclassify).toList();

  /// O servidor reaproveita uma análise por [cacheMaxAgeDays] dias antes de
  /// gastar cota de IA gerando outra.
  static const int cacheMaxAgeDays = 3;

  /// Idade da análise em dias completos. Nulo quando não sabemos a data.
  int? get ageInDays {
    final generatedAt = createdAt;
    if (generatedAt == null) return null;

    final days = DateTime.now().difference(generatedAt).inDays;
    return days < 0 ? 0 : days;
  }

  /// Quantos dias faltam até o servidor aceitar gerar uma análise nova.
  int get daysUntilRenewal {
    final age = ageInDays;
    if (age == null) return 0;

    final remaining = cacheMaxAgeDays - age;
    return remaining < 0 ? 0 : remaining;
  }

  /// Sem data conhecida assumimos que dá para tentar: quem decide é o servidor.
  bool get canRegenerate => daysUntilRenewal == 0;
}
