import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_card.dart';

/// A moldura do card da Bússola e os dois estados em que ele ainda não tem um
/// índice para mostrar.
///
/// A moldura é sempre a mesma — mesmo tamanho, mesma cor, mesmo raio — em
/// carregando, calibrando e pronto. É o que impede o card de pular de altura na
/// Jornada enquanto o Firestore responde.
class CompassShell extends StatelessWidget {
  const CompassShell({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        onTap: onTap,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class CompassLoading extends StatelessWidget {
  const CompassLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.l10n.compassTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}

class CompassCalibrating extends StatelessWidget {
  const CompassCalibrating({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.explore_outlined,
          color: context.palette.tealText,
          size: 32,
        ),
        AppSpacing.gapSm,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.compassCalibratingTitle,
                style: theme.textTheme.titleSmall,
              ),
              AppSpacing.gapXxs,
              Text(
                l10n.compassCalibratingMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
