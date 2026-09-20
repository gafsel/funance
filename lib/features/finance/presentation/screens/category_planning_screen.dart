import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/controllers/category_planning_notifier.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/l10n/app_localizations.dart';

class CategoryPlanningScreen extends ConsumerWidget {
  final CategoryType type;

  /// Categoria que o usuário veio definir (F3.2). Sobe para o topo e nasce
  /// destacada, com [suggestedAmount] já preenchido quando há histórico.
  final String? highlightCategoryId;
  final double? suggestedAmount;

  const CategoryPlanningScreen({
    super.key,
    required this.type,
    this.highlightCategoryId,
    this.suggestedAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = FinanceViewProviders.categoryPlanningForm(
      CategoryPlanningArgs(
        type: type,
        highlightCategoryId: highlightCategoryId,
        suggestedAmount: suggestedAmount,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == CategoryType.income
              ? l10n.planningIncomeLimits
              : l10n.planningExpenseLimits,
        ),
      ),
      body: ManualForm<CategoryPlanningState, void, CategoryPlanningNotifier>(
        provider,
        formBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(child: _buildCategoryList(context, state, notifier)),
              Padding(
                padding: AppSpacing.allMd,
                child: LoadingButton.elevated(
                  onPressed: (loading) async {
                    await loading(snapshot.notifier.submit());
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(l10n.planningSave),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    CategoryPlanningState state,
    CategoryPlanningNotifier notifier,
  ) {
    return ListView.builder(
      padding: AppSpacing.hMd,
      itemCount: state.items.length,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _buildCategoryItem(
          context,
          item,
          notifier,
          isHighlighted: item.category.id == state.highlightCategoryId,
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    CategoryPlanningFormItem item,
    CategoryPlanningNotifier notifier, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        variant: AppCardVariant.raised,
        // A categoria que trouxe o usuário até aqui (pelo nudge de gasto não
        // planejado) fica visivelmente marcada: ele veio decidir UMA coisa.
        borderColor: isHighlighted ? AppColors.gold : null,
        child: Row(
          children: [
            Container(
              padding: AppSpacing.allXs,
              decoration: BoxDecoration(
                // A cor é DADO: é a que o usuário escolheu para a categoria.
                color: item.category.color.asColor().withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.category.icon.asIcon(),
                color: item.category.color.asColor(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category.name, style: theme.textTheme.titleMedium),
                  if (item.planningId != null)
                    Text(
                      // Despesa tem limite; receita tem expectativa.
                      type == CategoryType.income
                          ? AppLocalizations.of(
                              context,
                            )!.planningExpectationDefined
                          : AppLocalizations.of(context)!.planningLimitDefined,
                      // O verde de progresso não é legível como texto sobre
                      // papel claro; aqui o papel é "está definido" = sucesso.
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.successText,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: 80, maxWidth: 200),
              child: MoneyFormField(
                initialValue: item.amount > 0 ? item.amount : null,
                decoration: const InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  notifier.updateAmount(item.category.id, value ?? 0.0);
                },
              ),
            ),
            if (item.amount > 0)
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: palette.dangerText,
                ),
                onPressed: () {
                  notifier.updateAmount(item.category.id, 0);
                },
              ),
          ],
        ),
      ),
    );
  }
}
