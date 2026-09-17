import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_popup_menu_item.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Cabeçalho do detalhe de transação: ícone, descrição, data, selos e menu.
///
/// O menu "…" é o que justifica o arquivo próprio: editar, excluir e voltar
/// para pendente são três fluxos com confirmação e cascata de replicação, e
/// eles ficavam intercalados com a montagem visual do cabeçalho. Aqui o
/// cabeçalho só desenha — quem sabe executar as ações continua sendo o sheet,
/// que as entrega por callback.
class TransactionDetailHeader extends StatelessWidget {
  final InstallmentModel installment;
  final Color amountColor;
  final VoidCallback? onUpdated;
  final Future<void> Function() onDelete;
  final Future<void> Function() onBackToPending;

  const TransactionDetailHeader({
    super.key,
    required this.installment,
    required this.amountColor,
    required this.onUpdated,
    required this.onDelete,
    required this.onBackToPending,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final locale = context.locale;

    return Padding(
      padding: AppSpacing.allMd,
      child: Row(
        spacing: AppSpacing.xs,
        children: [
          CategoryIcon.forInstallment(installment),
          Expanded(
            child: Column(
              spacing: AppSpacing.xxs,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.description,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  DateFormat.yMMMMd(locale).format(installment.referenceDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink2,
                  ),
                ),
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    // A cor do selo é a do tipo do lançamento — é dado, não
                    // decoração, e por isso vai por `color:` e não por `tone:`.
                    StatusPill(
                      label: l10n.fromOrderType(installment.type),
                      color: amountColor,
                      dense: true,
                    ),
                    if (installment.installmentType ==
                            InstallmentType.installment &&
                        installment.installmentNumber != null &&
                        installment.installmentCount != null)
                      StatusPill(
                        label: l10n.installmentCountDescription(
                          installment.installmentCount!,
                          installment.installmentNumber!,
                        ),
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () async {
                  final navigator = Navigator.of(context);

                  final updated = await context.push(
                    '/transactions/form'
                    '?installmentId=${installment.id}',
                  );

                  if (updated == true) {
                    onUpdated?.call();
                    navigator.pop();
                  }
                },
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    Text(l10n.editButton),
                  ],
                ),
              ),
              LoadingPopupMenuItem(
                onTap: (loading) async {
                  await loading(onDelete());
                },
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: palette.dangerText,
                    ),
                    Text(
                      l10n.deleteButton,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.dangerText,
                      ),
                    ),
                  ],
                ),
              ),
              if (installment.status != InstallmentStatus.settled &&
                  installment.amount > 0 &&
                  (installment.status == InstallmentStatus.paid ||
                      installment.status == InstallmentStatus.settled))
                LoadingPopupMenuItem(
                  onTap: (loading) async {
                    await loading(onBackToPending());
                  },
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      // Era o turquesa profundo bruto: acento que funcionava
                      // sobre papel claro e sumiria no tema escuro. O papel
                      // equivalente é a tinta teal da superfície corrente.
                      Icon(Icons.undo, size: 20, color: palette.tealText),
                      Text(
                        l10n.returnToPending,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.tealText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
