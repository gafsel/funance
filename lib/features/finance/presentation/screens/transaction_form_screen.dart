import 'package:flutter/material.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

class TransactionFormScreen extends StatelessWidget {
  final OrderType type;
  final OrderModel? order;
  final InstallmentModel? installment;
  final CategoryModel? category;
  final String? accountIdSource;
  final String? accountIdTarget;

  const TransactionFormScreen._({
    super.key,
    required this.type,
    this.status,
    this.order,
    this.installment,
    this.category,
    this.accountIdSource,
    this.accountIdTarget,
  });

  factory TransactionFormScreen.creation({
    required OrderType type,
    InstallmentStatus? status,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
  }) {
    return TransactionFormScreen._(
      type: type,
      status: status,
      category: category,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
    );
  }

  final InstallmentStatus? status;

  factory TransactionFormScreen.updateInstallment({
    required InstallmentModel installment,
  }) {
    return TransactionFormScreen._(
      type: installment.type,
      installment: installment,
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
        : updateInstallment
        ? FinanceViewProviders.updateInstallmentForm(installment!)
        : FinanceViewProviders.creationForm(
            TransactionCreationArgs(
              type: type,
              status: status,
              category: category,
              accountIdSource: accountIdSource,
              accountIdTarget: accountIdTarget,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          updateOrder || updateInstallment
              ? l10n.historyEdit
              : l10n.transactionAddExpense,
        ),
      ),
      body: ResponsiveForm<TransactionFormState, void, TransactionFormNotifier>(
        provider,
        submitLabel: l10n.saveButton,
        onSuccess: (output) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.transactionSaveSuccess)),
          );

          navigator.pop();
        },
        fieldsBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;
          final v = context.validations;
          final isPending = state.status == InstallmentStatus.pending;

          final showCategory = state.creation;
          final showAccounts =
              !state.creation ||
              state.category != null ||
              state.type == OrderType.transfer;
          final showBasicFields =
              !state.creation ||
              (state.type == OrderType.transfer
                  ? state.accountIdSource != null && state.accountIdTarget != null
                  : (state.category != null &&
                      (isPending || state.accountIdSource != null)));

          return [
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
                onChanged: state.creation
                    ? (v) {
                        if (v != null) {
                          notifier.updateOrderType(v);
                        }
                      }
                    : null,
                validator: v.all([v.notNull()]),
              ),
            if (showCategory)
              if (state.type == OrderType.transfer) ...[
                CategoryFormField.transfer(
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                ),
              ] else ...[
                CategoryFormField(
                  initialValue: state.category,
                  orderType: state.type,
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                  onChanged: notifier.updateCategory,
                  validator: v.all([v.notNull()]),
                  autoOpen: state.creation,
                ),
              ],
            if (showAccounts) ...[
              AccountFormField(
                initialValue: state.accountIdSource,
                decoration: InputDecoration(
                  labelText: state.type == OrderType.transfer
                      ? l10n.transactionFromAccountLabel
                      : l10n.transactionAccountLabel,
                ),
                onChanged: state.status != InstallmentStatus.paid || state.creation
                    ? notifier.updateAccountIdSource
                    : null,
                validator: isPending ? null : v.all([v.notEmpty()]),
                autoOpen: state.creation,
              ),
              if (state.type == OrderType.transfer) ...[
                AccountFormField(
                  initialValue: state.accountIdTarget,
                  decoration: InputDecoration(
                    labelText: l10n.transactionToAccountLabel,
                  ),
                  onChanged: state.status != InstallmentStatus.paid || state.creation
                      ? notifier.updateAccountIdTarget
                      : null,
                  validator: isPending ? null : v.all([v.notEmpty()]),
                  autoOpen: state.creation && state.accountIdSource != null,
                ),
              ],
            ],
            if (showBasicFields) ..._buildBasicFields(context, state, notifier),
          ];
        },
      ),
    );
  }

  List<Widget> _buildBasicFields(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;
    final v = context.validations;
    final isPaid = state.status == InstallmentStatus.paid;

    return [
      if (state.creation || state.formType == TransactionFormType.installment)
        ChipFormField<InstallmentStatus>(
          initialValue: state.status,
          decoration: InputDecoration(
            labelText: state.creation ? "Tipo de Cadastro" : "Status",
          ),
          options: state.creation
              ? [
                  const ChipFormFieldOption(
                    value: InstallmentStatus.pending,
                    label: "Planejamento",
                  ),
                  const ChipFormFieldOption(
                    value: InstallmentStatus.paid,
                    label: "Realizado",
                  ),
                ]
              : [
                  const ChipFormFieldOption(
                    value: InstallmentStatus.pending,
                    label: "Pendente",
                  ),
                  const ChipFormFieldOption(
                    value: InstallmentStatus.paid,
                    label: "Pago",
                  ),
                ],
          onChanged: (v) {
            if (v != null) {
              notifier.updateStatus(v);
            }
          },
        ),
      TextFormField(
        initialValue: state.description,
        decoration: InputDecoration(
          labelText: l10n.transactionDescriptionLabel,
        ),
        onChanged: notifier.updateDescription,
        validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
        enabled: !isPaid || state.creation,
      ),
      DateFormField(
        initialValue: state.dueDate,
        onChanged: (date) {
          if (date != null) {
            notifier.updateDueDate(date);
          }
        },
        decoration: InputDecoration(labelText: l10n.transactionDateLabel),
        enabled: (state.orderId == null) && (!isPaid || state.creation),
        validator: v.all([v.notNull()]),
      ),
      TextFormField(
        initialValue: state.amount > 0 ? state.amount.toString() : '',
        decoration: InputDecoration(
          labelText: l10n.transactionAmountLabel,
          prefixText: 'R\$ ',
        ),
        keyboardType: TextInputType.number,
        onChanged: (v) => notifier.updateAmount(double.tryParse(v) ?? 0),
        validator: v.all([v.notNull()]),
        enabled: !isPaid || state.creation,
      ),
      if (state.formType == TransactionFormType.installment && isPaid) ...[
        DateFormField(
          initialValue: state.paidDate,
          onChanged: (date) {
            if (date != null) {
              notifier.updatePaidDate(date);
            }
          },
          decoration: const InputDecoration(labelText: "Data de Pagamento"),
          validator: v.all([v.notNull()]),
        ),
        TextFormField(
          initialValue: state.paidAmount?.toString(),
          decoration: const InputDecoration(
            labelText: "Valor Pago",
            prefixText: 'R\$ ',
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => notifier.updatePaidAmount(double.tryParse(v) ?? 0),
          validator: v.all([v.notNull()]),
        ),
      ],
      if (state.type != OrderType.transfer) ...[
        ChipFormField<InstallmentType>(
          initialValue: state.installmentType,
          decoration: InputDecoration(labelText: l10n.transactionTypeLabel),
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
          onChanged: (v) {
            if (v != null) {
              notifier.updateInstallmentType(v);
            }
          },
        ),
      ],
      if (state.installmentType == InstallmentType.installment)
        TextFormField(
          initialValue: (state.installmentCount ?? 1).toString(),
          onChanged: (installment) =>
              notifier.updateInstallmentCount(int.tryParse(installment) ?? 1),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.transactionInstallmentsLabel,
          ),
          validator: v.all([v.notEmpty()]),
        ),
    ];
  }
}
