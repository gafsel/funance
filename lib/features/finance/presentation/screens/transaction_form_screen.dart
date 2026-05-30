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
    this.order,
    this.installment,
    this.category,
    this.accountIdSource,
    this.accountIdTarget,
  });

  factory TransactionFormScreen.creation({
    required OrderType type,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
  }) {
    return TransactionFormScreen._(
      type: type,
      category: category,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
    );
  }

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
              category: category,
              accountIdSource: accountIdSource,
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
              ),
            ],

            AccountFormField(
              initialValue: state.accountIdSource,
              decoration: InputDecoration(
                labelText: state.type == OrderType.transfer
                    ? l10n.transactionFromAccountLabel
                    : l10n.transactionAccountLabel,
              ),
              onChanged: notifier.updateAccountIdSource,
              validator: v.all([v.notEmpty()]),
            ),
            if (state.type == OrderType.transfer) ...[
              AccountFormField(
                initialValue: state.accountIdTarget,
                decoration: InputDecoration(
                  labelText: l10n.transactionToAccountLabel,
                ),
                onChanged: notifier.updateAccountIdTarget,
                validator: v.all([v.notEmpty()]),
              ),
            ],
            if (state.formType == TransactionFormType.installment) ...[
              TextFormField(
                initialValue: state.installmentCount?.toString(),
                decoration: InputDecoration(
                  labelText: l10n.transactionInstallmentsLabel,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    notifier.updateInstallmentCount(int.tryParse(v) ?? 1),
                validator: v.all([v.notEmpty()]),
              ),
            ],
            ..._buildBasicFields(context, state, notifier),
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

    return [
      TextFormField(
        initialValue: state.description,
        decoration: InputDecoration(
          labelText: l10n.transactionDescriptionLabel,
        ),
        onChanged: notifier.updateDescription,
        validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
      ),
      DateFormField(
        initialValue: state.dueDate,
        onChanged: (date) {
          if (date != null) {
            notifier.updateDueDate(date);
          }
        },
        decoration: InputDecoration(labelText: l10n.transactionDateLabel),
        enabled: state.orderId == null,
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
      ),
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
          decoration: InputDecoration(
            labelText: l10n.transactionInstallmentsLabel,
          ),
          validator: v.all([v.notEmpty()]),
        ),
    ];
  }
}
