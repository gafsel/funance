import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/services/account_service.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:uuid/uuid.dart';

class ReconciliationNotifier extends StateNotifier<ReconciliationState> {
  final AccountService accountService;
  final FinanceService financeService;
  final CategoryService categoryService;
  final AccountModel account;

  ReconciliationNotifier({
    required this.accountService,
    required this.financeService,
    required this.categoryService,
    required this.account,
  }) : super(ReconciliationState(selectedAccount: account));

  void back() {
    if (state.step == ReconciliationStep.review) {
      state = state.copyWith(step: ReconciliationStep.uploadFile);
    }
  }

  void reset() {
    state = ReconciliationState(selectedAccount: account);
  }

  Future<void> uploadFile(File file) async {
    state = state.copyWith(selectedFile: file);

    final transactions = await accountService.analyzeReconciliationDocument(
      file,
    );

    // Buscar transações existentes no sistema para essa conta
    // Vamos pegar um range de data baseado nas transações encontradas
    if (transactions.isEmpty) {
      state = state.copyWith(matches: [], step: ReconciliationStep.review);
      return;
    }

    final dates = transactions.map((t) => t.date).toList();
    dates.sort();
    final startDate = dates.first.subtract(const Duration(days: 7));
    final endDate = dates.last.add(const Duration(days: 7));

    final systemInstallmentsChunk = await financeService.queryInstallments(
      limit: 1000,
      accountId: state.selectedAccount.id,
      startDate: startDate,
      endDate: endDate,
    );

    final systemInstallments = systemInstallmentsChunk.items;

    final matches = _matchTransactions(transactions, systemInstallments);
    state = state.copyWith(matches: matches, step: ReconciliationStep.review);
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

    // Ordenar por data
    matches.sort((a, b) {
      final dateA = a.documentTransaction?.date ?? a.systemInstallment?.referenceDate ?? DateTime.now();
      final dateB = b.documentTransaction?.date ?? b.systemInstallment?.referenceDate ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return matches;
  }

  void updateMatch(int index, ReconciliationMatch match) {
    final newMatches = List<ReconciliationMatch>.from(state.matches);
    newMatches[index] = match;
    state = state.copyWith(matches: newMatches);
  }

  void linkManual(int index, InstallmentModel installment) {
    final matches = List<ReconciliationMatch>.from(state.matches);
    
    // Se a transação que estamos vinculando já existia como um match isolado do sistema,
    // precisamos removê-la para não ficar duplicada.
    final existingSystemMatchIndex = matches.indexWhere(
      (m) => m.documentTransaction == null && m.systemInstallment?.id == installment.id,
    );
    
    matches[index] = matches[index].copyWith(
      systemInstallment: installment,
      status: ReconciliationMatchStatus.matched,
      customCategory: installment.category,
      customDescription: installment.description,
      customType: installment.type,
      targetAccountId: installment.accountIdTarget,
    );

    if (existingSystemMatchIndex != -1) {
      matches.removeAt(existingSystemMatchIndex);
    }
    
    state = state.copyWith(matches: matches);
  }

  Future<void> confirmReconciliation() async {
    final categories = await categoryService.getCategories().first;
    final selectedAccount = state.selectedAccount!;

    for (final match in state.matches) {
      if (match.status == ReconciliationMatchStatus.ignored) continue;

      if (match.status == ReconciliationMatchStatus.matched ||
          match.status == ReconciliationMatchStatus.suggested) {
        if (match.systemInstallment != null) {
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
            final isCredit = (docTx?.amount ??
                    sysInst?.referenceAmount ??
                    0) >=
                0;
            if (isCredit) {
              newAccounts[selectedAccount.id] = AccountImpact.credit;
              if (match.targetAccountId != null) {
                newAccounts[match.targetAccountId!] = AccountImpact.debt;
              }
            } else {
              newAccounts[selectedAccount.id] = AccountImpact.debt;
              if (match.targetAccountId != null) {
                newAccounts[match.targetAccountId!] = AccountImpact.credit;
              }
            }
          }

          final docTx = match.documentTransaction;
          final sysInst = match.systemInstallment;

          await financeService.updateInstallment(
            installment.copyWith(
              status: InstallmentStatus.settled,
              paidAmount: (docTx?.amount ??
                      sysInst?.referenceAmount ??
                      0)
                  .abs(),
              paidDate: docTx?.date ??
                  sysInst?.referenceDate ??
                  DateTime.now(),
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
        final isCredit = docTx.amount >= 0;

        final category = match.customCategory ??
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
  }

  Future<CategoryModel> _findOrCreateCategory(
    List<CategoryModel> categories,
    CategoryModel category,
  ) async {
    CategoryModel? found = categories
        .where(
          (c) =>
              c.type == category.type &&
              c.name.toLowerCase() == category.name.toLowerCase(),
        )
        .firstOrNull;

    if (found == null) {
      final newCategory = await categoryService.create(
        category.copyWith(id: const Uuid().v4()),
      );
      return newCategory;
    }

    return found;
  }

}
