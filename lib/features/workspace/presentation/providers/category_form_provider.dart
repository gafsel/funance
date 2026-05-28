import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:uuid/uuid.dart';

class CategoryFormState {
  final String name;
  final CategoryType type;
  final String color;
  final String icon;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  CategoryFormState({
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  factory CategoryFormState.initial(CategoryModel? category) {
    return CategoryFormState(
      name: category?.name ?? '',
      type: category?.type ?? CategoryType.expense,
      color: category?.color ?? '#4A8C9C',
      icon: category?.icon ?? 'category',
    );
  }

  CategoryFormState copyWith({
    String? name,
    CategoryType? type,
    String? color,
    String? icon,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return CategoryFormState(
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

class CategoryFormNotifier extends StateNotifier<CategoryFormState> {
  final Ref ref;
  final CategoryModel? initialCategory;

  CategoryFormNotifier(this.ref, this.initialCategory)
      : super(CategoryFormState.initial(initialCategory));

  void updateName(String value) => state = state.copyWith(name: value);
  void updateType(CategoryType value) => state = state.copyWith(type: value);
  void updateColor(String value) => state = state.copyWith(color: value);
  void updateIcon(String value) => state = state.copyWith(icon: value);

  Future<void> submit() async {
    if (state.name.isEmpty) {
      state = state.copyWith(errorMessage: 'Name is required');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final category = CategoryModel(
      id: initialCategory?.id ?? const Uuid().v4(),
      name: state.name,
      icon: state.icon,
      color: state.color,
      type: state.type,
    );

    try {
      if (initialCategory == null) {
        await ref.read(categoryNotifierProvider.notifier).createCategory(category);
      } else {
        await ref.read(categoryNotifierProvider.notifier).updateCategory(category);
      }
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final categoryFormProvider = StateNotifierProvider.family<CategoryFormNotifier, CategoryFormState, CategoryModel?>((ref, category) {
  return CategoryFormNotifier(ref, category);
});
