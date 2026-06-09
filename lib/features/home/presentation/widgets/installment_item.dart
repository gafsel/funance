import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class InstallmentItem extends StatelessWidget {
  final InstallmentMission installmentInfo;

  const InstallmentItem({
    super.key,
    required this.installmentInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final inst = installmentInfo.installment;

    final isCompleted =
        inst.status == InstallmentStatus.settled ||
        inst.status == InstallmentStatus.paid;
    final isSuccess = installmentInfo.earnedXp > 0;
    final displayXp = isCompleted
        ? (inst.xp ?? installmentInfo.earnedXp)
        : installmentInfo.xpValue;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () =>
            context.push('/transactions/form', extra: {'installment': inst}),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: inst.isInvoice
                    ? AppColors.error
                    : inst.type == OrderType.transfer
                    ? AppColors.brightCyan
                    : inst.category?.color.asColor().withValues(alpha: 0.1) ??
                          Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                inst.isInvoice
                    ? Icons.credit_card
                    : inst.type == OrderType.transfer
                    ? Icons.swap_horiz
                    : inst.category?.icon.asIcon() ?? Icons.category,
                size: 20,
                color: inst.category?.color.asColor() ?? Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inst.description, style: theme.textTheme.bodyMedium),
                  Text(
                    DateFormat.E(
                      context.locale.toString(),
                    ).format(inst.referenceDate),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  inst.referenceAmount.asCurrency(locale: context.locale),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.xpValue(displayXp.toInt().toString()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isCompleted
                            ? isSuccess
                                  ? AppColors.success
                                  : AppColors.error
                            : theme.colorScheme.outline,
                        fontWeight: isCompleted ? FontWeight.bold : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      Icon(
                        isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 20,
                        color: isSuccess ? AppColors.success : AppColors.error,
                      )
                    else
                      Icon(
                        Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: theme.colorScheme.outline,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
