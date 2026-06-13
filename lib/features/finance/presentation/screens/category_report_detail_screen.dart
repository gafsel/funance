import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/presentation/widgets/category_detail_item.dart';
import 'package:funances/features/finance/presentation/widgets/category_detail_table.dart';
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
    final period = ref.watch(HomeViewProviders.period);
    final locale = context.locale;

    final sortedSummaries = List<OverviewCategorySummary>.from(state.summary)
      ..sort((a, b) {
        final isAOthers = a.category.name.toLowerCase() == 'outros' || a.category.id == 'others';
        final isBOthers = b.category.name.toLowerCase() == 'outros' || b.category.id == 'others';

        if (isAOthers && !isBOthers) return 1;
        if (!isAOthers && isBOthers) return -1;

        final valA = a.plannedAmount > a.actualAmount ? a.plannedAmount : a.actualAmount;
        final valB = b.plannedAmount > b.actualAmount ? b.plannedAmount : b.actualAmount;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CategoryDetailTable(
                summaries: sortedSummaries,
                type: type,
                locale: locale,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedSummaries.length,
            itemBuilder: (context, index) {
              return CategoryDetailItem(
                summary: sortedSummaries[index],
                type: type,
                locale: locale,
              );
            },
          );
        },
      ),
    );
  }
}
