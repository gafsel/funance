import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';

extension CategoryPlanningFirestoreX on DocumentSnapshot {
  CategoryPlanningModel toCategoryPlanningModel() {
    final data = this.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('CategoryPlanning data is null');

    return CategoryPlanningModel.fromJson({
      ...data,
      'id': id,
    });
  }
}
