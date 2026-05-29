import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/manual_form.dart';
import 'package:funances/core/form/responsive_grid.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ManualForm<TransactionFormState, void, TransactionFormNotifier>(
          provider,
          formBuilder: (context, snapshot) {
            final state = snapshot.model;
            final notifier = snapshot.notifier;

            return ResponsiveGrid(
              children: [
                if (state.category != null &&
                    state.type != OrderType.transfer) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      final category = await _showCategoryPicker(
                        context,
                        state.type,
                      );
                      if (category != null) {
                        notifier.updateCategory(category);
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(
                          state.category!.color.replaceFirst('#', '0xFF'),
                        ),
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        _getIconData(state.category!.icon),
                        color: Color(
                          int.parse(
                            state.category!.color.replaceFirst('#', '0xFF'),
                          ),
                        ),
                      ),
                    ),
                    title: Text(state.category!.name),
                    subtitle: Text(l10n.transactionCategoriesSection),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 16),
                ] else if (state.type == OrderType.transfer) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.brightCyan,
                      child: Icon(Icons.swap_horiz, color: Colors.white),
                    ),
                    title: Text(l10n.transactionTypeTransfer),
                    subtitle: Text(l10n.transactionCategoriesSection),
                  ),
                  const SizedBox(height: 16),
                ] else if (state.type != OrderType.transfer &&
                    state.category == null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      final category = await _showCategoryPicker(
                        context,
                        state.type,
                      );
                      if (category != null) {
                        notifier.updateCategory(category);
                      }
                    },
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.softGrey,
                      child: Icon(Icons.category, color: Colors.white),
                    ),
                    title: Text(l10n.transactionCategoriesSection),
                    subtitle: Text(l10n.fieldRequired),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(height: 16),
                ],

                ..._buildBasicFields(context, state, notifier),
                ..._buildAccountFields(context, state, notifier),
                const SizedBox(height: 32),
                LoadingButton.elevated(
                  onPressed: (loading) async {
                    if (snapshot.validate()) {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      await loading(notifier.submit());

                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.transactionSaveSuccess)),
                      );

                      navigator.pop();
                    }
                  },
                  child: Text(l10n.saveButton),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBasicFields(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;

    return [
      if (state.orderId != null) ...[
        DropdownButtonFormField<OrderType>(
          initialValue: state.type,
          decoration: InputDecoration(
            labelText: l10n.transactionOrderTypeLabel,
          ),
          items: [
            DropdownMenuItem(
              value: OrderType.expense,
              child: Text(l10n.transactionTypeExpense),
            ),
            DropdownMenuItem(
              value: OrderType.income,
              child: Text(l10n.transactionTypeIncome),
            ),
            DropdownMenuItem(
              value: OrderType.transfer,
              child: Text(l10n.transactionTypeTransfer),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              notifier.updateOrderType(v);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
      TextFormField(
        initialValue: state.description,
        decoration: InputDecoration(
          labelText: l10n.transactionDescriptionLabel,
        ),
        onChanged: notifier.updateDescription,
        validator: (v) => v?.isEmpty ?? true ? l10n.fieldRequired : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        initialValue: state.amount > 0 ? state.amount.toString() : '',
        decoration: InputDecoration(
          labelText: l10n.transactionAmountLabel,
          prefixText: 'R\$ ',
        ),
        keyboardType: TextInputType.number,
        onChanged: (v) => notifier.updateAmount(double.tryParse(v) ?? 0),
        validator: (v) => v?.isEmpty ?? true ? l10n.fieldRequired : null,
      ),
      const SizedBox(height: 16),
      if (state.type != OrderType.transfer) ...[
        DropdownButtonFormField<InstallmentType>(
          initialValue: state.installmentType,
          decoration: InputDecoration(labelText: l10n.transactionTypeLabel),
          items: [
            DropdownMenuItem(
              value: InstallmentType.single,
              child: Text(l10n.transactionTypeSimple),
            ),
            DropdownMenuItem(
              value: InstallmentType.installment,
              child: Text(l10n.transactionTypeInstallment),
            ),
            DropdownMenuItem(
              value: InstallmentType.recurring,
              child: Text(l10n.transactionTypeRecurrent),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              notifier.updateInstallmentType(v);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
      ListTile(
        title: Text(l10n.transactionDateLabel),
        subtitle: Text(state.dueDate.formated(l10n.formatSimpleDate)),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: state.dueDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) notifier.updateDueDate(date);
        },
      ),
      const Divider(),
    ];
  }

  List<Widget> _buildAccountFields(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;

    return [
      AccountFormField(
        initialValue: state.accountIdSource,
        decoration: InputDecoration(
          labelText: state.type == OrderType.transfer
              ? l10n.transactionFromAccountLabel
              : l10n.transactionAccountLabel,
        ),
        onChanged: notifier.updateAccountIdSource,
        validator: (v) => v == null ? l10n.fieldRequired : null,
      ),
      if (state.type == OrderType.transfer) ...[
        const SizedBox(height: 16),
        AccountFormField(
          initialValue: state.accountIdTarget,
          decoration: InputDecoration(
            labelText: l10n.transactionToAccountLabel,
          ),
          onChanged: notifier.updateAccountIdTarget,
          validator: (v) => v == null ? l10n.fieldRequired : null,
        ),
      ],
      if (state.formType == TransactionFormType.installment) ...[
        const SizedBox(height: 16),
        TextFormField(
          initialValue: state.installmentCount?.toString(),
          decoration: InputDecoration(
            labelText: l10n.transactionInstallmentsLabel,
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              notifier.updateInstallmentCount(int.tryParse(v) ?? 1),
          validator: (v) {
            if (state.formType == TransactionFormType.installment) {
              final n = int.tryParse(v ?? '');
              if (n == null || n <= 1) return l10n.fieldRequired;
            }
            return null;
          },
        ),
      ],
    ];
  }

  Future<CategoryModel?> _showCategoryPicker(
    BuildContext context,
    OrderType orderType,
  ) async {
    return showModalBottomSheet<CategoryModel>(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final categories = ref
              .watch(CategoryViewProviders.allStream)
              .when(
                data: (data) => data
                    .where((c) => c.type == orderType.categoryType)
                    .toList(),
                error: (error, stack) => [],
                loading: () => [],
              );

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    AppLocalizations.of(context)!.transactionCategoriesSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            int.parse(category.color.replaceFirst('#', '0xFF')),
                          ).withValues(alpha: 0.2),
                          child: Icon(
                            _getIconData(category.icon),
                            color: Color(
                              int.parse(
                                category.color.replaceFirst('#', '0xFF'),
                              ),
                            ),
                          ),
                        ),
                        title: Text(category.name),
                        onTap: () => Navigator.pop(context, category),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'home':
        return Icons.home;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'school':
        return Icons.school;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'movie':
        return Icons.movie;
      case 'flight':
        return Icons.flight;
      case 'work':
        return Icons.work;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'payments':
        return Icons.payments;
      case 'account_balance':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.category;
    }
  }
}
