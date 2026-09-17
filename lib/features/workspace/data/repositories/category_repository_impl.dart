import 'package:funances/core/firestore/offline_write.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/workspace/data/models/category_mapper.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('categories');
  }

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    return _getCollection(workspaceId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.toCategoryModel()).toList()..sort(
        (c1, c2) => c1.name.toLowerCase().compareTo(c2.name.toLowerCase()),
      );
    });
  }

  @override
  Future<CategoryModel> getCategory(String workspaceId, String id) async {
    final snap = await _getCollection(workspaceId).doc(id).get();
    return snap.toCategoryModel();
  }

  @override
  Future<CategoryModel> createCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    try {
      final data = category.toJson();
      data.remove('id');
      // `doc()` gera o id localmente; o `add()` que havia aqui só
      // devolvia a referência depois da resposta do servidor, e offline
      // isso nunca chegava.
      final doc = _getCollection(workspaceId).doc();
      await settleWrite(doc.set(data));

      return category.copyWith(id: doc.id);
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> updateCategory(
    String workspaceId,
    CategoryModel category,
  ) async {
    try {
      final data = category.toJson();
      data.remove('id');
      await settleWrite(_getCollection(workspaceId).doc(category.id).update(data));
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> deleteCategory(String workspaceId, String categoryId) async {
    try {
      await settleWrite(_getCollection(workspaceId).doc(categoryId).delete());
    } catch (e, s) {
      throw BusinessException(
        ErrorCode.unknown,
        originalError: e,
        stackTrace: s,
      );
    }
  }
}
