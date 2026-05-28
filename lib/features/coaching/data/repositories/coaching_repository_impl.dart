import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/coaching/data/models/coaching_mapper.dart';
import '../../domain/models/coaching_model.dart';
import '../../domain/models/hack_model.dart';
import '../../domain/repositories/coaching_repository.dart';

class CoachingRepositoryImpl implements ICoachingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getInsightsCollection(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId).collection('financial_coaching');
  }

  CollectionReference _getHacksCollection(String workspaceId) {
    return _firestore.collection('workspaces').doc(workspaceId).collection('finance_hacks');
  }

  @override
  Future<List<CoachingModel>> getInsights(String workspaceId) async {
    final snapshot = await _getInsightsCollection(workspaceId).orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => doc.toCoachingModel()).toList();
  }

  @override
  Future<void> addInsight(String workspaceId, CoachingModel insight) async {
    final data = insight.toJson();
    data.remove('id');
    data['date'] = Timestamp.fromDate(insight.date);
    await _getInsightsCollection(workspaceId).add(data);
  }

  @override
  Future<List<HackModel>> getFinanceHacks(String workspaceId) async {
    final snapshot = await _getHacksCollection(workspaceId).get();
    return snapshot.docs.map((doc) => doc.toHackModel()).toList();
  }
}
