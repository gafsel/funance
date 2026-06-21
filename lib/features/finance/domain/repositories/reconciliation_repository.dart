import 'package:funances/features/finance/domain/models/reconciliation_model.dart';

abstract class IReconciliationRepository {
  Future<void> saveUploadProgress(
    String workspaceId,
    String uploadId,
    UploadProgressModel progress,
  );

  Stream<UploadProgressModel?> watchUploadProgress(
    String workspaceId,
    String uploadId,
  );

  Future<void> saveReconciliationSummary(
    String workspaceId,
    String recId, {
    required int confirmedMatchesCount,
    required int totalTransactionsProcessed,
    required int createdTransactionsCount,
  });
}
