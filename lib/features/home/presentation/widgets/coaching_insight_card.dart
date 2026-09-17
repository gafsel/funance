import 'dart:async';

import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/utils/error_messages.dart';
import 'package:funances/core/presentation/retry.dart';

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
            AppSpacing.gapLg,
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: double.infinity,
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: AppCard(
          child: Row(
            children: [
              Icon(Icons.psychology_outlined, color: theme.colorScheme.error),
              AppSpacing.gapXs,
              // Sem rede, "não foi possível gerar sua análise" manda o
              // usuário tentar de novo sem dizer o que falta.
              Expanded(
                child: Text(
                  callableErrorMessage(error, errorMessageFor(context, error)),
                ),
              ),
              TextButton(
                onPressed: () => Retry.lastInsight(ref),
                child: Text(l10n.retry),
              ),
            ],
          ),
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

    return AppCard.game(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 120,
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: AppSpacing.allMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: AppSpacing.allXs,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Expanded(
                      child: Text(
                        l10n.coachingTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.inkInverse,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/coaching/history'),
                      borderRadius: AppRadius.brSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.coachingViewHistory,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.inkInverse2,
                              ),
                            ),
                            AppSpacing.gapXxs,
                            const Icon(
                              Icons.history,
                              color: AppColors.inkInverse2,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapSm,
                Text(
                  l10n.coachingConsultingDesc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkInverse2,
                  ),
                ),
                AppSpacing.gapMd,
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
                        child: Text(l10n.coachingConsultAction.toUpperCase()),
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
    final palette = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: palette.ink, size: 20),
              AppSpacing.gapXs,
              Expanded(
                child: Text(
                  l10n.coachingTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                lastCoaching.date.formated(l10n.formatSimpleDate, locale),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapXs,
              InkWell(
                onTap: () => context.push('/coaching/history'),
                borderRadius: AppRadius.brXs,
                child: Padding(
                  padding: AppSpacing.allXxs,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.coachingViewHistory,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.tealText,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.history, color: palette.tealText, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            lastCoaching.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          AppSpacing.gapSm,
          Consumer(
            builder: (context, ref, _) => InkWell(
              onTap: () {
                _logCoachingOpened(ref);
                context.push('/coaching?id=${lastCoaching.id}');
              },
              child: Text(
                l10n.coachingViewLast,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: palette.tealText,
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
