import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';

class ReconciliationRepositoryImpl implements IReconciliationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> saveUploadProgress(
    String workspaceId,
    String uploadId,
    UploadProgressModel progress,
  ) async {
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('uploads')
        .doc(uploadId)
        .set(progress.toJson(), SetOptions(merge: true));
  }

  @override
  Stream<UploadProgressModel?> watchUploadProgress(
    String workspaceId,
    String uploadId,
  ) {
    return _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('uploads')
        .doc(uploadId)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          if (data == null) return null;
          return UploadProgressModel.fromJson(data);
        });
  }

  @override
  Future<void> saveReconciliationSummary(
    String workspaceId,
    String recId, {
    required int confirmedMatchesCount,
    required int totalTransactionsProcessed,
    required int createdTransactionsCount,
  }) async {
    await _firestore
        .collection('workspaces')
        .doc(workspaceId)
        .collection('reconciliations')
        .doc(recId)
        .set({
      'id': recId,
      'status': 'completed',
      'confirmedMatchesCount': confirmedMatchesCount,
      'totalTransactionsProcessed': totalTransactionsProcessed,
      'createdTransactionsCount': createdTransactionsCount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
