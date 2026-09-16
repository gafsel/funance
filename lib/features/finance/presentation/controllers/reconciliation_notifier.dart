import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/domain/services/reconciliation_service.dart';
import 'package:funances/features/finance/presentation/model/reconciliation_view_models.dart';

class ReconciliationNotifier extends StateNotifier<ReconciliationState> {
  final ReconciliationService reconciliationService;
  final AccountModel account;
  final AnalyticsService analytics;

  ReconciliationNotifier({
    required this.reconciliationService,
    required this.account,
    required this.analytics,
  }) : super(ReconciliationState(selectedAccount: account));

  void back() {
    if (state.step == ReconciliationStep.review) {
      state = state.copyWith(step: ReconciliationStep.uploadFile);
    }
  }

  void reset() {
    state = ReconciliationState(selectedAccount: account);
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

  Future<void> uploadFile(File file, {String? uploadId}) async {
    state = state.copyWith(selectedFile: file);

    final matches = await reconciliationService.loadMatchesForDocument(
      file: file,
      accountId: state.selectedAccount.id,
      uploadId: uploadId,
    );

    state = state.copyWith(matches: matches, step: ReconciliationStep.review);
  }

  void updateMatch(int index, ReconciliationMatch match) {
    final newMatches = List<ReconciliationMatch>.from(state.matches);
    newMatches[index] = match;
    state = state.copyWith(matches: newMatches);
  }

  void confirmAllSuggestions() {
    final newMatches = state.matches.map((m) {
      if (m.status == ReconciliationMatchStatus.suggested) {
        return m.copyWith(status: ReconciliationMatchStatus.matched);
      }
      return m;
    }).toList();
    state = state.copyWith(matches: newMatches);
  }

  void linkManual(int index, InstallmentModel installment) {
    var matches = List<ReconciliationMatch>.from(state.matches);

    // 1. Desassociar esta parcela de qualquer outra transação de extrato para garantir 1:1
    for (int i = 0; i < matches.length; i++) {
      if (i != index &&
          matches[i].documentTransaction != null &&
          matches[i].systemInstallment?.id == installment.id) {
        matches[i] = matches[i].copyWith(
          systemInstallment: null,
          status: ReconciliationMatchStatus.unmatched,
          customCategory: null,
          customDescription: null,
          customType: null,
          targetAccountId: null,
        );
      }
    }

    // 2. Se existia como um match órfão do sistema, remover da listagem
    final existingSystemMatchIndex = matches.indexWhere(
      (m) =>
          m.documentTransaction == null &&
          m.systemInstallment?.id == installment.id,
    );

    final targetAccountId = installment.accounts.keys
        .where((key) => key != account.id)
        .firstOrNull;

    matches[index] = matches[index].copyWith(
      systemInstallment: installment,
      status: ReconciliationMatchStatus.matched,
      customCategory: installment.category,
      customDescription: installment.description,
      customType: installment.type,
      targetAccountId: targetAccountId,
    );

    if (existingSystemMatchIndex != -1) {
      final itemToRemove = matches[existingSystemMatchIndex];
      matches.remove(itemToRemove);
    }

    state = state.copyWith(matches: matches);
  }

  void unlinkMatch(int index) {
    var matches = List<ReconciliationMatch>.from(state.matches);
    final match = matches[index];
    final unlinkedInstallment = match.systemInstallment;

    if (unlinkedInstallment == null) return;

    matches[index] = match.copyWith(
      systemInstallment: null,
      status: ReconciliationMatchStatus.unmatched,
      customCategory: null,
      customDescription: null,
      customType: null,
      targetAccountId: null,
      installmentCount: null,
    );

    matches.add(
      ReconciliationMatch(
        systemInstallment: unlinkedInstallment,
        status: ReconciliationMatchStatus.unmatched,
      ),
    );

    _sortMatches(matches);
    state = state.copyWith(matches: matches);
  }

  Future<void> confirmReconciliation() async {
    await reconciliationService.confirmReconciliation(
      selectedAccount: state.selectedAccount,
      matches: state.matches,
    );

    // Analytics não pode derrubar a conciliação já confirmada no servidor.
    try {
      await analytics.logReconciliationDone();
    } catch (_) {}
  }
}
