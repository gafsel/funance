import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/model/core_models.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/virtual_category.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';

class FinanceService {
  final String workspaceId;
  final IFinanceRepository repository;
  final IAccountRepository accountRepository;
  final ICategoryRepository categoryRepository;

  FinanceService({
    required this.workspaceId,
    required this.repository,
    required this.accountRepository,
    required this.categoryRepository,
  });

  /// [documentId] força o id do documento; ver
  /// `IFinanceRepository.addOrder`.
  Future<Written<OrderModel>> addOrder(
    OrderModel order, {
    String? documentId,
  }) async {
    final processedOrder = await _processVirtualCategory(order);
    return await repository.addOrder(
      workspaceId,
      processedOrder,
      documentId: documentId,
    );
  }

  Future<WriteOutcome> updateOrder(OrderModel order) async {
    final processedOrder = await _processVirtualCategory(order);
    return await repository.updateOrder(workspaceId, processedOrder);
  }

  Future<WriteOutcome> updateInstallment(InstallmentModel installment) async {
    final processedInstallment = await _processVirtualCategoryInstallment(
      installment,
    );
    return await repository.updateInstallment(
      workspaceId,
      processedInstallment,
    );
  }

  Future<AccountModel> getAccount(String accountId) async {
    return await accountRepository.getAccount(workspaceId, accountId);
  }

  /// Contas do workspace, numa leitura única.
  ///
  /// O formulário de lançamento precisa saber quantas contas existem para
  /// escolher a conta padrão quando só há uma; um stream aberto seria
  /// desperdício para uma pergunta que se responde uma vez.
  Future<List<AccountModel>> getAccounts() async {
    return await accountRepository.getAccounts(workspaceId).first;
  }

  /// Troca a categoria de uma transferência pela contrapartida virtual.
  ///
  /// Eram 118 linhas em três métodos: `_processVirtualCategory` (order),
  /// `_processVirtualCategoryInstallment` (**cópia literal de 44 linhas**, só
  /// trocando o tipo) e `_getVirtualCategoryForAccountType`, com a árvore de
  /// decisão repetida nas duas primeiras. A regra agora mora em
  /// [VirtualCategory.resolve], do lado do modelo, e este método só faz as
  /// duas leituras e aplica.
  Future<CategoryModel?> _virtualCategoryFor({
    required OrderType type,
    required String? accountIdSource,
    required String? accountIdTarget,
  }) async {
    if (type != OrderType.transfer) return null;
    if (accountIdSource == null && accountIdTarget == null) return null;

    Future<AccountType?> typeOf(String? accountId) async {
      if (accountId == null) return null;
      return (await accountRepository.getAccount(workspaceId, accountId)).type;
    }

    final virtual = VirtualCategory.resolve(
      source: await typeOf(accountIdSource),
      target: await typeOf(accountIdTarget),
    );

    if (virtual == null) return null;

    // A categoria virtual é um documento real em
    // `workspaces/{wid}/categories`, semeado pelo servidor: o lançamento
    // guarda uma cópia dela, e não um id solto.
    return categoryRepository.getCategory(workspaceId, virtual.id);
  }

  Future<OrderModel> _processVirtualCategory(OrderModel order) async {
    final virtualCategory = await _virtualCategoryFor(
      type: order.type,
      accountIdSource: order.accountIdSource,
      accountIdTarget: order.accountIdTarget,
    );

    return virtualCategory == null
        ? order
        : order.copyWith(category: virtualCategory);
  }

  Future<InstallmentModel> _processVirtualCategoryInstallment(
    InstallmentModel installment,
  ) async {
    final virtualCategory = await _virtualCategoryFor(
      type: installment.type,
      accountIdSource: installment.accountIdSource,
      accountIdTarget: installment.accountIdTarget,
    );

    return virtualCategory == null
        ? installment
        : installment.copyWith(category: virtualCategory);
  }

  Future<void> cancelInstallment(
    String installmentId, {
    ReplicationCascade replicationCascade = ReplicationCascade.none,
  }) async {
    final installment = await repository.getInstallment(
      workspaceId,
      installmentId,
    );

    await repository.updateInstallment(
      workspaceId,
      installment.copyWith(
        status: InstallmentStatus.removed,
        replicationCascade: replicationCascade,
      ),
    );
  }

  Future<QueryChunk<InstallmentModel>> queryInstallments({
    required int limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    String? description,
    double? minAmount,
    double? maxAmount,
    InstallmentStatus? status,
    bool descending = true,
    dynamic chunkRef,
  }) async {
    return repository.queryInstallments(
      workspaceId,
      limit: limit,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
      description: description,
      minAmount: minAmount,
      maxAmount: maxAmount,
      status: status,
      descending: descending,
      chunkRef: chunkRef,
    );
  }

  /// Leitura dos planejamentos vigentes, usada pelo funil de analytics do
  /// formulário. A ESCRITA não mora aqui: quem grava limite e expectativa é o
  /// `CategoryPlanningService`, que é o caminho único com a regra de
  /// versionamento mensal.
  Future<List<CategoryPlanningModel>> getCategoryPlannings({
    String? startMonth,
    String? endMonth,
  }) async {
    return repository.getCategoryPlannings(
      workspaceId,
      startMonth: startMonth,
      endMonth: endMonth,
    );
  }

  Future<dynamic> getInstallment(String installmentId) async {
    return await repository.getInstallment(workspaceId, installmentId);
  }

  Stream<List<InstallmentModel>> watchInstallments({
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    return repository.watchInstallments(
      workspaceId,
      limit: limit,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
      categoryId: categoryId,
      type: type,
      status: status,
    );
  }

  Stream<InstallmentModel?> watchNextInvoice(String accountId) {
    return repository.watchNextInvoice(workspaceId, accountId);
  }

  Stream<InstallmentModel?> watchInstallment(String installmentId) {
    return repository.watchInstallment(workspaceId, installmentId);
  }

  Stream<double> watchWeeklyXp(int year, int week) {
    return repository.watchWeeklyXp(workspaceId, year, week);
  }
}
