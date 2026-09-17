import 'package:funances/core/files/picked_document.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/repositories/reconciliation_repository.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';
import 'finance_service.dart';

class ReconciliationService {
  final String workspaceId;
  final IReconciliationRepository repository;
  final AccountService accountService;
  final FinanceService financeService;
  final CategoryService categoryService;

  ReconciliationService({
    required this.workspaceId,
    required this.repository,
    required this.accountService,
    required this.financeService,
    required this.categoryService,
  });

  Stream<UploadProgressModel?> watchUploadProgress(String uploadId) {
    return repository.watchUploadProgress(workspaceId, uploadId);
  }

  String _removeDiacritics(String str) {
    final withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    final withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  bool _compareCategoryNames(String name1, String name2) {
    final norm1 = _removeDiacritics(name1.toLowerCase().trim());
    final norm2 = _removeDiacritics(name2.toLowerCase().trim());
    return norm1 == norm2;
  }

  void _sortMatches(List<ReconciliationMatch> matches) {
    matches.sort((a, b) {
      final dateA =
          a.documentTransaction?.date ??
          a.systemInstallment?.referenceDate ??
          DateTime.now();
      final dateB =
          b.documentTransaction?.date ??
          b.systemInstallment?.referenceDate ??
          DateTime.now();
      return dateA.compareTo(dateB);
    });
  }

  List<ReconciliationMatch> _matchTransactions(
    List<ReconciliationTransaction> docTransactions,
    List<InstallmentModel> systemInstallments,
  ) {
    final List<ReconciliationMatch> matches = [];
    final List<InstallmentModel> availableInstallments = List.from(
      systemInstallments,
    );

    for (final docTx in docTransactions) {
      // Tentar encontrar uma correspondência exata (data e valor)
      InstallmentModel? match = availableInstallments.where((inst) {
        final dateDiff = inst.referenceDate.difference(docTx.date).inDays.abs();
        return dateDiff <= 1 &&
            (inst.referenceAmount - docTx.amount).abs() < 0.01;
      }).firstOrNull;

      if (match != null) {
        availableInstallments.remove(match);
        matches.add(
          ReconciliationMatch(
            documentTransaction: docTx,
            systemInstallment: match,
            status: ReconciliationMatchStatus.matched,
          ),
        );
      } else {
        // Tentar encontrar uma correspondência aproximada (apenas valor num range de 7 dias)
        match = availableInstallments.where((inst) {
          final dateDiff = inst.referenceDate
              .difference(docTx.date)
              .inDays
              .abs();
          return dateDiff <= 7 &&
              (inst.referenceAmount - docTx.amount).abs() < 0.01;
        }).firstOrNull;

        if (match != null) {
          availableInstallments.remove(match);
          matches.add(
            ReconciliationMatch(
              documentTransaction: docTx,
              systemInstallment: match,
              status: ReconciliationMatchStatus.suggested,
            ),
          );
        } else {
          matches.add(
            ReconciliationMatch(
              documentTransaction: docTx,
              status: ReconciliationMatchStatus.unmatched,
            ),
          );
        }
      }
    }

    // Adicionar as transações do sistema que não foram vinculadas
    for (final inst in availableInstallments) {
      matches.add(
        ReconciliationMatch(
          systemInstallment: inst,
          status: ReconciliationMatchStatus.unmatched,
        ),
      );
    }

    _sortMatches(matches);

    return matches;
  }

  Future<List<ReconciliationMatch>> loadMatchesForDocument({
    required PickedDocument document,
    required String accountId,
    String? uploadId,
  }) async {
    if (uploadId != null) {
      await repository.saveUploadProgress(
        workspaceId,
        uploadId,
        UploadProgressModel(
          status: UploadStatus.reading,
          progress: 0.25,
          message: '[Fase 1/4] 📄 Lendo o arquivo do extrato...',
        ),
      );
    }

    final transactions = await accountService.analyzeReconciliationDocument(
      document,
      uploadId: uploadId,
    );

    if (uploadId != null) {
      await repository.saveUploadProgress(
        workspaceId,
        uploadId,
        UploadProgressModel(
          status: UploadStatus.searching,
          progress: 0.75,
          message: '[Fase 3/4] 🧠 Buscando parcelas e projeções no sistema...',
        ),
      );
    }

    final categories = await categoryService.getCategories().first;

    // Mapear categorias sugeridas pela IA com as categorias reais locais
    final mappedTransactions = transactions.map((tx) {
      if (tx.category == null) return tx;

      final matchedCategory = categories
          .where(
            (c) =>
                c.type == tx.category!.type &&
                _compareCategoryNames(c.name, tx.category!.name),
          )
          .firstOrNull;

      if (matchedCategory != null) {
        return tx.copyWith(category: matchedCategory);
      }
      return tx;
    }).toList();

    if (mappedTransactions.isEmpty) {
      if (uploadId != null) {
        await repository.saveUploadProgress(
          workspaceId,
          uploadId,
          UploadProgressModel(
            status: UploadStatus.completed,
            progress: 1.00,
            message: '[Fase 4/4] ⚡ Preparando sugestões de conciliação...',
          ),
        );
      }
      return [];
    }

    final dates = mappedTransactions.map((t) => t.date).toList();
    dates.sort();
    final startDate = dates.first.subtract(const Duration(days: 7));
    final endDate = dates.last.add(const Duration(days: 7));

    final systemInstallmentsChunk = await financeService.queryInstallments(
      limit: 1000,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );

    final systemInstallments = systemInstallmentsChunk.items;

    if (uploadId != null) {
      await repository.saveUploadProgress(
        workspaceId,
        uploadId,
        UploadProgressModel(
          status: UploadStatus.preparing,
          progress: 0.90,
          message: '[Fase 4/4] ⚡ Preparando sugestões de conciliação...',
        ),
      );
    }

    final matches = _matchTransactions(mappedTransactions, systemInstallments);

    if (uploadId != null) {
      await repository.saveUploadProgress(
        workspaceId,
        uploadId,
        UploadProgressModel(
          status: UploadStatus.completed,
          progress: 1.00,
          message: '[Fase 4/4] ⚡ Preparando sugestões de conciliação...',
        ),
      );
    }

    return matches;
  }

  Future<void> confirmReconciliation({
    required AccountModel selectedAccount,
    required List<ReconciliationMatch> matches,
  }) async {
    final categories = await categoryService.getCategories().first;

    for (final match in matches) {
      // Tratar remoção de itens órfãos descartados/ignorados
      if (match.status == ReconciliationMatchStatus.ignored) {
        if (match.documentTransaction == null &&
            match.systemInstallment != null) {
          await financeService.cancelInstallment(match.systemInstallment!.id);
        }
        continue;
      }

      if (match.status == ReconciliationMatchStatus.matched ||
          match.status == ReconciliationMatchStatus.suggested) {
        // Apenas atualizar/liquidar se for um match vinculado a documento (ignorar orphans mantidos)
        if (match.systemInstallment != null &&
            match.documentTransaction != null) {
          final installment = match.systemInstallment!;
          final type = match.customType ?? installment.type;

          final Map<String, AccountImpact> newAccounts = Map.from(
            installment.accounts,
          );

          if (type != OrderType.transfer) {
            newAccounts.clear();
            newAccounts[selectedAccount.id] = type == OrderType.income
                ? AccountImpact.credit
                : AccountImpact.debt;
          } else {
            newAccounts.clear();
            final docTx = match.documentTransaction;
            final sysInst = match.systemInstallment;
            final isCredit = docTx != null
                ? docTx.type == OrderType.income
                : (sysInst?.type == OrderType.income);

            final existingTargetAccountId = sysInst?.accounts.keys
                .where((key) => key != selectedAccount.id)
                .firstOrNull;
            var resolvedTargetAccountId =
                match.targetAccountId ?? existingTargetAccountId;
            if (resolvedTargetAccountId == selectedAccount.id) {
              resolvedTargetAccountId = existingTargetAccountId;
            }

            if (isCredit) {
              newAccounts[selectedAccount.id] = AccountImpact.credit;
              if (resolvedTargetAccountId != null &&
                  resolvedTargetAccountId != selectedAccount.id) {
                newAccounts[resolvedTargetAccountId] = AccountImpact.debt;
              }
            } else {
              newAccounts[selectedAccount.id] = AccountImpact.debt;
              if (resolvedTargetAccountId != null &&
                  resolvedTargetAccountId != selectedAccount.id) {
                newAccounts[resolvedTargetAccountId] = AccountImpact.credit;
              }
            }
          }

          final docTx = match.documentTransaction;
          final sysInst = match.systemInstallment;

          await financeService.updateInstallment(
            installment.copyWith(
              status: InstallmentStatus.settled,
              paidAmount: (docTx?.amount ?? sysInst?.referenceAmount ?? 0)
                  .abs(),
              paidDate: docTx?.date ?? sysInst?.referenceDate ?? DateTime.now(),
              accounts: newAccounts,
              type: type,
              category: match.customCategory ?? installment.category,
              description: match.customDescription ?? installment.description,
            ),
          );
        }
      }

      if (match.status == ReconciliationMatchStatus.unmatched ||
          (match.status == ReconciliationMatchStatus.matched &&
              match.systemInstallment == null &&
              match.createdOrder == null)) {
        if (match.documentTransaction == null) continue;

        // Criar nova transação baseada nos campos customizados ou no original
        final docTx = match.documentTransaction!;
        final type = match.customType ?? docTx.type;
        final isCredit = type == OrderType.income;

        final category =
            match.customCategory ??
            await _findOrCreateCategory(
              categories,
              docTx.category ??
                  CategoryModel(
                    id: const Uuid().v4(),
                    name: 'Outros',
                    icon: 'help',
                    color: '#9E9E9E',
                    type: type == OrderType.income
                        ? CategoryType.income
                        : CategoryType.expense,
                  ),
            );

        final Map<String, AccountImpact> accounts = {};
        if (type != OrderType.transfer) {
          accounts[selectedAccount.id] = type == OrderType.income
              ? AccountImpact.credit
              : AccountImpact.debt;
        } else {
          if (isCredit) {
            accounts[selectedAccount.id] = AccountImpact.credit;
            if (match.targetAccountId != null) {
              accounts[match.targetAccountId!] = AccountImpact.debt;
            }
          } else {
            accounts[selectedAccount.id] = AccountImpact.debt;
            if (match.targetAccountId != null) {
              accounts[match.targetAccountId!] = AccountImpact.credit;
            }
          }
        }

        final installmentType = (match.installmentCount ?? 1) > 1
            ? InstallmentType.installment
            : InstallmentType.single;

        final order = OrderModel(
          id: const Uuid().v4(),
          amount: docTx.amount.abs(),
          description: match.customDescription ?? docTx.description,
          dueDay: docTx.date.day,
          startMonth:
              '${docTx.date.year}-${docTx.date.month.toString().padLeft(2, '0')}',
          installmentType: installmentType,
          installmentCount: match.installmentCount,
          status: OrderStatus.active,
          type: type,
          installmentCreationStatus: InstallmentStatus.settled,
          category: category,
          accounts: accounts,
        );

        await financeService.addOrder(order);
      }
    }

    // Gravar log de conciliação para triggers de gamificação no backend
    int confirmedMatchesCount = 0;
    int totalTransactionsProcessed = 0;
    int createdTransactionsCount = 0;

    for (final match in matches) {
      if (match.status == ReconciliationMatchStatus.ignored) continue;
      totalTransactionsProcessed++;
      if (match.status == ReconciliationMatchStatus.matched ||
          match.status == ReconciliationMatchStatus.suggested) {
        if (match.systemInstallment != null) {
          confirmedMatchesCount++;
        }
      }
      if (match.status == ReconciliationMatchStatus.unmatched ||
          (match.status == ReconciliationMatchStatus.matched &&
              match.systemInstallment == null &&
              match.createdOrder == null)) {
        if (match.documentTransaction == null) continue;
        createdTransactionsCount++;
      }
    }

    final recId = const Uuid().v4();
    await repository.saveReconciliationSummary(
      workspaceId,
      recId,
      confirmedMatchesCount: confirmedMatchesCount,
      totalTransactionsProcessed: totalTransactionsProcessed,
      createdTransactionsCount: createdTransactionsCount,
    );
  }

  Future<CategoryModel> _findOrCreateCategory(
    List<CategoryModel> categories,
    CategoryModel category,
  ) async {
    final CategoryModel? found = categories
        .where(
          (c) =>
              c.type == category.type &&
              _compareCategoryNames(c.name, category.name),
        )
        .firstOrNull;

    if (found == null) {
      final newCategory = (await categoryService.create(
        category.copyWith(id: const Uuid().v4()),
      )).value;
      return newCategory;
    }

    return found;
  }
}
