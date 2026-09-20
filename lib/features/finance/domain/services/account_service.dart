import 'package:funances/core/files/picked_document.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';

class AccountService {
  final String workspaceId;
  final IAccountRepository repository;
  final IWorkspaceRepository workspaceRepository;

  /// O relógio do app. Ele entra aqui por causa de [getLatestAccountBalance]:
  /// "saldo atual" é uma pergunta sobre HOJE, e sem relógio injetado ela não
  /// tem teste.
  final Clock now;

  AccountService({
    required this.workspaceId,
    required this.repository,
    required this.workspaceRepository,
    this.now = DateTime.now,
  });

  Future<List<UserModel>> getWorkspaceMembers() async {
    return workspaceRepository.getWorkspaceMembers(workspaceId);
  }

  Future<Written<AccountModel>> create(AccountModel account) async {
    return await repository.createAccount(workspaceId, account);
  }

  Future<WriteOutcome> update(AccountModel account) async {
    return await repository.updateAccount(workspaceId, account);
  }

  Future<void> delete(String accountId) async {
    await repository.deleteAccount(workspaceId, accountId);
  }

  /// O saldo ATUAL: o último documento de `balance` com data **até hoje**.
  ///
  /// "Último documento", sem mais nada, estava errado — e o erro é invisível
  /// até alguém agendar um pagamento. Um lançamento marcado para sexta faz o
  /// servidor gravar o saldo projetado de SEXTA, e esse documento ordena
  /// depois do de hoje: a conta passava a mostrar, como saldo atual, um
  /// dinheiro que ainda não saiu. Na Arena isso aparecia como o herói já
  /// ferido no domingo.
  ///
  /// Vale para o app inteiro, e não só para a Arena: quem pergunta "quanto eu
  /// tenho" nunca quer a resposta de sexta-feira.
  Stream<AccountBalanceModel> getLatestAccountBalance(String accountId) {
    return getAccountBalanceAtDate(accountId, now());
  }

  Stream<AccountBalanceModel> getAccountBalanceAtDate(
    String accountId,
    DateTime date,
  ) {
    return repository
        .getLatestAccountBalanceBeforeDate(workspaceId, accountId, date)
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

  Future<AccountDocumentAnalysisResult> analyzeDocument(
    PickedDocument document,
  ) async {
    return repository.analyseDocument(workspaceId, document);
  }

  Future<List<ReconciliationTransaction>> analyzeReconciliationDocument(
    PickedDocument document, {
    String? uploadId,
  }) async {
    return repository.analyzeReconciliationDocument(
      workspaceId,
      document,
      uploadId: uploadId,
    );
  }
}
