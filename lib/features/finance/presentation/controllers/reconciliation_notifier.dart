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

  ReconciliationNotifier({
    required this.accountService,
    required this.financeService,
    required this.categoryService,
  }) : super(const ReconciliationState());

  void selectAccount(AccountModel account) {
    state = state.copyWith(
      selectedAccount: account,
      step: ReconciliationStep.uploadFile,
    );
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
      accountId: state.selectedAccount?.id,
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

    return matches;
  }

  void updateMatch(int index, ReconciliationMatch match) {
    final newMatches = List<ReconciliationMatch>.from(state.matches);
    newMatches[index] = match;
    state = state.copyWith(matches: newMatches);
  }

  void linkManual(int index, InstallmentModel systemInstallment) {
    final docTx = state.matches[index].documentTransaction;
    final newMatch = ReconciliationMatch(
      documentTransaction: docTx,
      systemInstallment: systemInstallment,
      status: ReconciliationMatchStatus.matched,
    );
    updateMatch(index, newMatch);
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
          final type = installment.type;

          // Atualizar o mapa de contas para a conta selecionada na conciliação
          final Map<String, AccountImpact> newAccounts = Map.from(
            installment.accounts,
          );

          // Remover impactos de outras contas se for transação comum (não transferência)
          if (type != OrderType.transfer) {
            newAccounts.clear();
            newAccounts[selectedAccount.id] = type == OrderType.income
                ? AccountImpact.credit
                : AccountImpact.debt;
          } else {
            // Se for transferência, precisamos decidir qual ponta atualizar.
            // Geralmente concilia-se a conta onde o extrato foi gerado.
            // Se a conta selecionada já estiver no mapa, garantimos o impacto correto.
            // Se não estiver, substituímos a ponta que faz sentido.
            if (newAccounts.containsKey(selectedAccount.id)) {
              // Já está lá, mantemos.
            } else {
              // Lógica simplificada: se o valor no extrato for positivo, é crédito na conta.
              final impact = match.documentTransaction.amount >= 0
                  ? AccountImpact.credit
                  : AccountImpact.debt;

              // Se estamos inserindo um crédito, removemos o crédito antigo.
              if (impact == AccountImpact.credit) {
                newAccounts.removeWhere(
                  (key, value) => value == AccountImpact.credit,
                );
              } else {
                newAccounts.removeWhere(
                  (key, value) => value == AccountImpact.debt,
                );
              }
              newAccounts[selectedAccount.id] = impact;
            }
          }

          // Marcar como settled e atualizar conta
          await financeService.updateInstallment(
            installment.copyWith(
              status: InstallmentStatus.settled,
              paidAmount: match.documentTransaction.amount.abs(),
              paidDate: match.documentTransaction.date,
              accounts: newAccounts,
            ),
          );
        }
      } else if (match.status == ReconciliationMatchStatus.unmatched) {
        // Cadastrar nova transação
        final category = await _findOrCreateCategory(
          categories,
          match.documentTransaction.category ??
              CategoryModel(
                id: const Uuid().v4(),
                name: 'Outros',
                icon: 'help',
                color: '#9E9E9E',
                type: match.documentTransaction.type == 'income'
                    ? CategoryType.income
                    : CategoryType.expense,
              ),
        );

        final type = match.documentTransaction.type == 'income'
            ? OrderType.income
            : OrderType.expense;

        final order = OrderModel(
          id: const Uuid().v4(),
          amount: match.documentTransaction.amount,
          description: match.documentTransaction.description,
          dueDay: match.documentTransaction.date.day,
          startMonth:
              '${match.documentTransaction.date.year}-${match.documentTransaction.date.month.toString().padLeft(2, '0')}',
          installmentType: InstallmentType.single,
          status: OrderStatus.active,
          type: type,
          installmentCreationStatus: InstallmentStatus.settled,
          category: category,
          accounts: {
            state.selectedAccount!.id: type == OrderType.income
                ? AccountImpact.credit
                : AccountImpact.debt,
          },
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

  void back() {
    if (state.step == ReconciliationStep.uploadFile) {
      state = state.copyWith(step: ReconciliationStep.selectAccount);
    } else if (state.step == ReconciliationStep.review) {
      state = state.copyWith(step: ReconciliationStep.uploadFile);
    }
  }
}
