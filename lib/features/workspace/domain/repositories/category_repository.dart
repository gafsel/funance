import '../models/category_model.dart';

abstract class ICategoryRepository {
  Stream<List<CategoryModel>> getCategories(String workspaceId);
  Future<void> createCategory(String workspaceId, CategoryModel category);
  Future<void> updateCategory(String workspaceId, CategoryModel category);
  Future<void> deleteCategory(String workspaceId, String categoryId);
}
