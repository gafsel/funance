import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';

abstract class IAutomaticTransactionRepository {
  Future<List<AutomaticTransactionModel>> getPendingTransactions(String workspaceId);
  Future<void> saveTransaction(String workspaceId, AutomaticTransactionModel transaction);
  Future<void> updateTransaction(String workspaceId, AutomaticTransactionModel transaction);
  Future<void> moveTransaction(String fromWorkspaceId, String toWorkspaceId, AutomaticTransactionModel transaction);
  Future<void> deleteTransaction(String workspaceId, String id);
  Future<bool> existsByNotificationId(String workspaceId, String notificationId);
}
