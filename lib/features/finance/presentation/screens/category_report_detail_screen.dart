import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class CategoryReportDetailScreen extends ConsumerWidget {
  final CategoryType type;

  const CategoryReportDetailScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final provider = type == CategoryType.expense
        ? HomeViewProviders.summaryExpensesFull
        : HomeViewProviders.summaryIncomesFull;
    
    final state = ref.watch(provider);
    final viewType = ref.watch(HomeViewProviders.viewType);
    final period = ref.watch(HomeViewProviders.period);
    final locale = context.locale;

    // Nota: O state atual já pode estar agrupado se o provider original agrupar.
    // Idealmente, criaríamos um SummaryDetailProvider que não limite a 10.
    
    final sortedSummaries = List<OverviewCategorySummary>.from(state.summary)
      ..sort((a, b) {
        final valA =
            a.plannedAmount > a.actualAmount ? a.plannedAmount : a.actualAmount;
        final valB =
            b.plannedAmount > b.actualAmount ? b.plannedAmount : b.actualAmount;
        return valB.compareTo(valA);
      });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(l10n.categoryReportDetails),
            Text(
              period.formated('MMMM yyyy', locale),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sortedSummaries.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final summary = sortedSummaries[index];
          final color = viewType == SummaryViewType.planning
              ? summary.category.color.asColor().withValues(alpha: 0.4)
              : summary.category.color.asColor();

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                summary.category.icon.asIcon(),
                color: color,
              ),
            ),
            title: Text(
              summary.category.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewType == SummaryViewType.planning ||
                    viewType == SummaryViewType.comparison)
                  Text(
                      '${l10n.overviewPlanning}: ${summary.plannedAmount.asCurrency(locale: locale)}'),
                if (viewType == SummaryViewType.effective ||
                    viewType == SummaryViewType.comparison)
                  Text(
                      '${l10n.overviewEffective}: ${summary.actualAmount.asCurrency(locale: locale)}'),
              ],
            ),
            trailing: viewType == SummaryViewType.comparison &&
                    summary.plannedAmount > 0
                ? SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: (summary.actualAmount / summary.plannedAmount)
                          .clamp(0, 1),
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: summary.category.color.asColor(),
                    ),
                  )
                : Text(
                    (viewType == SummaryViewType.planning
                            ? summary.plannedAmount
                            : summary.actualAmount)
                        .asCurrency(locale: locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.deepTurquoise,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
