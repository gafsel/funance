import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_history.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/l10n/app_localizations.dart';

/// A explicação de cada componente e o histórico dos últimos meses.
class FreedomCompassSheet extends ConsumerWidget {
  const FreedomCompassSheet({super.key, required this.health});

  final FinancialHealth health;

  static Future<void> show(BuildContext context, FinancialHealth health) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FreedomCompassSheet(health: health),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.compassTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.compassScoreOf(
                health.score.round().toString(),
                compassTierLabel(l10n, health.tier),
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final component in FreedomComponent.values)
              _ComponentExplanation(
                kind: component,
                score: health.componentOf(component),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.compassHistoryTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const CompassHistory(),
          ],
        ),
      ),
    );
  }
}

class _ComponentExplanation extends StatelessWidget {
  const _ComponentExplanation({required this.kind, required this.score});

  final FreedomComponent kind;
  final FreedomComponentScore? score;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);
    final value = score;
    final color = value == null
        ? theme.colorScheme.outlineVariant
        : compassScoreColor(value.score);

    final detail = value == null ? null : _detail(l10n, locale, value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(compassComponentIcon(kind), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        compassComponentLabel(l10n, kind),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      value == null ? '—' : value.score.round().toString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  compassComponentDescription(l10n, kind),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A legenda com a unidade do componente. Cada um tem a sua, e só aparece
  /// quando o servidor publicou o número — sem ele, fica só a explicação.
  String? _detail(
    AppLocalizations l10n,
    String locale,
    FreedomComponentScore value,
  ) {
    return switch (kind) {
      FreedomComponent.folego =>
        value.months == null
            ? null
            : l10n.compassFolegoDetail(value.months!.toStringAsFixed(1)),
      FreedomComponent.poupanca =>
        value.rate == null
            ? null
            : l10n.compassPoupancaDetail(value.rate!.asPercent(locale: locale)),
      FreedomComponent.disciplina =>
        value.within == null || value.total == null
            ? null
            : l10n.compassDisciplinaDetail(value.within!, value.total!),
      FreedomComponent.alivio =>
        value.delta == null
            ? null
            : l10n.compassAlivioDetail(
                value.delta!.asSignedCurrency(locale: locale),
              ),
    };
  }
}
