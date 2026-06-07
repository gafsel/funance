import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'dart:io';

part 'reconciliation_view_models.freezed.dart';

enum ReconciliationStep { selectAccount, uploadFile, review }

@freezed
sealed class ReconciliationState with _$ReconciliationState {
  const factory ReconciliationState({
    @Default(ReconciliationStep.selectAccount) ReconciliationStep step,
    AccountModel? selectedAccount,
    File? selectedFile,
    @Default([]) List<ReconciliationMatch> matches,
  }) = _ReconciliationState;
}
