
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';

import '../models/account_model.dart';

abstract class IAccountRepository {
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  });

  Future<AccountModel> createAccount(String workspaceId, AccountModel account);

  Future<void> updateAccount(String workspaceId, AccountModel account);

  Future<AccountModel> getAccount(String workspaceId, String accountId);

  Future<void> deleteAccount(String workspaceId, String accountId);

  Stream<AccountBalanceModel?> getLatestAccountBalance(
    String workspaceId,
    String accountId,
  );

  Stream<AccountBalanceModel?> getLatestAccountBalanceBeforeDate(
    String workspaceId,
    String accountId,
    DateTime date,
  );

  // Anexos e Processamento
  Future<String> uploadAccountFile(
    String workspaceId,
    String accountId,
    PickedDocument document,
  );

  Future<AccountDocumentAnalysisResult> analyseDocument(
    String workspaceId,
    PickedDocument document,
  );

  Future<List<ReconciliationTransaction>> analyzeReconciliationDocument(
    String workspaceId,
    PickedDocument document, {
    String? uploadId,
  });
}
