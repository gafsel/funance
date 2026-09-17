import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/theme/app_spacing.dart';

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
  WriteFailure? _failure;

  @override
  void initState() {
    super.initState();
    _failures = WriteFailures.stream.listen(_showFailure);
  }

  @override
  void dispose() {
    _failures?.cancel();
    super.dispose();
  }

  /// O aviso FICA até o usuário dispensar.
  ///
  /// Ele some sozinho antes durava 8 s, e 8 s é tempo de mais nada: quem
  /// estava com o app no bolso ou noutra aba perdia a única notícia de que
  /// uma alteração não foi salva. Não é um aviso de rotina — é a informação
  /// de que algo que a pessoa achava guardado não está.
  void _showFailure(WriteFailure failure) {
    if (!mounted) return;

    setState(() => _failure = failure);
  }

  void _dismissFailure() => setState(() => _failure = null);

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
      color: isOffline ? AppColors.surfaceDeep : AppColors.surfaceDefault,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isOffline)
              const Icon(
                Icons.cloud_off_outlined,
                size: 18,
                color: AppColors.inkInverse,
              )
            else
              const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.inkInverse,
                  ),
                ),
              ),
            AppSpacing.gapSm,
            Flexible(
              child: Text(
                isOffline
                    ? l10n.offlineBannerOffline
                    : l10n.offlineBannerPending,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkInverse),
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
      color: AppColors.danger,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: AppColors.inkInverse,
            ),
            AppSpacing.gapSm,
            Expanded(
              child: Text(
                l10n.writeFailedEntity(
                  writeEntityText(l10n, failure.entity),
                  writeFailureText(l10n, failure.reason),
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkInverse),
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
                  color: AppColors.inkInverse,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O que não pôde ser salvo, em texto para o usuário.
String writeEntityText(AppLocalizations l10n, WriteEntity entity) {
  return switch (entity) {
    WriteEntity.transaction => l10n.writeEntityTransaction,
    WriteEntity.installment => l10n.writeEntityInstallment,
    WriteEntity.planning => l10n.writeEntityPlanning,
    WriteEntity.account => l10n.writeEntityAccount,
    WriteEntity.category => l10n.writeEntityCategory,
    WriteEntity.goal => l10n.writeEntityGoal,
    WriteEntity.invite => l10n.writeEntityInvite,
    WriteEntity.workspace => l10n.writeEntityWorkspace,
    WriteEntity.profile => l10n.writeEntityProfile,
    WriteEntity.automaticTransaction => l10n.writeEntityAutomaticTransaction,
    WriteEntity.reconciliation => l10n.writeEntityReconciliation,
  };
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
