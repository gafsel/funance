import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';

/// Tarja que diz, sem interromper nada, que o app está trabalhando pelo cache.
///
/// Entra pelo `builder` do `MaterialApp`, e não dentro de cada `Scaffold`:
/// assim vale para todas as telas e nenhuma precisa saber que ela existe.
///
/// É um `Stack` de propósito. Empurrar o conteúdo para baixo mexeria no layout
/// de toda tela a cada oscilação de rede — justamente quando o usuário está no
/// meio de alguma coisa.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SyncStatus status =
        ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.online;

    return Stack(
      children: [
        child,
        if (status != SyncStatus.online)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Strip(status: status),
          ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.status});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool isOffline = status == SyncStatus.offline;

    return Material(
      color: isOffline ? AppColors.darkNavy : AppColors.deepTurquoise,
      child: SafeArea(
        top: false,
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
      ),
    );
  }
}
