// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_503020_analysis.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Planning503020AnalysisGroup _$Planning503020AnalysisGroupFromJson(
  Map<String, dynamic> json,
) => _Planning503020AnalysisGroup(
  allocation: $enumDecode(_$CategoryAllocationEnumMap, json['allocation']),
  currentPct: (json['currentPct'] as num?)?.toDouble() ?? 0.0,
  targetPct: (json['targetPct'] as num?)?.toDouble() ?? 0.0,
  deltaBRL: (json['deltaBRL'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$Planning503020AnalysisGroupToJson(
  _Planning503020AnalysisGroup instance,
) => <String, dynamic>{
  'allocation': _$CategoryAllocationEnumMap[instance.allocation]!,
  'currentPct': instance.currentPct,
  'targetPct': instance.targetPct,
  'deltaBRL': instance.deltaBRL,
};

const _$CategoryAllocationEnumMap = {
  CategoryAllocation.essential: 'essential',
  CategoryAllocation.comfort: 'comfort',
  CategoryAllocation.investment: 'investment',
};

_Planning503020AnalysisCategory _$Planning503020AnalysisCategoryFromJson(
  Map<String, dynamic> json,
) => _Planning503020AnalysisCategory(
  categoryId: json['categoryId'] as String,
  categoryName: json['categoryName'] as String? ?? '',
  idealMonthlyAmount: (json['idealMonthlyAmount'] as num?)?.toDouble() ?? 0.0,
  idealPctOfIncome: (json['idealPctOfIncome'] as num?)?.toDouble() ?? 0.0,
  status:
      $enumDecodeNullable(
        _$Planning503020AnalysisStatusEnumMap,
        json['status'],
      ) ??
      Planning503020AnalysisStatus.ok,
  currentAllocation:
      $enumDecodeNullable(
        _$CategoryAllocationEnumMap,
        json['currentAllocation'],
      ) ??
      CategoryAllocation.comfort,
  suggestedAllocation: $enumDecodeNullable(
    _$CategoryAllocationEnumMap,
    json['suggestedAllocation'],
  ),
  shouldReclassify: json['shouldReclassify'] as bool? ?? false,
  reason: json['reason'] as String? ?? '',
  savingTip: json['savingTip'] as String?,
  plannedAmount: (json['plannedAmount'] as num?)?.toDouble() ?? 0.0,
  actualAmount: (json['actualAmount'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$Planning503020AnalysisCategoryToJson(
  _Planning503020AnalysisCategory instance,
) => <String, dynamic>{
  'categoryId': instance.categoryId,
  'categoryName': instance.categoryName,
  'idealMonthlyAmount': instance.idealMonthlyAmount,
  'idealPctOfIncome': instance.idealPctOfIncome,
  'status': _$Planning503020AnalysisStatusEnumMap[instance.status]!,
  'currentAllocation': _$CategoryAllocationEnumMap[instance.currentAllocation]!,
  'suggestedAllocation':
      _$CategoryAllocationEnumMap[instance.suggestedAllocation],
  'shouldReclassify': instance.shouldReclassify,
  'reason': instance.reason,
  'savingTip': instance.savingTip,
  'plannedAmount': instance.plannedAmount,
  'actualAmount': instance.actualAmount,
};

const _$Planning503020AnalysisStatusEnumMap = {
  Planning503020AnalysisStatus.ok: 'ok',
  Planning503020AnalysisStatus.above: 'above',
  Planning503020AnalysisStatus.below: 'below',
};

_Planning503020Analysis _$Planning503020AnalysisFromJson(
  Map<String, dynamic> json,
) => _Planning503020Analysis(
  id: json['id'] as String,
  month: json['month'] as String? ?? '',
  summary: json['summary'] as String? ?? '',
  projectedIncome: (json['projectedIncome'] as num?)?.toDouble() ?? 0.0,
  groups:
      (json['groups'] as List<dynamic>?)
          ?.map(
            (e) =>
                Planning503020AnalysisGroup.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map(
            (e) => Planning503020AnalysisCategory.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList() ??
      const [],
  insights:
      (json['insights'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$Planning503020AnalysisToJson(
  _Planning503020Analysis instance,
) => <String, dynamic>{
  'id': instance.id,
  'month': instance.month,
  'summary': instance.summary,
  'projectedIncome': instance.projectedIncome,
  'groups': instance.groups,
  'categories': instance.categories,
  'insights': instance.insights,
  'createdAt': instance.createdAt?.toIso8601String(),
};
