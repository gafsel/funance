import 'package:funances/features/finance/domain/models/automatic_transaction_model.dart';
import 'package:funances/features/finance/domain/repositories/automatic_transaction_repository.dart';

class AutomaticTransactionService {
  final String workspaceId;
  final IAutomaticTransactionRepository repository;

  AutomaticTransactionService({
    required this.workspaceId,
    required this.repository,
  });

  Future<List<AutomaticTransactionModel>> getPendingTransactions() async {
    return repository.getPendingTransactions(workspaceId);
  }

  Future<void> saveTransaction(AutomaticTransactionModel transaction) async {
    return repository.saveTransaction(workspaceId, transaction);
  }

  Future<void> updateTransaction(AutomaticTransactionModel transaction) async {
    return repository.updateTransaction(workspaceId, transaction);
  }

  Future<void> moveTransaction(String toWorkspaceId, AutomaticTransactionModel transaction) async {
    return repository.moveTransaction(workspaceId, toWorkspaceId, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    return repository.deleteTransaction(workspaceId, id);
  }

  Future<bool> existsByNotificationId(String notificationId) async {
    return repository.existsByNotificationId(workspaceId, notificationId);
  }
}
