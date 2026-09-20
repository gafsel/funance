import 'package:flutter/material.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_payment_sheet.dart';
import 'package:intl/intl.dart';

/// O que o monstro guarda: as parcelas da semana que ainda não foram pagas.
///
/// O botão **não** escreve nada por conta própria: ele abre a
/// [TransactionPaymentSheet], que é o caminho de quitação que o app já tem.
/// Uma POC que inventasse a própria escrita de parcela estaria testando o
/// código dela, não o produto.
class ArenaMonsterSheet extends StatelessWidget {
  const ArenaMonsterSheet({super.key, required this.installments});

  final List<InstallmentModel> installments;

  /// Devolve a parcela QUITADA, quando houve quitação. É esse retorno que a
  /// Arena transforma em golpe.
  static Future<InstallmentModel?> show(
    BuildContext context,
    List<InstallmentModel> installments,
  ) {
    return showModalBottomSheet<InstallmentModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: (context) => ArenaMonsterSheet(installments: installments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.arenaWeekInstallments, style: theme.textTheme.titleLarge),
            AppSpacing.gapSm,
            if (installments.isEmpty)
              Padding(
                padding: AppSpacing.vMd,
                child: Text(
                  l10n.arenaNoPending,
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: installments.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _InstallmentRow(installment: installments[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({required this.installment});

  final InstallmentModel installment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return Padding(
      padding: AppSpacing.vXs,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                installment.category?.color.asColor().withValues(alpha: 0.16) ??
                palette.line,
            child: Icon(
              installment.isInvoice
                  ? Icons.credit_card
                  : installment.category?.icon.asIcon() ?? Icons.category,
              size: 16,
              color: installment.category?.color.asColor() ?? palette.ink2,
            ),
          ),
          AppSpacing.gapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayOr(installment.description, l10n.noDescription),
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat.MMMEd(
                    context.locale,
                  ).format(installment.dueDate),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          AppSpacing.gapXs,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(installment.amount, style: theme.textTheme.titleSmall),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final paid = await TransactionPaymentSheet.show(
                    context,
                    installment,
                  );

                  if (paid == null) return;
                  // Fecha a folha DEVOLVENDO a parcela quitada: é o sinal de
                  // que a Arena precisa para animar o golpe com o valor
                  // certo, sem ficar adivinhando pelo estado que chega depois.
                  navigator.pop(paid);
                },
                child: Text(l10n.arenaConfirmPaid),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
