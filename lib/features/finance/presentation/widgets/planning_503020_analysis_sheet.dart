import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';
import 'package:funances/features/finance/presentation/widgets/planning_analysis/allocation_bar.dart';
import 'package:funances/features/finance/presentation/widgets/planning_analysis/category_tile.dart';
import 'package:funances/features/finance/presentation/widgets/planning_analysis/reclassification_tile.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Abre o bottom sheet com o resultado da análise ideal 50-30-20.
Future<void> showPlanning503020AnalysisSheet(
  BuildContext context,
  Planning503020Analysis analysis, {
  VoidCallback? onRefresh,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Planning503020AnalysisSheet(
        analysis: analysis,
        scrollController: scrollController,
        onRefresh: onRefresh,
      ),
    ),
  );
}

class Planning503020AnalysisSheet extends ConsumerStatefulWidget {
  final Planning503020Analysis analysis;
  final ScrollController scrollController;
  final VoidCallback? onRefresh;

  const Planning503020AnalysisSheet({
    super.key,
    required this.analysis,
    required this.scrollController,
    this.onRefresh,
  });

  @override
  ConsumerState<Planning503020AnalysisSheet> createState() =>
      _Planning503020AnalysisSheetState();
}

class _Planning503020AnalysisSheetState
    extends ConsumerState<Planning503020AnalysisSheet> {
  final Set<String> _appliedCategoryIds = {};

  String _allocationLabel(
    AppLocalizations l10n,
    CategoryAllocation allocation,
  ) {
    return switch (allocation) {
      CategoryAllocation.essential => l10n.planning503020Essential,
      CategoryAllocation.comfort => l10n.planning503020Comfort,
      CategoryAllocation.investment => l10n.planning503020Investment,
    };
  }

  /// A cor do status vira TEXTO dentro da pílula da categoria, então vem dos
  /// papéis de tinta da paleta e não dos acentos de preenchimento.
  Color _statusColor(AppPalette palette, Planning503020AnalysisStatus status) {
    return switch (status) {
      Planning503020AnalysisStatus.ok => palette.successText,
      Planning503020AnalysisStatus.above => palette.warningText,
      Planning503020AnalysisStatus.below => palette.tealText,
    };
  }

  String _statusLabel(
    AppLocalizations l10n,
    Planning503020AnalysisStatus status,
  ) {
    return switch (status) {
      Planning503020AnalysisStatus.ok => l10n.planningAnalysisStatusOk,
      Planning503020AnalysisStatus.above => l10n.planningAnalysisStatusAbove,
      Planning503020AnalysisStatus.below => l10n.planningAnalysisStatusBelow,
    };
  }

  Future<void> _applyReclassification(
    Planning503020AnalysisCategory item,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(CategoryDomainProviders.service);
    final suggested = item.suggestedAllocation;
    if (suggested == null) return;

    try {
      final categories = await service.getCategories().first;
      final category = categories
          .where((c) => c.id == item.categoryId)
          .firstOrNull;
      if (category == null) {
        throw Exception('Category ${item.categoryId} not found');
      }

      await service.update(category.copyWith(allocation: suggested));

      if (!mounted) return;
      setState(() => _appliedCategoryIds.add(item.categoryId));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.planningAnalysisApplied)),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.planningAnalysisApplyError)),
      );
    }
  }

  /// Informação honesta sobre o cache do servidor.
  ///
  /// Uma análise é reaproveitada por alguns dias; pedir outra antes disso não
  /// geraria nada, então em vez de um botão que não faz nada mostramos quando
  /// a atual foi gerada e quando dá para pedir a próxima.
  Widget _buildCacheInfo(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final analysis = widget.analysis;
    final generatedAt = analysis.createdAt;

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: context.palette.ink2,
    );

    return Column(
      children: [
        if (generatedAt != null)
          Text(
            l10n.planningAnalysisGeneratedAt(
              generatedAt.formated(l10n.formatSimpleDate),
            ),
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        if (analysis.canRegenerate)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRefresh!();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(l10n.planningAnalysisGenerateNew),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.ink2,
              textStyle: theme.textTheme.labelSmall,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              l10n.planningAnalysisNextAvailable(analysis.daysUntilRenewal),
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final analysis = widget.analysis;
    final reclassifications = analysis.reclassifications
        .where((item) => !_appliedCategoryIds.contains(item.categoryId))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: AppRadius.brSheet,
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.line,
                borderRadius: AppRadius.brXs,
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.auto_awesome, color: palette.ink, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.planningAnalysisTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          AppSpacing.gapXxs,
          Text(
            l10n.planningAnalysisProjectedIncome(
              analysis.projectedIncome.asCurrency(locale: context.locale),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
          ),
          AppSpacing.gapSm,
          if (analysis.summary.isNotEmpty)
            AppCard(
              padding: AppSpacing.allSm,
              child: Text(analysis.summary, style: theme.textTheme.bodyMedium),
            ),
          AppSpacing.gapMd,
          for (final group in analysis.groups) ...[
            AllocationBar(
              label: _allocationLabel(l10n, group.allocation),
              group: group,
            ),
            AppSpacing.gapSm,
          ],
          if (analysis.categories.isNotEmpty) ...[
            AppSpacing.gapXs,
            Text(
              l10n.planningAnalysisCategoriesTitle,
              style: theme.textTheme.titleSmall,
            ),
            AppSpacing.gapXs,
            for (final category in analysis.categories)
              CategoryTile(
                category: category,
                statusColor: _statusColor(palette, category.status),
                statusLabel: _statusLabel(l10n, category.status),
              ),
          ],
          if (reclassifications.isNotEmpty) ...[
            AppSpacing.gapMd,
            Text(
              l10n.planningAnalysisReclassTitle,
              style: theme.textTheme.titleSmall,
            ),
            AppSpacing.gapXs,
            for (final item in reclassifications)
              ReclassificationTile(
                item: item,
                currentLabel: _allocationLabel(l10n, item.currentAllocation),
                suggestedLabel: _allocationLabel(
                  l10n,
                  item.suggestedAllocation ?? item.currentAllocation,
                ),
                onApply: () => _applyReclassification(item),
              ),
          ],
          if (analysis.insights.isNotEmpty) ...[
            AppSpacing.gapMd,
            Text(
              l10n.planningAnalysisInsightsTitle,
              style: theme.textTheme.titleSmall,
            ),
            AppSpacing.gapXs,
            for (final insight in analysis.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(insight, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
          if (widget.onRefresh != null) ...[
            AppSpacing.gapXs,
            _buildCacheInfo(context, l10n, theme),
          ],
        ],
      ),
    );
  }
}
