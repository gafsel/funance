import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/presentation/retry.dart';

class CoachingHistoryScreen extends ConsumerWidget {
  const CoachingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.locale;
    final historyAsync = ref.watch(CoachingViewProviders.insightsHistory);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coachingHistoryTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(CoachingViewProviders.insightsHistory);
          await ref.read(CoachingViewProviders.insightsHistory.future);
        },
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.coachingNoData,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final coaching = history[index];
                return _buildCoachingCard(context, coaching, l10n, locale);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorView.forError(
                context,
                err,
                onRetry: () => Retry.coaching(ref),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoachingCard(
    BuildContext context,
    CoachingModel coaching,
    AppLocalizations l10n,
    String locale,
  ) {
    final theme = Theme.of(context);
    final cardColor = coaching.type == CoachingType.warning
        ? Colors.amber.shade900.withValues(alpha: 0.08)
        : coaching.type == CoachingType.tip
            ? Colors.green.shade900.withValues(alpha: 0.08)
            : AppColors.deepTurquoise.withValues(alpha: 0.08);

    final iconColor = coaching.type == CoachingType.warning
        ? Colors.amber
        : coaching.type == CoachingType.tip
            ? Colors.green
            : AppColors.deepTurquoise;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/coaching?id=${coaching.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        coaching.type == CoachingType.warning
                            ? Icons.warning_amber_rounded
                            : coaching.type == CoachingType.tip
                                ? Icons.tips_and_updates_outlined
                                : Icons.psychology_outlined,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        coaching.date.formated(l10n.formatSimpleDate, locale),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(context, coaching),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  coaching.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => context.push('/coaching?id=${coaching.id}'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(l10n.coachingReviewTips),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, CoachingModel coaching) {
    final theme = Theme.of(context);
    final String label;
    final Color color;

    switch (coaching.type) {
      case CoachingType.warning:
        label = "Alerta";
        color = Colors.amber.shade800;
        break;
      case CoachingType.tip:
        label = "Dica";
        color = Colors.green.shade700;
        break;
      case CoachingType.insight:
        label = "Insight";
        color = AppColors.deepTurquoise;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
