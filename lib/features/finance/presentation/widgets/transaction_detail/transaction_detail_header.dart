import 'package:flutter/material.dart';
import 'package:funances/core/form/loading_popup_menu_item.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
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
    final locale = context.locale;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 8,
        children: [
          CategoryIcon.forInstallment(installment),
          Expanded(
            child: Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  installment.description,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),Text(
                  DateFormat.yMMMMd(
                    locale,
                  ).format(installment.referenceDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: amountColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: amountColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        l10n.fromOrderType(installment.type),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (installment.installmentType ==
                        InstallmentType.installment &&
                        installment.installmentNumber != null &&
                        installment.installmentCount != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Text(
                          l10n.installmentCountDescription(
                            installment.installmentCount!,
                            installment.installmentNumber!,
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
                  spacing: 12,
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
                  spacing: 12,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.error,
                    ),
                    Text(
                      l10n.deleteButton,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
              if (installment.status !=
                      InstallmentStatus.settled &&
                  installment.amount > 0 &&
                  (installment.status == InstallmentStatus.paid ||
                      installment.status ==
                          InstallmentStatus.settled))
                LoadingPopupMenuItem(
                  onTap: (loading) async {
                    await loading(onBackToPending());
                  },
                  child: Row(
                    spacing: 12,
                    children: [
                      const Icon(
                        Icons.undo,
                        size: 20,
                        color: AppColors.deepTurquoise,
                      ),
                      Text(
                        l10n.returnToPending,
                        style: const TextStyle(
                          color: AppColors.deepTurquoise,
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
