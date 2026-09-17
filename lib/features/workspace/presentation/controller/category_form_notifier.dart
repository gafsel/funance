import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/form/form_notifier.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';

class CategoryFormNotifier extends FormNotifier<CategoryFormState, void>
    with TracksWriteOutcome {
  final CategoryService service;

  CategoryFormNotifier({required this.service, CategoryModel? initialCategory})
    : super(CategoryFormState.initial(initialCategory));

  void updateName(String value) => state = state.copyWith(name: value);

  void updateType(CategoryType value) => state = state.copyWith(type: value);

  void updateColor(String value) => state = state.copyWith(color: value);

  void updateIcon(String value) => state = state.copyWith(icon: value);

  @override
  Future<void> submit() async {
    beginWrite();

    var category = state.asModel();

    if (state.creation) {
      final created = await service.create(category);

      category = created.value;
      recordWrite(created.outcome);

      state = state.copyWith(category: category);
    } else {
      recordWrite(await service.update(category));
    }
  }
}
