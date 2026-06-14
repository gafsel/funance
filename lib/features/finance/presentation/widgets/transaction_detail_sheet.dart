import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/loading_popup_menu_item.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_payment_sheet.dart';
import 'package:funances/features/home/presentation/widgets/category_icon.dart';
import 'package:funances/features/workspace/presentation/widgets/category_picker_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
    final locale = context.locale;
    final mq = MediaQuery.of(context);

    final isExpense = _currentInstallment.type == OrderType.expense;
    final isTransfer = _currentInstallment.type == OrderType.transfer;

    Color amountColor;
    if (isTransfer) {
      amountColor = theme.colorScheme.primary;
    } else if (isExpense) {
      amountColor = AppColors.error;
    } else {
      amountColor = AppColors.success;
    }

    return Padding(
      padding:
          const EdgeInsets.all(24) +
          EdgeInsets.only(bottom: mq.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryIcon.forInstallment(_currentInstallment),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentInstallment.description,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          DateFormat.yMMMMd(
                            locale,
                          ).format(_currentInstallment.referenceDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                  l10n.fromOrderType(_currentInstallment.type),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_currentInstallment.installmentType ==
                      InstallmentType.installment &&
                  _currentInstallment.installmentNumber != null &&
                  _currentInstallment.installmentCount != null) ...[
                const SizedBox(width: 8),
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
                      _currentInstallment.installmentCount!,
                      _currentInstallment.installmentNumber!,
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 16),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () async {
                      final navigator = Navigator.of(context);

                      final updated = await context.push(
                        '/transactions/form',
                        extra: {'installment': _currentInstallment},
                      );

                      if (updated == true) {
                        widget.onUpdated?.call();
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
                      await loading(_deleteTransaction());
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
                  if (_currentInstallment.status !=
                          InstallmentStatus.settled &&
                      _currentInstallment.amount > 0 &&
                      (_currentInstallment.status ==
                              InstallmentStatus.paid ||
                          _currentInstallment.status ==
                              InstallmentStatus.settled))
                    LoadingPopupMenuItem(
                      onTap: (loading) async {
                        await loading(_backToPending());
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
          const SizedBox(height: 32),
          Center(
            child: Text(
              _currentInstallment.referenceAmount.asCurrency(
                locale: locale,
              ),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ),
          if (_currentInstallment.type != OrderType.transfer)
            const SizedBox(height: 32),
          if (_currentInstallment.type != OrderType.transfer)
            _DetailItem(
              label: l10n.category,
              value:
                  _currentInstallment.category?.name ?? l10n.categoryOthers,
              icon:
                  _currentInstallment.category?.icon.asIcon() ??
                  Icons.category_outlined,
              iconColor: _currentInstallment.category?.color.asColor(),
              onTap: (loading) async {
                await loading(_changeCategory());
              },
            ),
          const Divider(height: 32),
          Consumer(
            builder: (context, ref, _) {
              final sourceId = _currentInstallment.accountIdSource;
              final targetId = _currentInstallment.accountIdTarget;

              if (isTransfer && sourceId != null && targetId != null) {
                final sourceAccount = ref.watch(
                  AccountViewProviders.byId(sourceId),
                );
                final targetAccount = ref.watch(
                  AccountViewProviders.byId(targetId),
                );

                return sourceAccount.when(
                  data: (source) => targetAccount.when(
                    data: (target) => _DetailItem(
                      label: l10n.transactionAccountLabel,
                      value: '',
                      customValue: Row(
                        children: [
                          if (source != null) ...[
                            AccountLogo(
                              account: source,
                              size: 30,
                              showMembers: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              source.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            Text(
                              '-',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: AppColors.antiqueGold,
                            ),
                          ),
                          if (target != null) ...[
                            AccountLogo(
                              account: target,
                              size: 30,
                              showMembers: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              target.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ] else
                            Text(
                              '-',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      icon: Icons.swap_horiz,
                      iconColor: AppColors.antiqueGold,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              }

              return Column(
                children: [
                  if (sourceId != null)
                    ref
                        .watch(AccountViewProviders.byId(sourceId))
                        .when(
                          data: (account) => _DetailItem(
                            label: l10n.transactionAccountLabel,
                            value: account?.name ?? '-',
                            customValue: account != null
                                ? Row(
                                    children: [
                                      AccountLogo(
                                        account: account,
                                        size: 30,
                                        showMembers: true,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        account.name,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  )
                                : null,
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: AppColors.antiqueGold,
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                ],
              );
            },
          ),
          const Divider(height: 32),
          _DetailItem(
            label: l10n.transactionStatusLabel,
            value: l10n.forInstallmentStatus(_currentInstallment.status),
            icon: _getStatusIcon(_currentInstallment.status),
            iconColor: _getStatusColor(_currentInstallment.status),
          ),
          const SizedBox(height: 40),
          if (_currentInstallment.status == InstallmentStatus.pending)
            FilledButton.icon(
              onPressed: _registerPayment,
              icon: const Icon(Icons.check),
              label: Text(l10n.reconciliationConfirm),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(l10n.cancelButton),
          ),
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

  Color _getStatusColor(InstallmentStatus status) {
    return switch (status) {
      InstallmentStatus.pending => AppColors.antiqueGold,
      InstallmentStatus.paid => AppColors.success,
      InstallmentStatus.settled => AppColors.deepPurple,
      InstallmentStatus.removed => AppColors.error,
    };
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget? customValue;
  final IconData icon;
  final Color? iconColor;
  final LoadingCallback? onTap;

  const _DetailItem({
    required this.label,
    required this.value,
    this.customValue,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingButton.text(
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (customValue != null)
                    customValue!
                  else
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
