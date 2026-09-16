import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/core/utils/date_time_converter.dart';

part 'installment_model.freezed.dart';

part 'installment_model.g.dart';

enum InstallmentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('settled')
  settled,
  @JsonValue('removed')
  removed,
}

enum ReplicationCascade {
  @JsonValue('none')
  none,
  @JsonValue('all')
  all,
  @JsonValue('future')
  future,
}

@freezed
sealed class InstallmentModel with _$InstallmentModel {
  const InstallmentModel._();
  @JsonSerializable(explicitToJson: true)
  const factory InstallmentModel({
    required String id,
    required String orderId,
    required double amount,
    required String description,
    @DateTimeTwelvePmConverter() required DateTime dueDate,
    double? paidAmount,
    @DateTimeTwelvePmNullableConverter() DateTime? paidDate,
    int? installmentNumber,
    int? installmentCount,
    required InstallmentStatus status,
    required OrderType type,
    required InstallmentType installmentType,
    @Default({}) Map<String, AccountImpact> accounts,
    CategoryModel? category,
    ReplicationCascade? replicationCascade,
    double? xp,
    @Default(false) bool isInvoice,
  }) = _InstallmentModel;

  @JsonKey(includeToJson: true)
  List<String> get accountIds => accounts.keys.toList();

  @DateTimeTwelvePmNullableConverter()
  @JsonKey(includeToJson: true)
  DateTime get referenceDate => paidDate ?? dueDate;

  @JsonKey(includeToJson: true)
  double get referenceAmount => paidAmount ?? amount;

  String? get accountIdSource {
    if (type == OrderType.income) {
      return accounts.entries
          .where((entry) => entry.value == AccountImpact.credit)
          .map((entry) => entry.key)
          .firstOrNull;
    } else {
      return accounts.entries
          .where((entry) => entry.value == AccountImpact.debt)
          .map((entry) => entry.key)
          .firstOrNull;
    }
  }

  String? get accountIdTarget {
    if (type == OrderType.transfer) {
      return accounts.entries
          .where((entry) => entry.value == AccountImpact.credit)
          .map((entry) => entry.key)
          .firstOrNull;
    } else {
      return null;
    }
  }

  /// Conta a que a parcela pertence, na ordem em que as telas a resolvem.
  ///
  /// Numa fatura o lado credit é o cartão; depois de paga, `accountIdSource`
  /// passa a ser a conta corrente que pagou, e `accountIdTarget` fica null
  /// (só transferências têm target). O último recurso é a primeira conta
  /// impactada — sem ele a chave da fatura cairia em string vazia e a tela
  /// listaria tudo.
  String? get resolvedAccountId =>
      accountIdTarget ?? accountIdSource ?? accounts.keys.firstOrNull;

  factory InstallmentModel.fromJson(Map<String, dynamic> json) =>
      _$InstallmentModelFromJson(json);
}
