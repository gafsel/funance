import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';

import 'package:funances/features/finance/presentation/providers/transaction_form_provider.dart';

class TransactionFormScreen extends ConsumerWidget {
  final TransactionType initialType;
  final OrderModel? initialOrder;
  final CategoryModel? initialCategory;
  final String? initialAccountId;
  final String? initialToAccountId;
  final bool isTransfer;
  final double? initialAmount;

  const TransactionFormScreen({
    super.key,
    required this.initialType,
    this.initialOrder,
    this.initialCategory,
    this.initialAccountId,
    this.initialToAccountId,
    this.isTransfer = false,
    this.initialAmount,
  });

  static final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = TransactionFormArgs(
      initialType: initialType,
      initialOrder: initialOrder,
      initialCategory: initialCategory,
      initialAccountId: initialAccountId,
      initialToAccountId: initialToAccountId,
      isTransfer: isTransfer,
      initialAmount: initialAmount,
    );
    
    final state = ref.watch(transactionFormProvider(args));
    final notifier = ref.read(transactionFormProvider(args).notifier);
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider).value ?? [];

    final isPlannedFlow =
        state.currentType == TransactionType.plannedExpense ||
        state.currentType == TransactionType.plannedIncome;

    ref.listen(transactionFormProvider(args), (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.transactionSaveSuccess)),
        );
        Navigator.pop(context);
      } else if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.coralOrange,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPlannedFlow
              ? l10n.transactionPlanExpense
              : l10n.transactionAddExpense,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.selectedCategory != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(
                        state.selectedCategory!.color.replaceFirst('#', '0xFF'),
                      ),
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      _getIconData(state.selectedCategory!.icon),
                      color: Color(
                        int.parse(
                          state.selectedCategory!.color.replaceFirst('#', '0xFF'),
                        ),
                      ),
                    ),
                  ),
                  title: Text(state.selectedCategory!.name),
                  subtitle: Text(l10n.transactionCategoriesSection),
                ),
                const SizedBox(height: 16),
              ] else if (state.isTransfer) ...[
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
              ],
              TextFormField(
                initialValue: state.description,
                decoration: InputDecoration(
                  labelText: l10n.transactionDescriptionLabel,
                ),
                onChanged: notifier.updateDescription,
                validator: (v) =>
                    v?.isEmpty ?? true ? l10n.fieldRequired : null,
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
                validator: (v) =>
                    v?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              if (!state.isTransfer) ...[
                DropdownButtonFormField<TransactionFormType>(
                  value: state.formType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: TransactionFormType.simple,
                      child: Text(l10n.transactionTypeSimple),
                    ),
                    DropdownMenuItem(
                      value: TransactionFormType.installment,
                      child: Text(l10n.transactionTypeInstallment),
                    ),
                    DropdownMenuItem(
                      value: TransactionFormType.recurrent,
                      child: Text(l10n.transactionTypeRecurrent),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      notifier.updateFormType(v);
                      if (v == TransactionFormType.simple) {
                        notifier.updateInstallments(1);
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              ListTile(
                title: Text(l10n.transactionDateLabel),
                subtitle: Text(DateFormat.yMd().format(state.selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: state.selectedDate,
                    firstDate: isPlannedFlow ? DateTime.now() : DateTime(2000),
                    lastDate: isPlannedFlow ? DateTime(2100) : DateTime.now(),
                  );
                  if (date != null) notifier.updateDate(date);
                },
              ),
              const Divider(),

              DropdownButtonFormField<String>(
                value: state.selectedAccountId,
                decoration: InputDecoration(
                  labelText: state.isTransfer
                      ? l10n.transactionFromAccountLabel
                      : l10n.transactionAccountLabel,
                ),
                items: accounts
                    .map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text(acc.name),
                      ),
                    )
                    .toList(),
                onChanged: notifier.updateAccountId,
                validator: (v) => v == null ? l10n.fieldRequired : null,
              ),

              if (state.isTransfer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: state.toAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.transactionToAccountLabel,
                  ),
                  items: accounts
                      .where((acc) => acc.id != state.selectedAccountId)
                      .map(
                        (acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text(acc.name),
                        ),
                      )
                      .toList(),
                  onChanged: notifier.updateToAccountId,
                  validator: (v) => v == null ? l10n.fieldRequired : null,
                ),
              ],

              if (state.formType == TransactionFormType.installment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.installments.toString(),
                  decoration: InputDecoration(
                    labelText: l10n.transactionInstallmentsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateInstallments(int.tryParse(v) ?? 1),
                  validator: (v) {
                    if (state.formType == TransactionFormType.installment) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 1) return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: state.isLoading ? null : () {
                  if (_formKey.currentState!.validate()) {
                    notifier.submit();
                  }
                },
                child: state.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.saveButton),
              ),
            ],
          ),
        ),
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
