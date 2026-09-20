import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_typography.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:intl/intl.dart';

/// Cartão de uma categoria dentro de uma pool.
///
/// Em tela larga ele é arrastável entre pools; no mobile, o mesmo cartão sem
/// arrasto e com um menu de três pontos. O corpo era uma função `_card(...)`
/// chamada TRÊS vezes com os mesmos seis parâmetros posicionais (normal,
/// fantasma do arrasto e sombra) — agora é um widget e as três chamadas são
/// a mesma linha.
class PlanningCategoryCard extends ConsumerWidget {
  const PlanningCategoryCard({
    super.key,
    required this.item,
    this.isMobile = false,
  });

  final CategoryPlanning503020Item item;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _PlanningCategoryCardBody(item: item, isMobile: isMobile);

    if (isMobile) return body;

    return Draggable<String>(
      data: item.category.id,
      feedback: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 200,
          child: AppCard(
            padding: AppSpacing.allXs,
            child: Text(item.category.displayName(context.l10n)),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: body),
      child: body,
    );
  }
}

class _PlanningCategoryCardBody extends ConsumerWidget {
  const _PlanningCategoryCardBody({required this.item, required this.isMobile});

  final CategoryPlanning503020Item item;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final currencyFormat = NumberFormat.simpleCurrency(locale: context.locale);

    // O limite mensal ("geral") manda quando existe; sem ele, a régua é a
    // soma do que já foi agendado para a categoria.
    final isOverGeneral = item.generalAmount > 0;
    final actualOverLimit = isOverGeneral
        ? item.actualAmount > item.generalAmount
        : item.actualAmount > item.specificAmount;
    final specificOverLimit =
        isOverGeneral && item.specificAmount > item.generalAmount;

    return AppCard(
      variant: AppCardVariant.raised,
      padding: AppSpacing.allSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.category.displayName(context.l10n),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (isMobile)
                PopupMenuButton<CategoryAllocation>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (allocation) {
                    ref
                        .read(FinanceViewProviders.planning503020.notifier)
                        .moveCategory(item.category.id, allocation);
                  },
                  itemBuilder: (context) => [
                    for (final allocation in CategoryAllocation.values)
                      PopupMenuItem(
                        value: allocation,
                        child: Text(switch (allocation) {
                          CategoryAllocation.essential =>
                            l10n.planning503020Essential,
                          CategoryAllocation.comfort =>
                            l10n.planning503020Comfort,
                          CategoryAllocation.investment =>
                            l10n.planning503020Investment,
                        }),
                      ),
                  ],
                ),
            ],
          ),
          AppSpacing.gapSm,
          MoneyFormField(
            key: ValueKey("${item.planningId}_${item.category.id}"),
            initialValue: item.generalAmount > 0 ? item.generalAmount : null,
            // Preenchimento, borda e respiro do campo já vêm do tema.
            decoration: InputDecoration(
              labelText: l10n.planning503020MonthlyLimitLabel,
            ),
            onChanged: (value) {
              ref
                  .read(FinanceViewProviders.planning503020.notifier)
                  .updateAmount(item.category.id, value ?? 0.0);
            },
          ),
          AppSpacing.gapXs,
          _AmountRow(
            label: l10n.planning503020ActualLabel,
            value: currencyFormat.format(item.actualAmount),
            isOver: actualOverLimit,
          ),
          AppSpacing.gapXxs,
          _AmountRow(
            label: context.l10n.planning503020AlreadyPlanned,
            value: currencyFormat.format(item.specificAmount),
            isOver: specificOverLimit,
          ),
          if (specificOverLimit) ...[
            AppSpacing.gapXs,
            Container(
              padding: AppSpacing.allXs,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.brSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: palette.warningText, size: 14),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      l10n.planning503020AlertSpecificGreater,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.warningText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Já gasto" e "Já previsto": mesma linha, muda o rótulo, o valor e se ele
/// passou do limite.
class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    required this.isOver,
  });

  final String label;
  final String value;
  final bool isOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: palette.ink2),
        ),
        Text(
          value,
          style: theme.textTheme.labelMedium?.tabularFigures.copyWith(
            color: isOver ? palette.dangerText : palette.ink,
          ),
        ),
      ],
    );
  }
}
