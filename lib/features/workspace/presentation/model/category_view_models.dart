import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:uuid/uuid.dart';

part 'category_view_models.freezed.dart';

@freezed
sealed class CategoryFormState with _$CategoryFormState {
  const CategoryFormState._();

  const factory CategoryFormState({
    required CategoryModel? category,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) = _CategoryFormState;

  factory CategoryFormState.initial(CategoryModel? category) {
    return CategoryFormState(
      category: category,
      name: category?.name ?? '',
      type: category?.type ?? CategoryType.expense,
      color: category?.color ?? '#4A8C9C',
      icon: category?.icon ?? 'category',
    );
  }

  bool get creation => category == null;

  CategoryModel asModel() {
    if (category != null) {
      return category!.copyWith(
        name: name,
        color: color,
        icon: icon,
      );
    }

    return CategoryModel(
      id: Uuid().v4(),
      name: name,
      icon: icon,
      color: color,
      type: type,
    );
  }
}
