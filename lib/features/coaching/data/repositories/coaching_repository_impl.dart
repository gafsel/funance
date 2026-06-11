import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/features/coaching/data/models/coaching_mapper.dart';
import '../../domain/models/coaching_model.dart';
import '../../domain/repositories/coaching_repository.dart';

class CoachingRepositoryImpl implements ICoachingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  CollectionReference _getInsightsCollection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('financial_coaching');
  }

  @override
  Future<CoachingModel?> getLastInsight(String workspaceId) async {
    final snapshot = await _getInsightsCollection(
      workspaceId,
    ).orderBy('date', descending: true).limit(1).get();
    return snapshot.docs.map((doc) => doc.toCoachingModel()).firstOrNull;
  }

  @override
  Future<CoachingModel> generateCoaching(String workspaceId) async {
    final callable = _functions.httpsCallable(
      'generateCoaching',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
    );

    final result = await callable.call({'workspaceId': workspaceId});

    final coaching = CoachingModel.fromJson(
      CoachingMapper.fromMap(result.data as Map),
    );

    final data = coaching.toJson();
    data.remove('id');
    data['date'] = Timestamp.fromDate(coaching.date);
    final doc = await _getInsightsCollection(workspaceId).add(data);

    return coaching.copyWith(id: doc.id);
  }
}
