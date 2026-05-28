import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'account_model.g.dart';

enum AccountType {
  @JsonValue('checking')
  checking,
  @JsonValue('investment')
  investment,
  @JsonValue('credit_card')
  creditCard,
  @JsonValue('debt')
  debt,
}

enum AccountProcessingStatus {
  @JsonValue('none')
  none,
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class AccountModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final AccountType type;
  final Map<String, dynamic> metadata;
  final bool isDeleted;
  @JsonKey(name: 'initial_balance')
  final double initialBalance;
  @JsonKey(name: 'initial_balance_date')
  final DateTime initialBalanceDate;
  @JsonKey(name: 'file_path')
  final String? filePath;
  @JsonKey(name: 'file_name')
  final String? fileName;
  @JsonKey(name: 'processing_status')
  final AccountProcessingStatus processingStatus;

  AccountModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.metadata = const {},
    this.isDeleted = false,
    this.initialBalance = 0.0,
    required this.initialBalanceDate,
    this.filePath,
    this.fileName,
    this.processingStatus = AccountProcessingStatus.none,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => _$AccountModelFromJson(json);
  Map<String, dynamic> toJson() => _$AccountModelToJson(this);

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Account data is null');

    return AccountModel.fromJson({
      'type': 'checking',
      'isDeleted': false,
      ...data,
      'id': doc.id,
      'initial_balance': (data['initial_balance'] ?? data['initialBalance'] ?? 0.0).toDouble(),
      'initial_balance_date': (data['initial_balance_date'] as Timestamp? ?? data['initialBalanceDate'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
      'processing_status': data['processing_status'] ?? data['processingStatus'] ?? 'none',
      'file_path': data['file_path'] ?? data['filePath'],
      'file_name': data['file_name'] ?? data['fileName'],
    });
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    AccountType? type,
    Map<String, dynamic>? metadata,
    bool? isDeleted,
    double? initialBalance,
    DateTime? initialBalanceDate,
    String? filePath,
    String? fileName,
    AccountProcessingStatus? processingStatus,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      isDeleted: isDeleted ?? this.isDeleted,
      initialBalance: initialBalance ?? this.initialBalance,
      initialBalanceDate: initialBalanceDate ?? this.initialBalanceDate,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      processingStatus: processingStatus ?? this.processingStatus,
    );
  }
}

@JsonSerializable()
class AccountBalanceModel {
  final String id; // Date string YYYY-MM-DD
  final double balance;
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;

  AccountBalanceModel({
    required this.id,
    required this.balance,
    required this.updatedAt,
  });

  factory AccountBalanceModel.zero() => AccountBalanceModel(id: "", balance: 0, updatedAt: DateTime.now());

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) => _$AccountBalanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$AccountBalanceModelToJson(this);

  factory AccountBalanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('AccountBalance data is null');

    return AccountBalanceModel.fromJson({
      ...data,
      'id': doc.id,
      'updatedAt': (data['updatedAt'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
    });
  }
}
