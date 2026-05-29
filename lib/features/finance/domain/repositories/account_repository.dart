import 'dart:io';

import '../models/account_model.dart';

abstract class IAccountRepository {
  Stream<List<AccountModel>> getAccounts(
    String workspaceId, {
    AccountType? type,
  });

  Future<void> createAccount(String workspaceId, AccountModel account);

  Future<void> updateAccount(String workspaceId, AccountModel account);

  Future<void> deleteAccount(String workspaceId, String accountId);

  Stream<AccountBalanceModel?> getLatestAccountBalance(
    String workspaceId,
    String accountId,
  );

  // Anexos e Processamento
  Future<String> uploadAccountFile(
    String workspaceId,
    String accountId,
    File file,
  );

  Future<AccountDocumentAnalysisResult> analyseDocument(
    String workspaceId,
    File file,
  );
}
