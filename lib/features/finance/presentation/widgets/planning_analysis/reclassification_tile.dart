import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';

/// Sugestão de mudar a alocação de uma categoria, com o botão que aplica.
///
/// É o único item da análise que MUDA dado do usuário — reclassificar mexe na
/// categoria de verdade. Quem escreve é a folha, que conhece o serviço e sabe
/// remover o item da lista depois; aqui fica só o "de → para" e o botão.
class ReclassificationTile extends StatelessWidget {
  final Planning503020AnalysisCategory item;
  final String currentLabel;
  final String suggestedLabel;
  final VoidCallback onApply;

  const ReclassificationTile({
    super.key,
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
