import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';
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
    backgroundColor: Colors.transparent,
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

  Color _statusColor(Planning503020AnalysisStatus status) {
    return switch (status) {
      Planning503020AnalysisStatus.ok => AppColors.limeGreen,
      Planning503020AnalysisStatus.above => AppColors.coralOrange,
      Planning503020AnalysisStatus.below => AppColors.vibrantTeal,
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
      color: theme.colorScheme.onSurfaceVariant,
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
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              textStyle: theme.textTheme.labelSmall,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
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
    final analysis = widget.analysis;
    final reclassifications = analysis.reclassifications
        .where((item) => !_appliedCategoryIds.contains(item.categoryId))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.deepTurquoise,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.planningAnalysisTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.planningAnalysisProjectedIncome(
              analysis.projectedIncome.asCurrency(locale: context.locale),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (analysis.summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.deepTurquoise.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(analysis.summary, style: theme.textTheme.bodyMedium),
            ),
          const SizedBox(height: 16),
          for (final group in analysis.groups) ...[
            _AllocationBar(
              label: _allocationLabel(l10n, group.allocation),
              group: group,
            ),
            const SizedBox(height: 12),
          ],
          if (analysis.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.planningAnalysisCategoriesTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final category in analysis.categories)
              _CategoryTile(
                category: category,
                statusColor: _statusColor(category.status),
                statusLabel: _statusLabel(l10n, category.status),
              ),
          ],
          if (reclassifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.planningAnalysisReclassTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in reclassifications)
              _ReclassificationTile(
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
            const SizedBox(height: 16),
            Text(
              l10n.planningAnalysisInsightsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (final insight in analysis.insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: AppColors.antiqueGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(insight, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ),
          ],
          if (widget.onRefresh != null) ...[
            const SizedBox(height: 8),
            _buildCacheInfo(context, l10n, theme),
          ],
        ],
      ),
    );
  }
}

class _AllocationBar extends StatelessWidget {
  final String label;
  final Planning503020AnalysisGroup group;

  const _AllocationBar({required this.label, required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;
    final isOver = group.currentPct > group.targetPct;
    final barColor = isOver ? AppColors.coralOrange : AppColors.limeGreen;

    final deltaText = group.deltaBRL > 0
        ? l10n.planningAnalysisAboveBy(
            group.deltaBRL.asCurrency(locale: locale),
          )
        : group.deltaBRL < 0
        ? l10n.planningAnalysisBelowBy(
            (-group.deltaBRL).asCurrency(locale: locale),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${l10n.planningAnalysisCurrentPct((group.currentPct / 100).asPercent(locale: locale))} · '
              '${l10n.planningAnalysisTargetPct((group.targetPct / 100).asPercent(locale: locale))}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: 12,
                  width: maxWidth * (group.currentPct / 100).clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Positioned(
                  left: (maxWidth * (group.targetPct / 100)).clamp(
                    0.0,
                    maxWidth - 2,
                  ),
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: AppColors.darkNavy),
                ),
              ],
            );
          },
        ),
        if (deltaText != null) ...[
          const SizedBox(height: 2),
          Text(
            deltaText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isOver ? AppColors.coralOrange : AppColors.vibrantTeal,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Planning503020AnalysisCategory category;
  final Color statusColor;
  final String statusLabel;

  const _CategoryTile({
    required this.category,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.categoryName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.planningAnalysisIdealValue(
              category.idealMonthlyAmount.asCurrency(locale: locale),
              (category.idealPctOfIncome / 100).asPercent(locale: locale),
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (category.savingTip != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 14,
                  color: AppColors.antiqueGold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    category.savingTip!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReclassificationTile extends StatelessWidget {
  final Planning503020AnalysisCategory item;
  final String currentLabel;
  final String suggestedLabel;
  final VoidCallback onApply;

  const _ReclassificationTile({
    required this.item,
    required this.currentLabel,
    required this.suggestedLabel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successGold.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.antiqueGold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.categoryName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(currentLabel, style: theme.textTheme.labelSmall),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              Text(
                suggestedLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepTurquoise,
                ),
              ),
            ],
          ),
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.reason,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: onApply,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(l10n.planningAnalysisApply),
            ),
          ),
        ],
      ),
    );
  }
}
