import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
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
import 'package:funances/core/widgets/error_view.dart';

/// Lançamento em duas telas: escolher a categoria e preencher o formulário.
///
/// O status vem do ponto de entrada ("Registrei" abre como pago, "Agendar"
/// como pendente) e não é mais uma escolha dentro do formulário. Sem status,
/// vale o caminho mais comum: registrar algo que já aconteceu.
///
/// No caminho "Registrei", o formulário ainda oferece os agendamentos
/// pendentes da categoria, para o usuário quitar o que já tinha planejado em
/// vez de criar um lançamento paralelo.
class TransactionWizardScreen extends ConsumerWidget {
  final OrderType type;
  final InstallmentStatus? initialStatus;
  final String? accountIdSource;

  const TransactionWizardScreen({
    super.key,
    required this.type,
    this.initialStatus,
    this.accountIdSource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TransactionWizardArgs(
      type: type,
      accountIdSource: accountIdSource,
    );
    final state = ref.watch(FinanceViewProviders.wizard(args));
    final notifier = ref.read(FinanceViewProviders.wizard(args).notifier);

    return switch (state.step) {
      TransactionWizardStep.category => _CategorySelectionStep(
        type: type,
        onCategorySelected: notifier.selectCategory,
      ),
      TransactionWizardStep.form => TransactionFormScreen.creation(
        type: type,
        category: state.selectedCategory,
        // Sem status no ponto de entrada quem decide é
        // `TransactionFormState.creation`, que assume realizado.
        status: initialStatus,
        accountIdSource: state.accountIdSource,
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
    final summariesAsync = ref.watch(
      PeriodSummaryViewProviders.monthSummary(period.monthKey),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transactionWizardSelectCategory)),
      body: categoriesAsync.when(
        data: (categories) {
          // Categorias de sistema e excluídas não são escolhíveis no wizard.
          final filtered = categories
              .where((c) => c.type == type.categoryType && c.isSelectable)
              .toList();

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
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ErrorView.forError(
                  context,
                  err,
                  onRetry: () => ref.invalidate(CategoryViewProviders.allStream),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorView.forError(
              context,
              err,
              onRetry: () => ref.invalidate(CategoryViewProviders.allStream),
            ),
          ),
        ),
      ),
    );
  }
}
