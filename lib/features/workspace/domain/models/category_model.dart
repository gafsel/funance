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
  investment,
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
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

  static const String virtualDebtExpenseId = 'virtual_debt_expense';
  static const String virtualDebtIncomeId = 'virtual_debt_income';
  static const String virtualInvestmentExpenseId = 'virtual_investment_expense';
  static const String virtualInvestmentIncomeId = 'virtual_investment_income';

  bool get isVirtual =>
      id == virtualDebtExpenseId ||
      id == virtualDebtIncomeId ||
      id == virtualInvestmentExpenseId ||
      id == virtualInvestmentIncomeId;
}
