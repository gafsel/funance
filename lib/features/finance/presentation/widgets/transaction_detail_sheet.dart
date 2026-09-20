import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail/detail_item.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail/transaction_detail_accounts.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_detail/transaction_detail_header.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_payment_sheet.dart';
import 'package:funances/features/workspace/presentation/widgets/category_picker_sheet.dart';

class TransactionDetailSheet extends ConsumerStatefulWidget {
  final InstallmentModel installment;
  final VoidCallback? onUpdated;

  const TransactionDetailSheet({
    super.key,
    required this.installment,
    this.onUpdated,
  });

  static Future<void> show(
    BuildContext context,
    InstallmentModel installment, {
    VoidCallback? onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => TransactionDetailSheet(
        installment: installment,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  ConsumerState<TransactionDetailSheet> createState() =>
      _TransactionDetailSheetState();
}

class _TransactionDetailSheetState
    extends ConsumerState<TransactionDetailSheet> {
  late InstallmentModel _currentInstallment;

  @override
  void initState() {
    super.initState();
    _currentInstallment = widget.installment;
  }

  Future<void> _changeCategory() async {
    final selectedCategory = await CategoryPickerSheet.show(
      context,
      categoryType: _currentInstallment.type.categoryType,
      title: context.l10n.category,
      showClearOption: false,
      showAddOption: true,
    );

    if (selectedCategory != null && mounted) {
      ReplicationCascade cascade = ReplicationCascade.none;
      if (_currentInstallment.installmentType != InstallmentType.single) {
        final result = await ReplicationCascadeDialog.showUpdate(context);
        if (result == null) return;
        cascade = result;
      }

      final notifier = ref.read(
        FinanceViewProviders.updateInstallmentForm(
          _currentInstallment,
        ).notifier,
      );

      notifier.updateReplicationCascade(cascade);
      notifier.updateCategory(selectedCategory);

      final result = await notifier.submit();

      if (result is InstallmentModel) {
        widget.onUpdated?.call();

        setState(() {
          _currentInstallment = result;
        });
      }
    }
  }

  Future<void> _registerPayment() async {
    final result = await TransactionPaymentSheet.show(
      context,
      _currentInstallment,
    );

    if (mounted && result is InstallmentModel) {
      final notifier = ref.read(
        FinanceViewProviders.updateInstallmentForm(
          _currentInstallment,
        ).notifier,
      );

      notifier.updateStatus(result.status);
      notifier.updateReplicationCascade(ReplicationCascade.none);
      notifier.updateAccountIdSource(result.accountIdSource);
      notifier.updatePaidDate(result.paidDate);
      notifier.updatePaidAmount(result.paidAmount);

      widget.onUpdated?.call();

      setState(() {
        _currentInstallment = result;
      });
    }
  }

  Future<void> _backToPending() async {
    final notifier = ref.read(
      FinanceViewProviders.updateInstallmentForm(_currentInstallment).notifier,
    );

    notifier.updateStatus(InstallmentStatus.pending);
    notifier.updateReplicationCascade(ReplicationCascade.none);

    final result = await notifier.submit();

    if (result is InstallmentModel) {
      widget.onUpdated?.call();
      setState(() {
        _currentInstallment = result;
      });
    }
  }

  Future<void> _deleteTransaction() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reconciliationConfirm),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ReplicationCascade cascade = ReplicationCascade.none;
      if (_currentInstallment.installmentType != InstallmentType.single) {
        final result = await ReplicationCascadeDialog.showDeletion(context);
        if (result == null) return;
        cascade = result;
      }

      final notifier = ref.read(
        FinanceViewProviders.updateInstallmentForm(widget.installment).notifier,
      );

      notifier.updateReplicationCascade(cascade);

      await notifier.delete();

      widget.onUpdated?.call();
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final mq = MediaQuery.of(context);

    final isExpense = _currentInstallment.type == OrderType.expense;
    final isTransfer = _currentInstallment.type == OrderType.transfer;

    Color amountColor;
    if (isTransfer) {
      amountColor = theme.colorScheme.primary;
    } else if (isExpense) {
      amountColor = palette.dangerText;
    } else {
      amountColor = palette.successText;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: mq.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TransactionDetailHeader(
            installment: _currentInstallment,
            amountColor: amountColor,
            onUpdated: widget.onUpdated,
            onDelete: _deleteTransaction,
            onBackToPending: _backToPending,
          ),
          const Divider(),
          Padding(
            padding: AppSpacing.allMd,
            child: Column(
              spacing: AppSpacing.xxs,
              children: [
                Container(
                  padding: AppSpacing.vMd,
                  alignment: Alignment.center,
                  child: MoneyText(
                    _currentInstallment.referenceAmount,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: amountColor,
                    ),
                  ),
                ),
                if (_currentInstallment.type != OrderType.transfer)
                  DetailItem(
                    label: l10n.category,
                    value:
                        _currentInstallment.category?.name ??
                        l10n.categoryOthers,
                    icon:
                        _currentInstallment.category?.icon.asIcon() ??
                        Icons.category_outlined,
                    iconColor: _currentInstallment.category?.color.asColor(),
                    onTap: (loading) async {
                      await loading(_changeCategory());
                    },
                  ),
                TransactionDetailAccounts(installment: _currentInstallment),
                DetailItem(
                  label: l10n.transactionStatusLabel,
                  value: l10n.forInstallmentStatus(_currentInstallment.status),
                  icon: _getStatusIcon(_currentInstallment.status),
                  iconColor: _statusColor(_currentInstallment.status, palette),
                ),
              ],
            ),
          ),
          if (_currentInstallment.status == InstallmentStatus.pending) ...[
            const Divider(),
            Padding(
              padding: AppSpacing.allMd,
              child: FilledButton.icon(
                onPressed: _registerPayment,
                icon: const Icon(Icons.check),
                label: Text(l10n.reconciliationConfirm),
                // O botão ocupa a linha inteira; o resto (raio, tipografia,
                // cor) já vem do `filledButtonTheme`.
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(InstallmentStatus status) {
    return switch (status) {
      InstallmentStatus.pending => Icons.schedule,
      InstallmentStatus.paid => Icons.check_circle_outline,
      InstallmentStatus.settled => Icons.done_all,
      InstallmentStatus.removed => Icons.delete_outline,
    };
  }

  Color _statusColor(InstallmentStatus status, AppPalette palette) {
    return switch (status) {
      InstallmentStatus.pending => AppColors.goldDeep,
      InstallmentStatus.paid => palette.successText,
      InstallmentStatus.settled => AppColors.violet,
      InstallmentStatus.removed => palette.dangerText,
    };
  }
}
