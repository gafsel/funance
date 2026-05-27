import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import 'workspace_providers.dart';

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;

  if (workspace == null) {
    return Stream.value([]);
  }

  return repository.getCategories(workspace.id);
});

class CategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final ICategoryRepository _repository;
  final String? _workspaceId;

  CategoryNotifier(this._repository, this._workspaceId) : super(const AsyncValue.data(null));

  Future<void> createCategory(CategoryModel category) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.createCategory(_workspaceId!, category));
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateCategory(_workspaceId!, category));
  }

  Future<void> deleteCategory(String categoryId) async {
    if (_workspaceId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteCategory(_workspaceId!, categoryId));
  }
}

final categoryNotifierProvider = StateNotifierProvider<CategoryNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final workspaceId = ref.watch(workspaceNotifierProvider).currentWorkspace?.id;
  return CategoryNotifier(repository, workspaceId);
});
