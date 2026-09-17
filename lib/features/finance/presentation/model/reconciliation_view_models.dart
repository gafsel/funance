import 'package:funances/core/files/picked_document.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';

part 'reconciliation_view_models.freezed.dart';

enum ReconciliationStep { uploadFile, review }

@freezed
sealed class ReconciliationState with _$ReconciliationState {
  const factory ReconciliationState({
    @Default(ReconciliationStep.uploadFile) ReconciliationStep step,
    required AccountModel selectedAccount,
    PickedDocument? selectedFile,
    @Default([]) List<ReconciliationMatch> matches,
  }) = _ReconciliationState;
}
