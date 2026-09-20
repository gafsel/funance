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
  const CoachingInsightCard({super.key, this.compact = false});

  /// Uma LINHA em vez do cartão inteiro.
  ///
  /// Na Home o coaching custava 120px fixos de altura — e o dobro disso
  /// quando não havia análise recente, porque o cartão de convite tem título,
  /// parágrafo e botão. Análise de IA não é informação diária: ela é lida uma
  /// vez e vale por semanas. A linha diz que existe algo a ler (ou a pedir) e
  /// leva à tela onde isso acontece; o cartão inteiro continua existindo para
  /// onde ele é o assunto.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastInsightAsync = ref.watch(CoachingViewProviders.lastInsight);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    if (compact) {
      // A linha não mostra carregamento nem erro: sem análise ela já é o
      // convite para pedir uma, que é a mesma coisa que o usuário faria
      // depois de ver um erro.
      return _CoachingLine(insight: lastInsightAsync.valueOrNull);
    }

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
                        onPressed: () => generateAndOpen(context, ref),
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

  /// Gera uma análise nova e abre, com o modal de espera e o tratamento de
  /// falha. Extraído para que a LINHA compacta da Home ofereça exatamente a
  /// mesma ação que o botão do cartão — e não uma segunda cópia dela.
  static Future<void> generateAndOpen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final coaching = await showLoadingModal(
        context,
        ref.read(CoachingDomainProviders.service).generateCoaching(),
        child: AnalysisLoadingView(
          title: l10n.coachingConsulting,
          description: l10n.coachingConsultingDesc,
        ),
      );

      ref.invalidate(CoachingViewProviders.lastInsight);
      ref.invalidate(CoachingViewProviders.insightsHistory);

      if (context.mounted) {
        _logCoachingOpened(ref);
        unawaited(context.push('/coaching?id=${coaching.id}'));
      }
    } catch (e) {
      // Sem isso a falha era silenciosa: o modal fechava e nada acontecia
      // após minutos de espera.
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
  }

  /// Dispara o evento de funil sem bloquear a navegação nem deixar uma falha
  /// de analytics impedir o usuário de abrir o coaching.
  static void _logCoachingOpened(WidgetRef ref) {
    unawaited(
      ref.read(analyticsServiceProvider).logCoachingOpened().catchError((_) {}),
    );
  }
}

/// O coaching em uma linha, para a Home.
class _CoachingLine extends ConsumerWidget {
  const _CoachingLine({required this.insight});

  final CoachingModel? insight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    final fresh = insight != null && !insight!.isDeprecated;
    final texto = fresh ? insight!.message : l10n.coachingConsultingDesc;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: () {
            if (fresh) {
              CoachingInsightCard._logCoachingOpened(ref);
              context.push('/coaching?id=${insight!.id}');
            } else {
              CoachingInsightCard.generateAndOpen(context, ref);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: palette.line),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 18,
                  color: palette.tealText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.ink,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  fresh ? l10n.coachingViewLast : l10n.coachingConsultAction,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.tealText,
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: palette.ink2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
