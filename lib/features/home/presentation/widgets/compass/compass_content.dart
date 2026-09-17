import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';

/// O card da Bússola quando o servidor já publicou um índice: o score no anel,
/// a faixa por extenso e as quatro barras dos componentes.
///
/// As barras aparecem no card e não só no sheet porque o número sozinho não
/// diz o que fazer — é a barra curta que aponta qual componente está puxando o
/// índice para baixo.
class CompassContent extends StatelessWidget {
  const CompassContent({required this.health, super.key});

  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = compassScoreColor(health.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: 56,
              width: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: health.fraction,
                      strokeWidth: 6,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  Text(
                    health.score.round().toString(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.compassTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    compassTierLabel(l10n, health.tier),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        for (final component in FreedomComponent.values)
          _ComponentBar(score: health.componentOf(component), kind: component),
      ],
    );
  }
}

class _ComponentBar extends StatelessWidget {
  const _ComponentBar({required this.kind, required this.score});

  final FreedomComponent kind;
  final FreedomComponentScore? score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final value = score;
    final color = value == null
        ? theme.colorScheme.outlineVariant
        : compassScoreColor(value.score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(compassComponentIcon(kind), size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              compassComponentLabel(l10n, kind),
              style: theme.textTheme.labelMedium,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value?.fraction ?? 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              value == null ? '—' : value.score.round().toString(),
              textAlign: TextAlign.end,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
