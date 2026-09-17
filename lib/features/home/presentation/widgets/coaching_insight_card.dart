import 'dart:async';

import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/utils/error_messages.dart';

class CoachingInsightCard extends ConsumerWidget {
  const CoachingInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastInsightAsync = ref.watch(CoachingViewProviders.lastInsight);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return lastInsightAsync.when(
      data: (lastInsight) {
        return Column(
          children: [
            _buildCoachingCall(context, lastInsight),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => Container(
        width: double.infinity,
        height: 120,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_outlined, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            // Sem rede, "não foi possível gerar sua análise" manda o
            // usuário tentar de novo sem dizer o que falta.
            Expanded(
              child: Text(
                callableErrorMessage(
                  error,
                  errorMessageFor(context, error),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(CoachingViewProviders.lastInsight),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachingCall(BuildContext context, CoachingModel? lastInsight) {
    if (lastInsight?.isDeprecated ?? true) {
      return _buildNewInsightCall(context);
    }

    return _buildReviewLastInsight(context, lastInsight!);
  }

  Widget _buildNewInsightCall(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepTurquoise, AppColors.vibrantTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 120,
              color: AppColors.successGold.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.successGold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: AppColors.successGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.coachingTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/coaching/history'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.coachingViewHistory,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.pureWhite.withValues(alpha: 0.9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.history,
                              color: AppColors.pureWhite.withValues(alpha: 0.9),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.coachingConsultingDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.pureWhite.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, _) {
                      return ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final coaching = await showLoadingModal(
                              context,
                              ref
                                  .read(CoachingDomainProviders.service)
                                  .generateCoaching(),
                              child: AnalysisLoadingView(
                                title: l10n.coachingConsulting,
                                description: l10n.coachingConsultingDesc,
                              ),
                            );

                            ref.invalidate(CoachingViewProviders.lastInsight);
                            ref.invalidate(
                              CoachingViewProviders.insightsHistory,
                            );

                            if (context.mounted) {
                              _logCoachingOpened(ref);
                              unawaited(
                                context.push('/coaching?id=${coaching.id}'),
                              );
                            }
                          } catch (e) {
                            // Sem isso a falha era silenciosa: o modal fechava
                            // e nada acontecia após minutos de espera.
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  callableErrorMessage(
                                    e,
                                    l10n.coachingError,
                                    offlineMessage: l10n.errorOfflineCallable,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGold,
                          foregroundColor: AppColors.darkNavy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          l10n.coachingConsultAction.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewLastInsight(
    BuildContext context,
    CoachingModel lastCoaching,
  ) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: AppColors.deepTurquoise,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.coachingTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                lastCoaching.date.formated(l10n.formatSimpleDate, locale),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/coaching/history'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.coachingViewHistory,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.deepTurquoise,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.history,
                        color: AppColors.deepTurquoise,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastCoaching.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, _) => InkWell(
              onTap: () {
                _logCoachingOpened(ref);
                context.push('/coaching?id=${lastCoaching.id}');
              },
              child: Text(
                l10n.coachingViewLast,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.deepTurquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dispara o evento de funil sem bloquear a navegação nem deixar uma falha
  /// de analytics impedir o usuário de abrir o coaching.
  static void _logCoachingOpened(WidgetRef ref) {
    unawaited(
      ref.read(analyticsServiceProvider).logCoachingOpened().catchError((_) {}),
    );
  }
}
