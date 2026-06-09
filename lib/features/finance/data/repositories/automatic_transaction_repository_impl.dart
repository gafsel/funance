import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';

class AutomaticTransactionRepositoryImpl implements IAutomaticTransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getCollection(String workspaceId) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('automatic_transactions');
  }

  @override
  Future<List<AutomaticTransactionModel>> getPendingTransactions(String workspaceId) async {
    final snapshot = await _getCollection(workspaceId)
        .where('isConsolidated', isEqualTo: false)
        .where('isIgnored', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => AutomaticTransactionModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveTransaction(String workspaceId, AutomaticTransactionModel transaction) async {
    await _getCollection(workspaceId).doc(transaction.id).set(transaction.toJson());
  }

  @override
  Future<void> updateTransaction(String workspaceId, AutomaticTransactionModel transaction) async {
    await _getCollection(workspaceId).doc(transaction.id).update(transaction.toJson());
  }

  @override
  Future<void> moveTransaction(String fromWorkspaceId, String toWorkspaceId, AutomaticTransactionModel transaction) async {
    final batch = _firestore.batch();
    
    // Remove do workspace antigo
    batch.delete(_getCollection(fromWorkspaceId).doc(transaction.id));
    
    // Adiciona no novo workspace
    batch.set(_getCollection(toWorkspaceId).doc(transaction.id), transaction.toJson());
    
    await batch.commit();
  }

  @override
  Future<void> deleteTransaction(String workspaceId, String id) async {
    await _getCollection(workspaceId).doc(id).delete();
  }

  @override
  Future<bool> existsByNotificationId(String workspaceId, String notificationId) async {
    final snapshot = await _getCollection(workspaceId)
        .where('originNotificationId', isEqualTo: notificationId)
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }
}
