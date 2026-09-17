import 'package:funances/core/firestore/offline_write.dart';

import '../models/category_model.dart';

abstract class ICategoryRepository {
  Stream<List<CategoryModel>> getCategories(String workspaceId);
  Future<Written<CategoryModel>> createCategory(
    String workspaceId,
    CategoryModel category,
  );
  Future<WriteOutcome> updateCategory(
    String workspaceId,
    CategoryModel category,
  );
  Future<void> deleteCategory(String workspaceId, String categoryId);
  Future<CategoryModel> getCategory(String workspaceId, String categoryId);
}
