import 'dart:io';

import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';

class AccountService {
  final String workspaceId;
  final IAccountRepository repository;

  AccountService({required this.workspaceId, required this.repository});

  Future<AccountModel> create(AccountModel account) async {
    return await repository.createAccount(workspaceId, account);
  }

  Future<void> update(AccountModel account) async {
    await repository.updateAccount(workspaceId, account);
  }

  Future<void> delete(String accountId) async {
    await repository.deleteAccount(workspaceId, accountId);
  }

  Stream<AccountBalanceModel> getLatestAccountBalance(String accountId) {
    return repository
        .getLatestAccountBalance(workspaceId, accountId)
        .map((balance) => balance ?? AccountBalanceModel.zero());
  }

  Stream<AccountBalanceModel> getAccountBalanceAtDate(String accountId, DateTime date) {
    return repository
        .getAccountBalanceAtDate(workspaceId, accountId, date)
        .map((balance) => balance ?? AccountBalanceModel.zero(date: date));
  }

  Stream<List<AccountModel>> getAccounts() {
    return repository.getAccounts(workspaceId);
  }

  Stream<Map<AccountType, List<AccountModel>>> getAccountsByType() {
    return repository
        .getAccounts(workspaceId)
        .map(
          (accounts) => AccountType.values.asMap().map(
            (_, type) => MapEntry(
              type,
              accounts.where((account) => account.type == type).toList(),
            ),
          ),
        );
  }

  Future<AccountDocumentAnalysisResult> analyzeDocument(File file) async {
    return repository.analyseDocument(workspaceId, file);
  }

  Future<List<ReconciliationTransaction>> analyzeReconciliationDocument(File file) async {
    return repository.analyzeReconciliationDocument(workspaceId, file);
  }
}
