import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/providers/goal_providers.dart';
import 'package:intl/intl.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';

class GoalFormDialog extends ConsumerStatefulWidget {
  final GoalModel? goal;

  const GoalFormDialog({super.key, this.goal});

  @override
  ConsumerState<GoalFormDialog> createState() => _GoalFormDialogState();
}

class _GoalFormDialogState extends ConsumerState<GoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentAmountController;
  late TextEditingController _averageSpendingController;
  late DateTime _startDate;
  late DateTime _deadline;
  late GoalType _type;
  String? _selectedCategory;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name);
    _targetAmountController = TextEditingController(text: widget.goal?.targetAmount.toString());
    _currentAmountController = TextEditingController(text: widget.goal?.currentAmount.toString());
    _averageSpendingController = TextEditingController(
      text: widget.goal?.metadata?['averageSpending']?.toString() ?? '',
    );
    _startDate = widget.goal?.startDate ?? DateTime.now();
    _deadline = widget.goal?.deadline ?? DateTime.now().add(const Duration(days: 30));
    _type = widget.goal?.type ?? GoalType.saveMoney;
    _selectedCategory = widget.goal?.metadata?['category'];
    _selectedAccountId = widget.goal?.accountId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _averageSpendingController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final metadata = <String, dynamic>{};
      if (_type == GoalType.reduceExpense) {
        metadata['category'] = _selectedCategory;
        metadata['averageSpending'] = double.tryParse(_averageSpendingController.text) ?? 0.0;
      } else if (_type == GoalType.reduceCreditCard) {
        metadata['averageSpending'] = double.tryParse(_averageSpendingController.text) ?? 0.0;
      }

      final goal = GoalModel(
        id: widget.goal?.id ?? '',
        name: _nameController.text,
        targetAmount: double.parse(_targetAmountController.text),
        currentAmount: double.parse(_currentAmountController.text),
        startDate: _startDate,
        deadline: _deadline,
        type: _type,
        accountId: _selectedAccountId,
        metadata: metadata.isEmpty ? null : metadata,
      );

      if (widget.goal == null) {
        ref.read(goalsProvider.notifier).addGoal(goal);
      } else {
        ref.read(goalsProvider.notifier).updateGoal(goal);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountsProvider);

    return AlertDialog(
      title: Text(widget.goal == null ? l10n.addGoalButton : l10n.continueButton),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo de Meta (Somente leitura se estiver editando)
              DropdownButtonFormField<GoalType>(
                value: _type,
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
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: widget.goal == null
                    ? (value) {
                        if (value != null) setState(() => _type = value);
                      }
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.goalNameLabel),
                validator: (v) => v == null || v.isEmpty ? l10n.errorUnknown : null,
              ),
              const SizedBox(height: 16),
              if (_type == GoalType.saveMoney) ...[
                TextFormField(
                  controller: _targetAmountController,
                  decoration: InputDecoration(labelText: l10n.goalTargetAmountLabel),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentAmountController,
                  decoration: InputDecoration(labelText: l10n.goalCurrentAmountLabel),
                  keyboardType: TextInputType.number,
                  enabled: _selectedAccountId == null,
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
              ] else ...[
                // Para redução de gastos
                TextFormField(
                  controller: _targetAmountController,
                  decoration: InputDecoration(
                    labelText: l10n.goalTargetAmountLabel,
                    hintText: 'Ex: 500.00 (Limite de gasto)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _averageSpendingController,
                  decoration: InputDecoration(labelText: l10n.goalAverageSpendingLabel),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || double.tryParse(v) == null ? l10n.errorUnknown : null,
                ),
              if (_type == GoalType.reduceExpense) ...[
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(labelText: l10n.goalCategoryLabel),
                  items: ['Moradia', 'Lazer', 'Alimentação', 'Transporte'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? l10n.errorUnknown : null,
                ),
                const SizedBox(height: 16),
                accountsAsync.when(
                  data: (accounts) => DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                    items: accounts.map((a) {
                      return DropdownMenuItem(value: a.id, child: Text(a.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
                if (_type == GoalType.reduceCreditCard)
                  accountsAsync.when(
                    data: (accounts) {
                      final creditCards = accounts.where((a) => a.type == AccountType.creditCard).toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedAccountId,
                            decoration: InputDecoration(labelText: l10n.goalCreditCardLabel),
                            items: creditCards.map((a) {
                              return DropdownMenuItem(value: a.id, child: Text(a.name));
                            }).toList(),
                            onChanged: (v) {
                              setState(() => _selectedAccountId = v);
                              if (v != null) {
                                ref.read(latestAccountBalanceProvider(v).stream).first.then((balance) {
                                  setState(() {
                                    // Para cartão de crédito, o saldo geralmente é negativo (débito acumulado), 
                                    // mas para a meta de redução talvez interesse o valor absoluto ou o saldo atual.
                                    // Como a meta de redução usa targetAmount como limite, 
                                    // currentAmount pode ser o quanto já gastou.
                                    _currentAmountController.text = balance.balance.abs().toString();
                                  });
                                });
                              }
                            },
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
              ],
              const SizedBox(height: 16),
              if (_type == GoalType.saveMoney)
                accountsAsync.when(
                  data: (accounts) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedAccountId,
                        decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                        items: accounts.map((a) {
                          return DropdownMenuItem(value: a.id, child: Text(a.name));
                        }).toList(),
                        onChanged: (v) {
                          setState(() => _selectedAccountId = v);
                          if (v != null) {
                            final account = accounts.firstWhere((a) => a.id == v);
                            ref.read(latestAccountBalanceProvider(v).stream).first.then((balance) {
                              setState(() {
                                _currentAmountController.text = balance.balance.toString();
                              });
                            });
                          }
                        },
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
                subtitle: Text(DateFormat.yMd().format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectStartDate,
                contentPadding: EdgeInsets.zero,
              ),
              ListTile(
                title: Text(l10n.goalDeadlineLabel),
                subtitle: Text(DateFormat.yMd().format(_deadline)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDeadline,
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
          onPressed: _save,
          child: Text(l10n.continueButton),
        ),
      ],
    );
  }
}
