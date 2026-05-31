import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';

class CategoryService {
  final String workspaceId;
  final ICategoryRepository repository;

  CategoryService({required this.workspaceId, required this.repository});

  Future<CategoryModel> create(CategoryModel category) async {
    return await repository.createCategory(workspaceId, category);
  }

  Future<void> update(CategoryModel category) async {
    await repository.updateCategory(workspaceId, category);
  }

  Future<void> delete(String categoryId) async {
    await repository.deleteCategory(workspaceId, categoryId);
  }

  Stream<List<CategoryModel>> getCategories() {
    return repository.getCategories(workspaceId);
  }
}
