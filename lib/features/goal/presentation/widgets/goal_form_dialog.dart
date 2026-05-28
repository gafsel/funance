import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_form_provider.dart';
import 'package:intl/intl.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';

class GoalFormDialog extends ConsumerWidget {
  final GoalModel? goal;

  GoalFormDialog({super.key, this.goal});

  final _formKey = GlobalKey<FormState>();

  Future<void> _selectStartDate(BuildContext context, WidgetRef ref, GoalModel? goal) async {
    final state = ref.read(goalFormProvider(goal));
    final picked = await showDatePicker(
      context: context,
      initialDate: state.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      ref.read(goalFormProvider(goal).notifier).updateStartDate(picked);
    }
  }

  Future<void> _selectDeadline(BuildContext context, WidgetRef ref, GoalModel? goal) async {
    final state = ref.read(goalFormProvider(goal));
    final picked = await showDatePicker(
      context: context,
      initialDate: state.deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      ref.read(goalFormProvider(goal).notifier).updateDeadline(picked);
    }
  }

  void _save(BuildContext context, WidgetRef ref, GoalModel? goal) async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(goalFormProvider(goal).notifier).submit();
      if (success && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalFormProvider(goal));
    final notifier = ref.read(goalFormProvider(goal).notifier);
    final l10n = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsProvider);

    return AlertDialog(
      title: Text(goal == null ? l10n.addGoalButton : l10n.continueButton),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de Meta (Somente leitura se estiver editando)
              DropdownButtonFormField<GoalType>(
                value: state.type,
                decoration: InputDecoration(labelText: l10n.goalTypeLabel),
                items: GoalType.values.map((type) {
                  String label = '';
                  switch (type) {
                    case GoalType.saveMoney:
                      label = l10n.goalTypeSaveMoney;
                      break;
                    case GoalType.reduceExpense:
                      label = l10n.goalTypeReduceExpense;
                      break;
                    case GoalType.reduceCreditCard:
                      label = l10n.goalTypeReduceCreditCard;
                      break;
                    case GoalType.payDebt:
                      label = 'Pagar Dívida';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: goal == null ? (value) {
                  if (value != null) notifier.updateType(value);
                } : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: state.name,
                decoration: InputDecoration(labelText: l10n.goalNameLabel),
                onChanged: notifier.updateName,
                validator: (v) => v == null || v.isEmpty ? l10n.errorUnknown : null,
              ),
              const SizedBox(height: 16),
              if (state.type == GoalType.saveMoney) ...[
                TextFormField(
                  initialValue: state.targetAmount > 0 ? state.targetAmount.toString() : '',
                  decoration: InputDecoration(labelText: l10n.goalTargetAmountLabel),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey('currentAmount_${state.currentAmount}'),
                  initialValue: state.currentAmount > 0 ? state.currentAmount.toString() : '0.0',
                  decoration: InputDecoration(labelText: l10n.goalCurrentAmountLabel),
                  keyboardType: TextInputType.number,
                  enabled: state.selectedAccountId == null,
                  onChanged: (v) => notifier.updateCurrentAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
              ] else if (state.type == GoalType.payDebt) ...[
                TextFormField(
                  initialValue: state.targetAmount > 0 ? state.targetAmount.toString() : '',
                  decoration: InputDecoration(
                    labelText: 'Valor Total da Dívida',
                    hintText: 'Quanto você deve no total?',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: ValueKey('currentAmount_${state.currentAmount}'),
                  initialValue: state.currentAmount > 0 ? state.currentAmount.toString() : '0.0',
                  decoration: InputDecoration(
                    labelText: 'Valor Já Pago',
                    hintText: 'Quanto você já amortizou?',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: state.selectedAccountId == null,
                  onChanged: (v) => notifier.updateCurrentAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                accountsAsync.when(
                  data: (accounts) {
                    final debtAccounts = accounts.where((a) => a.type == AccountType.debt).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: state.selectedAccountId,
                          decoration: InputDecoration(labelText: 'Vincular à Conta de Dívida'),
                          items: debtAccounts.map((a) {
                            return DropdownMenuItem(value: a.id, child: Text(a.name));
                          }).toList(),
                          onChanged: notifier.updateAccountId,
                        ),
                        if (debtAccounts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addAccountButton),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
              ] else ...[
                // Para redução de gastos
                TextFormField(
                  initialValue: state.targetAmount > 0 ? state.targetAmount.toString() : '',
                  decoration: InputDecoration(
                    labelText: l10n.goalTargetAmountLabel,
                    hintText: 'Ex: 500.00 (Limite de gasto)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: state.averageSpending > 0 ? state.averageSpending.toString() : '',
                  decoration: InputDecoration(labelText: l10n.goalAverageSpendingLabel),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateAverageSpending(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
              ],
              if (state.type == GoalType.reduceExpense) ...[
                DropdownButtonFormField<String>(
                  value: state.selectedCategory,
                  decoration: InputDecoration(labelText: l10n.goalCategoryLabel),
                  items: ['Moradia', 'Lazer', 'Alimentação', 'Transporte'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: notifier.updateCategory,
                  validator: (v) => v == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                accountsAsync.when(
                  data: (accounts) => DropdownButtonFormField<String>(
                    value: state.selectedAccountId,
                    decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                    items: accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: notifier.updateAccountId,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
              if (state.type == GoalType.reduceCreditCard)
                accountsAsync.when(
                  data: (accounts) {
                    final creditCards = accounts.where((a) => a.type == AccountType.creditCard).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: state.selectedAccountId,
                          decoration: InputDecoration(labelText: l10n.goalCreditCardLabel),
                          items: creditCards.map((a) {
                            return DropdownMenuItem(value: a.id, child: Text(a.name));
                          }).toList(),
                          onChanged: notifier.updateAccountId,
                          validator: (v) => v == null ? l10n.errorUnknown : null,
                        ),
                        if (creditCards.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(l10n.addAccountButton),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              const SizedBox(height: 16),
              if (state.type == GoalType.saveMoney)
                accountsAsync.when(
                  data: (accounts) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: state.selectedAccountId,
                        decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text(a.name));
                        }).toList(),
                        onChanged: notifier.updateAccountId,
                      ),
                      if (accounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addAccountButton),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AccountManagementScreen()),
                            ),
                          ),
                        ),
                    ],
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ListTile(
                title: Text(l10n.goalStartDateLabel),
                subtitle: Text(DateFormat.yMd().format(state.startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectStartDate(context, ref, goal),
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: Text(l10n.goalDeadlineLabel),
                subtitle: Text(DateFormat.yMd().format(state.deadline)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDeadline(context, ref, goal),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => _save(context, ref, goal),
          child: state.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.continueButton),
        ),
      ],
    );
  }
}
