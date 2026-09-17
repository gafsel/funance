import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Conteúdo de uma aba do 50-30-20 no mobile: nome da pool, sinal de
/// estouro e uma barra de 80px com a marca da meta.
///
/// A barra dentro da aba existe para que o usuário veja as três pools de uma
/// vez mesmo só podendo ler uma: sem ela, trocar de aba é a única forma de
/// saber se a outra estourou.
class AllocationTabLabel extends ConsumerWidget {
  const AllocationTabLabel({super.key, required this.allocation});

  final CategoryAllocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final progress = ref.watch(
      FinanceViewProviders.planning503020AllocationProgress(allocation),
    );
    final statusColor = progress.isOver ? Colors.red : Colors.green;
    final label = switch (allocation) {
      CategoryAllocation.essential => l10n.planning503020Essential,
      CategoryAllocation.comfort => l10n.planning503020Comfort,
      CategoryAllocation.investment => l10n.planning503020Investment,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Icon(
              progress.isOver ? Icons.warning : Icons.check_circle,
              size: 14,
              color: statusColor,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              child: LinearProgressIndicator(
                value: progress.currentPercentage.clamp(0.0, 1.0),
                backgroundColor: statusColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 15,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              left: 80 * allocation.idealPercentage,
              top: 0,
              bottom: 0,
              child: Container(width: 2, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
