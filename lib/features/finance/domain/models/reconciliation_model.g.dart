// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reconciliation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReconciliationTransaction _$ReconciliationTransactionFromJson(
  Map<String, dynamic> json,
) => _ReconciliationTransaction(
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  date: const DateTimeTwelvePmConverter().fromJson(json['date'] as String),
  type: $enumDecode(_$OrderTypeEnumMap, json['type']),
  category: json['category'] == null
      ? null
      : CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReconciliationTransactionToJson(
  _ReconciliationTransaction instance,
) => <String, dynamic>{
  'description': instance.description,
  'amount': instance.amount,
  'date': const DateTimeTwelvePmConverter().toJson(instance.date),
  'type': _$OrderTypeEnumMap[instance.type]!,
  'category': instance.category?.toJson(),
};

const _$OrderTypeEnumMap = {
  OrderType.expense: 'expense',
  OrderType.income: 'income',
  OrderType.transfer: 'transfer',
};

_UploadProgressModel _$UploadProgressModelFromJson(Map<String, dynamic> json) =>
    _UploadProgressModel(
      status: $enumDecode(_$UploadStatusEnumMap, json['status']),
      progress: (json['progress'] as num).toDouble(),
      message: json['message'] as String,
    );

Map<String, dynamic> _$UploadProgressModelToJson(
  _UploadProgressModel instance,
) => <String, dynamic>{
  'status': _$UploadStatusEnumMap[instance.status]!,
  'progress': instance.progress,
  'message': instance.message,
};

const _$UploadStatusEnumMap = {
  UploadStatus.reading: 'reading',
  UploadStatus.extracting: 'extracting',
  UploadStatus.searching: 'searching',
  UploadStatus.preparing: 'preparing',
  UploadStatus.completed: 'completed',
  UploadStatus.error: 'error',
};
