import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

enum CategoryType {
  @JsonValue('income')
  income,
  @JsonValue('expense')
  expense,
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
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) => _$CategoryModelFromJson(json);

}
