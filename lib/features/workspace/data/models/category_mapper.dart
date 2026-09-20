import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

extension CategoryFirestoreX on DocumentSnapshot {
  CategoryModel toCategoryModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Category data is null');

    return CategoryModel.fromJson({...data, 'id': id});
  }
}
