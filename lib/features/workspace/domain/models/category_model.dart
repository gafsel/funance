import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';

part 'category_model.g.dart';

enum CategoryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
}

enum CategoryAllocation {
  @JsonValue('essential')
  essential,
  @JsonValue('comfort')
  comfort,
  @JsonValue('investment')
  investment;

  double get idealPercentage => switch (this) {
    essential => .5,
    comfort => .3,
    investment => .2,
  };
}

@freezed
sealed class CategoryModel with _$CategoryModel {
  const CategoryModel._();

  const factory CategoryModel({
    required String id,
    required String name,
    required String icon, // Icon name/code
    required String color, // Hex color string
    @Default(CategoryType.expense) CategoryType type,
    @Default(CategoryAllocation.comfort) CategoryAllocation allocation,
    // Categoria criada e mantida pelo backend (ex.: saldo inicial). O usuário
    // não escolhe nem edita; ela só aparece em relatórios/extrato.
    @Default(false) bool isSystem,
    // Exclusão lógica feita pelo backend: some dos seletores, mas continua
    // resolvível por id para nomear lançamentos antigos.
    @Default(false) bool isDeleted,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  /// Categoria SINTÉTICA do agrupamento "Outros": não existe no Firestore, é
  /// montada pela apresentação quando a lista passa de dez linhas. O nome sai
  /// do l10n (ver `CategoryDisplayName.displayName`), não deste modelo.
  static const String othersId = 'others';

  static const String virtualDebtExpenseId = 'virtual_debt_expense';
  static const String virtualDebtIncomeId = 'virtual_debt_income';
  static const String virtualInvestmentExpenseId = 'virtual_investment_expense';
  static const String virtualInvestmentIncomeId = 'virtual_investment_income';

  bool get isVirtual =>
      id == virtualDebtExpenseId ||
      id == virtualDebtIncomeId ||
      id == virtualInvestmentExpenseId ||
      id == virtualInvestmentIncomeId;

  /// Categoria que o usuário pode escolher ou editar num seletor da UI.
  /// Categorias de sistema e excluídas logicamente ficam de fora.
  bool get isSelectable => !isSystem && !isDeleted;
}
