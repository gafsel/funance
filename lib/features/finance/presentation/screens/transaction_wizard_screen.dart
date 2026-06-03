import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

class TransactionWizardScreen extends ConsumerWidget {
  final OrderType type;
  final InstallmentStatus? initialStatus;
  final bool skipTransactions;

  const TransactionWizardScreen({
    super.key,
    required this.type,
    this.initialStatus,
    this.skipTransactions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TransactionWizardArgs(type: type, skipTransactions: skipTransactions);
    final state = ref.watch(FinanceViewProviders.wizard(args));
    final notifier = ref.read(FinanceViewProviders.wizard(args).notifier);

    return switch (state.step) {
      TransactionWizardStep.category => _CategorySelectionStep(
        type: type,
        onCategorySelected: notifier.selectCategory,
      ),
      TransactionWizardStep.transactions => _PendingTransactionsStep(
        type: type,
        category: state.selectedCategory,
        onInstallmentSelected: notifier.selectInstallment,
        onBack: notifier.back,
      ),
      _ =>
        state.selectedInstallment != null
            ? TransactionFormScreen.updateInstallment(
                installment: state.selectedInstallment!,
                status: InstallmentStatus.paid,
              )
            : TransactionFormScreen.creation(
                type: type,
                category: state.selectedCategory,
                status: initialStatus,
              ),
    };
  }
}

class _CategorySelectionStep extends ConsumerWidget {
  final OrderType type;
  final ValueChanged<CategoryModel> onCategorySelected;

  const _CategorySelectionStep({
    required this.type,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.locale;
    final theme = Theme.of(context);

    // Watch both categories and summaries to show progress
    final categoriesAsync = ref.watch(CategoryViewProviders.allStream);
    final period = ref.watch(HomeViewProviders.period);
    final summariesAsync = ref.watch(PeriodSummaryViewProviders.monthSummary(period));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionWizardSelectCategory)),
      body: categoriesAsync.when(
        data: (categories) {
          final filtered = categories.where((c) => c.type == type.categoryType).toList();

          return summariesAsync.when(
            data: (summaries) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                          ? 3
                          : 2;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 100, // Fixed height for each item
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final category = filtered[index];
                      final summary = summaries.firstWhere(
                        (s) => s.category.id == category.id,
                        orElse: () => OverviewCategorySummary(
                          category: category,
                          specificPlannedAmount: 0,
                          generalPlannedAmount: 0,
                          actualAmount: 0,
                        ),
                      );

                      final progress = summary.plannedAmount > 0
                          ? summary.actualAmount / summary.plannedAmount
                          : null;

                      final bool isOverBudget;
                      if (type == OrderType.income) {
                        isOverBudget = progress != null && progress >= 1.0;
                      } else {
                        isOverBudget = progress != null && progress > 1.0;
                      }

                      final progressColor = progress == null
                          ? category.color.asColor()
                          : type == OrderType.income
                              ? (progress >= 1.0 ? Colors.green : AppColors.successGold)
                              : (progress > 1.0 ? Colors.red : category.color.asColor());

                      return InkWell(
                        onTap: () => onCategorySelected(category),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isOverBudget
                                  ? progressColor.withValues(alpha: 0.5)
                                  : theme.dividerColor.withValues(alpha: 0.1),
                              width: isOverBudget ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isOverBudget ? progressColor.withValues(alpha: 0.05) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isOverBudget ? progressColor : category.color.asColor(),
                                    child: Icon(
                                      category.icon.asIcon(),
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isOverBudget ? progressColor : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (summary.plannedAmount > 0)
                                          Text(
                                            '${summary.actualAmount.asCurrency(locale: locale)} / ${summary.plannedAmount.asCurrency(locale: locale)}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 10,
                                              color: isOverBudget ? progressColor : null,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        else
                                          Text(
                                            summary.actualAmount.asCurrency(locale: locale),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontSize: 10,
                                              color: isOverBudget ? progressColor : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (progress != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress.clamp(0.0, 1.0),
                                    backgroundColor: progressColor.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progressColor,
                                    ),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text(err.toString())),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }
}

class _PendingTransactionsStep extends ConsumerWidget {
  final OrderType type;
  final CategoryModel? category;
  final ValueChanged<InstallmentModel?> onInstallmentSelected;
  final VoidCallback onBack;

  const _PendingTransactionsStep({
    required this.type,
    this.category,
    required this.onInstallmentSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.locale;

    final installmentsAsync = ref.watch(
      FinanceViewProviders.pendingInstallments((
        type: type,
        categoryId: category?.id,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionWizardSelectPending),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 600;

          return installmentsAsync.when(
            data: (installments) {
              final itemCount = installments.length + 1;

              if (isLargeScreen) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      itemCount: itemCount,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemBuilder: (context, index) => _buildTransactionItem(
                        context,
                        ref,
                        index,
                        installments,
                        l10n,
                        locale,
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: itemCount,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemBuilder: (context, index) => _buildTransactionItem(
                  context,
                  ref,
                  index,
                  installments,
                  l10n,
                  locale,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text(err.toString())),
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    List<InstallmentModel> installments,
    dynamic l10n,
    String locale,
  ) {
    final theme = Theme.of(context);

    if (index == installments.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () => onInstallmentSelected(null),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.transactionWizardNewTransaction,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final installment = installments[index];
    final isExpense = installment.type == OrderType.expense;
    final isTransfer = installment.type == OrderType.transfer;

    Color amountColor;
    if (isTransfer) {
      amountColor = theme.colorScheme.primary;
    } else if (isExpense) {
      amountColor = AppColors.error;
    } else {
      amountColor = AppColors.limeGreen;
    }

    final sourceAccount = installment.accountIdSource != null
        ? ref.watch(AccountViewProviders.byId(installment.accountIdSource!)).valueOrNull
        : null;

    final targetAccount = isTransfer && installment.accountIdTarget != null
        ? ref.watch(AccountViewProviders.byId(installment.accountIdTarget!)).valueOrNull
        : null;

    final categoryColor = category?.color.asColor() ?? theme.colorScheme.primary;
    final categoryIcon = category?.icon.asIcon() ?? Icons.help_outline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => onInstallmentSelected(installment),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isTransfer ? Icons.swap_horiz : categoryIcon,
                  color: categoryColor,
                  size: 20,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      installment.description,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isTransfer
                          ? '${sourceAccount?.name ?? '...'} ➡ ${targetAccount?.name ?? '...'}'
                          : sourceAccount?.name ?? '...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      installment.dueDate.formated(l10n.formatSimpleDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                installment.amount.asCurrency(locale: locale),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
