import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:uuid/uuid.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class CategoryFormNotifier extends FormNotifier<CategoryFormState, void> {
  final CategoryService service;

  CategoryFormNotifier({required this.service, CategoryModel? initialCategory})
    : super(CategoryFormState.initial(initialCategory));

  void updateName(String value) => state = state.copyWith(name: value);

  void updateType(CategoryType value) => state = state.copyWith(type: value);

  void updateColor(String value) => state = state.copyWith(color: value);

  void updateIcon(String value) => state = state.copyWith(icon: value);

  @override
  Future<void> submit() async {
    final category = state.asModel();

    if (state.creation) {
      await service.create(category);

      state = state.copyWith(category: category);
    } else {
      await service.update(category);
    }
  }
}
