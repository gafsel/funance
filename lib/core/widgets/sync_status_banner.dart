import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Quanto tempo o aviso de falha fica na tela antes de sair sozinho.
const Duration _failureDuration = Duration(seconds: 8);

/// Tarja que diz, sem interromper nada, que o app está trabalhando pelo cache
/// — e que avisa quando uma escrita dada como salva acabou recusada.
///
/// Entra pelo `builder` do `MaterialApp`, e não dentro de cada `Scaffold`:
/// assim vale para todas as telas e nenhuma precisa saber que ela existe. É
/// também o único lugar do app que sobrevive à tela que salvou, que é de onde
/// um erro tardio de escrita precisa ser mostrado.
///
/// Fica no TOPO e EMPURRA o conteúdo. A primeira versão era um `Stack` colado
/// no rodapé, para não mexer no layout — mas ali ela cobria a barra de
/// navegação e o botão de novo lançamento da Home, que é justamente o que o
/// usuário vai tocar em seguida. Tapar navegação é pior do que deslocar.
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  StreamSubscription<WriteFailure>? _failures;
  Timer? _hideFailure;
  WriteFailure? _failure;

  @override
  void initState() {
    super.initState();
    _failures = WriteFailures.stream.listen(_showFailure);
  }

  @override
  void dispose() {
    _failures?.cancel();
    _hideFailure?.cancel();
    super.dispose();
  }

  void _showFailure(WriteFailure failure) {
    if (!mounted) return;

    setState(() => _failure = failure);

    _hideFailure?.cancel();
    _hideFailure = Timer(_failureDuration, () {
      if (mounted) setState(() => _failure = null);
    });
  }

  void _dismissFailure() {
    _hideFailure?.cancel();
    setState(() => _failure = null);
  }

  @override
  Widget build(BuildContext context) {
    final SyncStatus status =
        ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.online;
    final int pending = ref.watch(pendingWriteCountProvider).valueOrNull ?? 0;

    // A contagem local cobre o que os metadados não veem: eles falam só do
    // documento observado, e a escrita pendente pode estar em qualquer coleção.
    final SyncStatus effective = effectiveSyncStatus(status, pending);

    final WriteFailure? failure = _failure;
    final bool showsStatus = effective != SyncStatus.online;

    if (failure == null && !showsStatus) return widget.child;

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (failure != null)
                _FailureStrip(failure: failure, onDismiss: _dismissFailure),
              if (showsStatus) _StatusStrip(status: effective),
            ],
          ),
        ),
        // A tarja já consumiu o recorte do topo; deixá-lo para o conteúdo
        // abriria uma faixa vazia sob ela.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isOffline = status == SyncStatus.offline;

    return Material(
      color: isOffline ? AppColors.darkNavy : AppColors.deepTurquoise,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOffline)
              const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: AppColors.pureWhite,
              )
            else
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.pureWhite,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isOffline
                    ? l10n.offlineBannerOffline
                    : l10n.offlineBannerPending,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureStrip extends StatelessWidget {
  const _FailureStrip({required this.failure, required this.onDismiss});

  final WriteFailure failure;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: AppColors.error,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.pureWhite,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.writeFailed(writeFailureText(l10n, failure.reason)),
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 13,
                ),
              ),
            ),
            // Sem `tooltip`: a tarja vive ACIMA do Navigator, e um tooltip
            // precisa de um `Overlay` — que só existe abaixo dele. Com o
            // tooltip, mostrar esta tarja quebrava a tela inteira. O rótulo
            // para leitores de tela vem pelo Semantics.
            Semantics(
              button: true,
              label: l10n.closeButton,
              child: IconButton(
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.pureWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Motivo da recusa, em texto para o usuário.
String writeFailureText(AppLocalizations l10n, WriteFailureReason reason) {
  return switch (reason) {
    WriteFailureReason.permissionDenied => l10n.writeFailedReasonPermission,
    WriteFailureReason.notFound => l10n.writeFailedReasonNotFound,
    WriteFailureReason.tookTooLong => l10n.writeFailedReasonTimeout,
    WriteFailureReason.unknown => l10n.writeFailedReasonUnknown,
  };
}
