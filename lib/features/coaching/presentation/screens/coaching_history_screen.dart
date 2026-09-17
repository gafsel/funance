import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/empty_state.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Como cada tipo de insight se apresenta: ícone, tom da pílula e rótulo.
///
/// Antes eram três ternários aninhados repetidos em três lugares (cor de
/// fundo, cor do ícone e cor do selo), com `Colors.amber`/`Colors.green` — as
/// únicas duas cores cruas que sobraram no app — e os rótulos "Alerta",
/// "Dica" e "Insight" escritos em português direto no código, que em inglês
/// apareciam em português. Aqui o tipo responde por si.
extension on CoachingType {
  IconData get icon => switch (this) {
    CoachingType.warning => Icons.warning_amber_rounded,
    CoachingType.tip => Icons.tips_and_updates_outlined,
    CoachingType.insight => Icons.psychology_outlined,
  };

  StatusTone get tone => switch (this) {
    CoachingType.warning => StatusTone.warning,
    CoachingType.tip => StatusTone.ok,
    CoachingType.insight => StatusTone.info,
  };

  String label(AppLocalizations l10n) => switch (this) {
    CoachingType.warning => l10n.coachingTypeWarning,
    CoachingType.tip => l10n.coachingTypeTip,
    CoachingType.insight => l10n.coachingTypeInsight,
  };
}

/// A cor do tipo, já resolvida para o tema em vigor.
Color _toneColor(AppPalette palette, CoachingType type) => switch (type) {
  CoachingType.warning => palette.warningText,
  CoachingType.tip => palette.successText,
  CoachingType.insight => palette.tealText,
};

class CoachingHistoryScreen extends ConsumerWidget {
  const CoachingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = context.locale;
    final historyAsync = ref.watch(CoachingViewProviders.insightsHistory);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.coachingHistoryTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(CoachingViewProviders.insightsHistory);
          await ref.read(CoachingViewProviders.insightsHistory.future);
        },
        child: historyAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return EmptyState.centered(
                icon: Icons.psychology_outlined,
                title: l10n.coachingNoData,
              );
            }

            return ListView.separated(
              padding: AppSpacing.allMd,
              itemCount: history.length,
              separatorBuilder: (_, _) => AppSpacing.gapMd,
              itemBuilder: (context, index) =>
                  _CoachingCard(coaching: history[index], locale: locale),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: AppSpacing.allLg,
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
}

class _CoachingCard extends StatelessWidget {
  const _CoachingCard({required this.coaching, required this.locale});

  final CoachingModel coaching;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final tone = _toneColor(palette, coaching.type);

    void open() => context.push('/coaching?id=${coaching.id}');

    return AppCard(
      variant: AppCardVariant.raised,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSpacing.allXs,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(coaching.type.icon, color: tone, size: 20),
              ),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  coaching.date.formated(l10n.formatSimpleDate, locale),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              AppSpacing.gapXs,
              StatusPill(
                label: coaching.type.label(l10n),
                tone: coaching.type.tone,
                dense: true,
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            coaching.message,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink2),
          ),
          AppSpacing.gapXs,
          Align(
            alignment: Alignment.bottomRight,
            // O cartão inteiro já abre o insight; este botão é o mesmo
            // destino escrito por extenso, não uma segunda ação. Por isso
            // deixou de ser um `ElevatedButton` pintado com a cor do tipo —
            // que em tema escuro virava texto branco sobre laranja — e virou
            // o que sempre foi: um link.
            child: TextButton.icon(
              onPressed: open,
              style: TextButton.styleFrom(
                foregroundColor: tone,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd,
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: Text(l10n.coachingReviewTips),
            ),
          ),
        ],
      ),
    );
  }
}
