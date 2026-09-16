import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_model.freezed.dart';

part 'order_model.g.dart';

enum OrderStatus {
  @JsonValue('active')
  active,
  @JsonValue('cancelled')
  cancelled,
  // O servidor grava `settled` em orders que já nasceram concluídas (ex.: a
  // order de saldo inicial). Sem este valor o $enumDecode gerado lançava
  // ArgumentError ao ler o documento.
  @JsonValue('settled')
  settled;

  /// Uma order concluída ou cancelada não é mais editável pelo usuário.
  bool get isEditable => this == OrderStatus.active;
}

enum OrderType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
  @JsonValue('transfer')
  transfer;

  CategoryType get categoryType {
    if (this == income) {
      return CategoryType.income;
    }

    return CategoryType.expense;
  }
}

enum AccountImpact {
  @JsonValue('debt')
  debt,
  @JsonValue('credit')
  credit,
}

enum InstallmentType {
  @JsonValue('single')
  single,
  @JsonValue('installment')
  installment,
  @JsonValue('recurring')
  recurring,
}

@freezed
sealed class OrderModel with _$OrderModel {
  const OrderModel._();

  @JsonSerializable(explicitToJson: true)
  const factory OrderModel({
    required String id,
    required double amount,
    required String description,
    required int dueDay,
    required String startMonth,
    int? installmentCount,
    required InstallmentType installmentType,
    required OrderStatus status,
    required OrderType type,
    InstallmentStatus? installmentCreationStatus,
    Map<String, AccountImpact>? accounts,
    CategoryModel? category,
    @Default(false) bool isInvoice,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);

  DateTime get firstDueDate {
    final parts = startMonth.split(RegExp("-"));
    return DateTime(int.parse(parts.first), int.parse(parts.last), dueDay);
  }

  String? get accountIdSource {
    if (type == OrderType.income) {
      return accounts?.entries
          .where((entry) => entry.value == AccountImpact.credit)
          .map((entry) => entry.key)
          .firstOrNull;
    } else {
      return accounts?.entries
          .where((entry) => entry.value == AccountImpact.debt)
          .map((entry) => entry.key)
          .firstOrNull;
    }
  }

  String? get accountIdTarget {
    if (type == OrderType.transfer) {
      return accounts?.entries
          .where((entry) => entry.value == AccountImpact.credit)
          .map((entry) => entry.key)
          .firstOrNull;
    } else {
      return null;
    }
  }
}
