import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/features/finance/presentation/controllers/reconciliation_notifier.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:uuid/uuid.dart';

/// Primeira etapa: escolher o extrato.
///
/// A janela de progresso é diferente por formato porque o custo é diferente:
/// OFX e imagem são rápidos, PDF passa por extração e pode levar minutos.
class ReconciliationUploadView extends StatelessWidget {
  const ReconciliationUploadView({super.key, required this.notifier});

  final ReconciliationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StatementUploadPanel(
          allowedExtensions: const ['pdf', 'ofx', 'png', 'jpg', 'jpeg'],
          title: l10n.reconciliationSelectAccount,
          dragOverTitle: l10n.statementDragOverTitle,
          supportedFormatsText: l10n.reconciliationSupportedFormats,
          selectFileButtonText: l10n.reconciliationChooseFile,
          onFileSelected: (document) async {
            final extension = document.extension;
            final uploadId = const Uuid().v4();
            final messenger = ScaffoldMessenger.of(context);
            final progressStream = notifier.reconciliationService
                .watchUploadProgress(uploadId);

            try {
              await showLoadingModal(
                context,
                notifier.uploadFile(document, uploadId: uploadId),
                child: AnalysisLoadingView(
                  title: l10n.reconciliationAnalyzing,
                  description: l10n.reconciliationAnalyzingDesc,
                  progressStream: progressStream,
                  firstPhaseDuration:
                      ['ofx', 'png', 'jpg', 'jpeg'].contains(extension)
                      ? const Duration(seconds: 20)
                      : const Duration(minutes: 1),
                  totalDuration:
                      ['ofx', 'png', 'jpg', 'jpeg'].contains(extension)
                      ? const Duration(seconds: 45)
                      : const Duration(minutes: 5),
                ),
              );
            } catch (e) {
              // Antes a falha era silenciosa: o modal fechava e a tela ficava
              // parada na etapa de upload.
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    callableErrorMessage(
                      e,
                      l10n.reconciliationError,
                      offlineMessage: l10n.errorOfflineCallable,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
