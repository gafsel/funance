import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFormScreen extends StatelessWidget {
  final OrderType type;
  final OrderModel? order;
  final InstallmentModel? installment;
  final CategoryModel? category;
  final String? accountIdSource;
  final String? accountIdTarget;
  final InstallmentStatus? status;
  final String? description;
  final DateTime? dueDate;
  final double? amount;

  const TransactionFormScreen._({
    required this.type,
    this.status,
    this.order,
    this.installment,
    this.category,
    this.accountIdSource,
    this.accountIdTarget,
    this.description,
    this.dueDate,
    this.amount,
  });

  factory TransactionFormScreen.creation({
    required OrderType type,
    InstallmentStatus? status,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    double? amount,
    DateTime? dueDate,
  }) {
    return TransactionFormScreen._(
      type: type,
      status: status,
      category: category,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
      description: description,
      amount: amount,
      dueDate: dueDate,
    );
  }

  factory TransactionFormScreen.updateInstallment({
    required InstallmentModel installment,
    InstallmentStatus? status,
  }) {
    return TransactionFormScreen._(
      type: installment.type,
      installment: installment,
      status: status,
    );
  }

  factory TransactionFormScreen.updateOrder({required OrderModel order}) {
    return TransactionFormScreen._(type: order.type, order: order);
  }

  bool get updateOrder => order != null;

  bool get updateInstallment => installment != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final provider = updateOrder
        ? FinanceViewProviders.updateOrderForm(order!)
        : updateInstallment && status == InstallmentStatus.paid
        // Confirmação de pagamento (ex.: vindo do wizard): abre o formulário
        // já como pago, com os campos de pagamento visíveis e preenchidos.
        ? FinanceViewProviders.transactionPaymentForm(installment!)
        : updateInstallment
        ? FinanceViewProviders.updateInstallmentForm(installment!)
        : FinanceViewProviders.creationForm(
            TransactionCreationArgs(
              type: type,
              status: status,
              category: category,
              accountIdSource: accountIdSource,
              accountIdTarget: accountIdTarget,
              description: description,
              amount: amount,
              date: dueDate,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          updateOrder || updateInstallment
              ? l10n.historyEdit
              : l10n.transactionAddExpense,
        ),
        actions: [
          if (updateOrder || updateInstallment)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, provider),
            ),
        ],
      ),
      body: ResponsiveForm<TransactionFormState, dynamic, TransactionFormNotifier>(
        provider,
        submitLabel: l10n.saveButton,
        onCancel: () => Navigator.pop(context),
        onSubmit: (snapshot, loading) async {
          if (!snapshot.validate()) return;

          final state = snapshot.model;
          final notifier = snapshot.notifier;

          ReplicationCascade cascade = ReplicationCascade.none;

          if (notifier.shouldAskCascade) {
            final original = installment!;
            final changedFieldsOtherThanStatusOrPayment =
                state.description != original.description ||
                state.amount != original.amount ||
                state.dueDate != original.dueDate ||
                state.category?.id != original.category?.id ||
                state.accountIdSource != original.accountIdSource ||
                state.accountIdTarget != original.accountIdTarget;

            if (changedFieldsOtherThanStatusOrPayment) {
              final selectedCascade = await ReplicationCascadeDialog.showUpdate(
                context,
              );

              if (selectedCascade == null) return;
              cascade = selectedCascade;
            }
          }

          notifier.updateReplicationCascade(cascade);

          final result = await loading(notifier.submit());
          if (result == null) return;

          unawaited(HapticFeedback.mediumImpact());
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.transactionSaveSuccess)),
          );

          navigator.pop(true);
        },
        bannerBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;

          if (!state.creation && state.status == InstallmentStatus.settled) {
            return MaterialBanner(
              backgroundColor: AppColors.successGold,
              content: Text(l10n.transactionSettledAlert),
              actions: [
                TextButton(
                  onPressed: notifier.unsettle,
                  child: Text(l10n.transactionUnsettleAction),
                ),
              ],
            );
          }
          return null;
        },
        fieldsBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;
          final theme = Theme.of(context);
          final l10n = context.l10n;
          final v = context.validations;
          final isPending = state.status == InstallmentStatus.pending;
          final isSettled = state.status == InstallmentStatus.settled;
          final isPaid = state.status == InstallmentStatus.paid;

          final isEditable = !state.isInvoice && (!isSettled || state.creation);

          String amountLabel = l10n.transactionAmountLabel;
          if (state.installmentType == InstallmentType.recurring) {
            amountLabel = l10n.transactionAmountRecurringLabel;
          } else if (state.installmentType == InstallmentType.installment) {
            if (!state.creation ||
                state.amountType == TransactionAmountType.installment) {
              amountLabel = l10n.transactionAmountInstallmentLabel;
            } else {
              amountLabel = l10n.transactionAmountTotalLabel;
            }
          }

          return [
            // 1. Badge de Tipo de Transação (Apenas em Edição)
            if (!state.creation)
              FullWidthItem(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      state.type == OrderType.expense
                          ? l10n.transactionTypeExpense
                          : state.type == OrderType.income
                          ? l10n.transactionTypeIncome
                          : l10n.transactionTypeTransfer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: state.type == OrderType.expense
                        ? AppColors.error
                        : state.type == OrderType.income
                        ? AppColors.limeGreen
                        : theme.colorScheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

            // 2. Campo de Valor (MoneyFormField ou Texto Estático)
            if (state.creation || state.isPlanning)
              if (isEditable)
                FullWidthItem(
                  MoneyFormField(
                    initialValue: state.amount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: state.type == OrderType.expense
                          ? AppColors.error
                          : state.type == OrderType.income
                          ? AppColors.limeGreen
                          : theme.colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: amountLabel,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (v) => notifier.updateAmount(v ?? 0.0),
                    validator: v.all([v.notNull()]),
                    enabled: true,
                  ),
                )
              else
                FullWidthItem(
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            amountLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.amount.asCurrency(locale: context.locale),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: state.type == OrderType.expense
                                  ? AppColors.error
                                  : state.type == OrderType.income
                                  ? AppColors.limeGreen
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            // 3. Campo de Descrição (TextFormField ou Texto Estático)
            if (isEditable)
              FullWidthItem(
                TextFormField(
                  initialValue: state.description,
                  decoration: InputDecoration(
                    labelText: l10n.transactionDescriptionLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: notifier.updateDescription,
                  validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
                  enabled: true,
                ),
              )
            else
              FullWidthItem(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      state.description,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // 4. Seção de Categoria e Contas (Editável ou Metadados)
            if (state.creation || !isSettled) ...[
              // Modo Editável
              if (state.isInvoice)
                CategoryFormField.invoice(
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                )
              else if (state.type == OrderType.transfer)
                CategoryFormField.transfer(
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                )
              else
                CategoryFormField(
                  initialValue: state.category,
                  categoryType: state.type.categoryType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                  onChanged: notifier.updateCategory,
                  validator: v.all([v.notNull()]),
                  autoOpen: state.creation && state.type != OrderType.transfer,
                ),

              AccountFormField(
                initialValue: state.accountIdSource,
                decoration: InputDecoration(
                  labelText: state.type == OrderType.transfer
                      ? l10n.transactionFromAccountLabel
                      : l10n.transactionAccountLabel,
                ),
                onChanged: notifier.updateAccountIdSource,
                validator: isPending ? null : v.all([v.notEmpty()]),
                autoOpen:
                    state.creation && state.status != InstallmentStatus.pending,
              ),
              if (state.type == OrderType.transfer)
                AccountFormField(
                  initialValue: state.accountIdTarget,
                  decoration: InputDecoration(
                    labelText: l10n.transactionToAccountLabel,
                  ),
                  onChanged: notifier.updateAccountIdTarget,
                  validator: v.all([v.notEmpty()]),
                  autoOpen:
                      state.creation &&
                      state.accountIdSource != null &&
                      state.type == OrderType.transfer,
                ),
            ] else ...[
              // Modo Leitura (Metadados Limpos)
              if (state.category != null)
                FullWidthItem(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "${l10n.transactionCategoriesSection}: ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: state.category!.color
                                .asColor()
                                .withValues(alpha: 0.2),
                            child: Icon(
                              state.category!.icon.asIcon(),
                              size: 12,
                              color: state.category!.color.asColor(),
                            ),
                          ),
                          label: Text(state.category!.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),

              if (state.accountIdSource != null)
                FullWidthItem(
                  Consumer(
                    builder: (context, ref, child) {
                      final accountAsync = ref.watch(
                        AccountViewProviders.byId(state.accountIdSource!),
                      );
                      return accountAsync.when(
                        data: (account) {
                          if (account == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  state.type == OrderType.transfer
                                      ? "${l10n.transactionFromAccountLabel}: "
                                      : "${l10n.transactionAccountLabel}: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AccountLogo(account: account, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  account.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

              if (state.type == OrderType.transfer &&
                  state.accountIdTarget != null)
                FullWidthItem(
                  Consumer(
                    builder: (context, ref, child) {
                      final accountAsync = ref.watch(
                        AccountViewProviders.byId(state.accountIdTarget!),
                      );
                      return accountAsync.when(
                        data: (account) {
                          if (account == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "${l10n.transactionToAccountLabel}: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AccountLogo(account: account, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  account.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
            ],

            // 5. Data de Vencimento / Transação (Editável ou Metadado)
            if (state.creation || state.isPlanning)
              if (isEditable)
                DateFormField(
                  initialValue: state.dueDate,
                  onChanged: (date) {
                    if (date != null) {
                      notifier.updateDueDate(date);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.transactionDateLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: v.all([v.notNull()]),
                )
              else
                FullWidthItem(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "${l10n.transactionDateLabel}: ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.dueDate.formated(l10n.formatSimpleDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            // 6. Configurações Avançadas ("Mais Opções")
            FullWidthItem(
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    l10n.transactionMoreOptions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.all(8),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        if (state.creation)
                          ChipFormField<OrderType>(
                            initialValue: state.type,
                            decoration: InputDecoration(
                              labelText: l10n.transactionOrderTypeLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: OrderType.expense,
                                label: l10n.transactionTypeExpense,
                              ),
                              ChipFormFieldOption(
                                value: OrderType.income,
                                label: l10n.transactionTypeIncome,
                              ),
                              ChipFormFieldOption(
                                value: OrderType.transfer,
                                label: l10n.transactionTypeTransfer,
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                notifier.updateOrderType(v);
                              }
                            },
                            validator: v.all([v.notNull()]),
                          ),
                        _buildStatusField(context, state, notifier),
                        if (state.type != OrderType.transfer) ...[
                          ChipFormField<InstallmentType>(
                            initialValue: state.installmentType,
                            decoration: InputDecoration(
                              labelText: l10n.transactionTypeLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: InstallmentType.single,
                                label: l10n.transactionTypeSimple,
                              ),
                              ChipFormFieldOption(
                                value: InstallmentType.installment,
                                label: l10n.transactionTypeInstallment,
                              ),
                              ChipFormFieldOption(
                                value: InstallmentType.recurring,
                                label: l10n.transactionTypeRecurrent,
                              ),
                            ],
                            onChanged: state.creation
                                ? (v) {
                                    if (v != null) {
                                      notifier.updateInstallmentType(v);
                                    }
                                  }
                                : null,
                          ),
                        ],
                        if (state.installmentType == InstallmentType.installment)
                          TextFormField(
                            initialValue: (state.installmentCount ?? 1).toString(),
                            onChanged: (installment) =>
                                notifier.updateInstallmentCount(
                                  int.tryParse(installment) ?? 1,
                                ),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.transactionInstallmentsLabel,
                            ),
                            validator: v.all([v.notEmpty()]),
                            enabled: state.creation,
                          ),
                        if (state.installmentType == InstallmentType.installment &&
                            state.creation &&
                            !isSettled)
                          ChipFormField<TransactionAmountType>(
                            initialValue: state.amountType,
                            decoration: InputDecoration(
                              labelText: l10n.transactionAmountLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: TransactionAmountType.total,
                                label: l10n.transactionAmountTotalLabel,
                              ),
                              ChipFormFieldOption(
                                value: TransactionAmountType.installment,
                                label: l10n.transactionAmountInstallmentLabel,
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                notifier.updateAmountType(v);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 7. Informações de Pagamento (Se não for Criação e estiver Pago/Liquidado ou sem planejamento)
            if (!state.creation && (isPaid || isSettled || !state.isPlanning)) ...[
              FullWidthItem(const Divider()),
              FullWidthItem(
                Text(l10n.paymentInfo, style: theme.textTheme.titleMedium),
              ),
              DateFormField(
                initialValue: state.paidDate,
                onChanged: (date) {
                  if (date != null) {
                    notifier.updatePaidDate(date);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.transactionDateLabel,
                ),
                validator: v.all([v.notNull()]),
                enabled: !isSettled,
              ),
              MoneyFormField(
                initialValue: state.paidAmount,
                decoration: InputDecoration(
                  labelText: l10n.transactionAmountLabel,
                ),
                onChanged: (v) => notifier.updatePaidAmount(v ?? 0.0),
                validator: v.all([v.notNull()]),
                enabled: !isSettled,
              ),
            ],
          ];
        },
      ),
    );
  }

  ChipFormField<InstallmentStatus> _buildStatusField(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;
    final isSettled = state.status == InstallmentStatus.settled;

    return ChipFormField<InstallmentStatus>(
      initialValue: isSettled ? InstallmentStatus.paid : state.status,
      decoration: InputDecoration(
        labelText: state.creation
            ? l10n.transactionStatusTypeLabel
            : l10n.transactionStatusLabel,
      ),
      options: state.creation
          ? [
              ChipFormFieldOption(
                value: InstallmentStatus.pending,
                label: l10n.transactionStatusPlanning,
              ),
              ChipFormFieldOption(
                value: InstallmentStatus.paid,
                label: l10n.transactionStatusRealized,
              ),
            ]
          : [
              ChipFormFieldOption(
                value: InstallmentStatus.pending,
                label: l10n.transactionStatusPending,
              ),
              ChipFormFieldOption(
                value: InstallmentStatus.paid,
                label: l10n.transactionStatusPaid,
              ),
              if (isSettled)
                ChipFormFieldOption(
                  value: InstallmentStatus.settled,
                  label: l10n.transactionStatusSettled,
                ),
            ],
      onChanged: (!isSettled && state.amount > 0) || state.creation
          ? (v) {
              if (v != null) {
                notifier.updateStatus(v);
              }
            }
          : null,
    );
  }

  void _confirmDelete(
    BuildContext context,
    AutoDisposeStateNotifierProvider<
      TransactionFormNotifier,
      TransactionFormState
    >
    provider,
  ) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(provider.notifier);
              final state = ref.watch(provider.select((s) => s));

              return LoadingButton.text(
                onPressed: (loading) async {
                  final navigator = Navigator.of(context);
                  ReplicationCascade cascade = ReplicationCascade.none;

                  if (state.installmentType != InstallmentType.single) {
                    final selectedCascade =
                        await ReplicationCascadeDialog.showDeletion(context);

                    if (selectedCascade == null) return;
                    cascade = selectedCascade;
                  }

                  notifier.updateReplicationCascade(cascade);
                  await loading(notifier.delete());

                  navigator.pop(); // Fecha dialog de confirmação
                  if (context.mounted) {
                    Navigator.of(context).pop(true); // Fecha tela de form
                  }
                },
                child: Text(
                  l10n.deleteButton,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
