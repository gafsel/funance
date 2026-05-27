import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId).collection('categories');
  }

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    return _getCollection(workspaceId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> createCategory(String workspaceId, CategoryModel category) async {
    final data = category.toJson();
    data.remove('id');
    await _getCollection(workspaceId).add(data);
  }

  @override
  Future<void> updateCategory(String workspaceId, CategoryModel category) async {
    final data = category.toJson();
    data.remove('id');
    await _getCollection(workspaceId).doc(category.id).update(data);
  }

  @override
  Future<void> deleteCategory(String workspaceId, String categoryId) async {
    await _getCollection(workspaceId).doc(categoryId).delete();
  }
}
