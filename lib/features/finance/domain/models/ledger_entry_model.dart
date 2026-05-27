import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ledger_entry_model.g.dart';

enum LedgerEntryStatus {
  @JsonValue('forecast')
  forecast,
  @JsonValue('cleared')
  cleared,
}

enum LedgerEntryType {
  @JsonValue('debit')
  debit,
  @JsonValue('credit')
  credit,
}

@JsonSerializable()
class LedgerEntryModel {
  final String id;
  @JsonKey(name: 'order_id')
  final String? orderId;
  final String category;
  final double amount;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  final LedgerEntryStatus status;
  final LedgerEntryType type;
  @JsonKey(name: 'account_id')
  final String? accountId;
  @JsonKey(name: 'is_deductible')
  final bool isDeductible;

  LedgerEntryModel({
    required this.id,
    this.orderId,
    required this.category,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.type,
    this.accountId,
    this.isDeductible = false,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) => _$LedgerEntryModelFromJson(json);
  Map<String, dynamic> toJson() => _$LedgerEntryModelToJson(this);

  factory LedgerEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('LedgerEntry data is null');

    return LedgerEntryModel.fromJson({
      'status': 'cleared',
      'type': 'debit',
      ...data,
      'id': doc.id,
      'order_id': data['order_id'] ?? data['orderId'],
      'account_id': data['account_id'] ?? data['accountId'],
      'planning_id': data['planning_id'] ?? data['planningId'],
      'due_date': (data['due_date'] as Timestamp? ?? data['dueDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
