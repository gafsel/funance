import 'package:funances/features/finance/domain/models/planning_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers/category_providers.dart';
import 'package:funances/features/finance/presentation/providers/account_providers.dart';
import 'package:funances/features/finance/presentation/providers/transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

enum _TransactionFormType { simple, installment, recurrent }

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _currentType;
  _TransactionFormType _formType = _TransactionFormType.simple;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController(text: '1');

  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  String? _selectedAccountId;
  String? _toAccountId; // For transfers
  String? _existingOrderId;
  String? _planningId;

  bool _isTransfer = false;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _isTransfer = widget.isTransfer;
    _selectedCategory = widget.initialCategory;
    _selectedAccountId = widget.initialAccountId;
    _toAccountId = widget.initialToAccountId;

    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount.toString();
    }

    if (widget.initialOrder != null) {
      _onPlannedOrderSelected(widget.initialOrder!);
      _planningId = widget.initialOrder!.planningId;
    } else {
      // Por padrão se for transferência, é sempre simples
      if (_isTransfer) {
        _formType = _TransactionFormType.simple;
      }
    }

    if (_currentType == TransactionType.plannedExpense ||
        _currentType == TransactionType.plannedIncome) {
      // Data de planejamento não pode ser passada
      if (_selectedDate.isBefore(DateTime.now())) {
        // Garantir que a data seja pelo menos hoje
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  void _onPlannedOrderSelected(OrderModel order) {
    setState(() {
      _existingOrderId = order.id;
      _planningId = order.planningId;
      _descriptionController.text = order.description;
      _amountController.text = order.totalAmount.toString();
      _installmentsController.text = order.installmentsCount.toString();
      _selectedDate = order.date;

      if (order.installmentsCount > 1) {
        _formType = _TransactionFormType.installment;
      } else {
        _formType = _TransactionFormType.simple;
      }

      final categories = ref.read(categoriesProvider).value ?? [];
      _selectedCategory = categories.firstWhere(
        (c) => c.id == order.category.id,
        orElse: () => order.category,
      );

      _isTransfer = order.type == OrderType.transfer;
      if (_isTransfer && order.metadata != null) {
        _selectedAccountId = order.metadata!['fromAccountId'];
        _toAccountId = order.metadata!['toAccountId'];
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null && !_isTransfer) return;
    if (_selectedAccountId == null) return;

    final l10n = AppLocalizations.of(context)!;
    final status =
        (_currentType == TransactionType.plannedExpense ||
            _currentType == TransactionType.plannedIncome)
        ? OrderStatus.active
        : OrderStatus.paid;

    OrderType type = OrderType.expense;
    if (_isTransfer) {
      type = OrderType.transfer;
    } else if (_currentType == TransactionType.income ||
        _currentType == TransactionType.plannedIncome) {
      type = OrderType.income;
    }

    final metadata = <String, dynamic>{'accountId': _selectedAccountId};

    if (_isTransfer) {
      metadata['fromAccountId'] = _selectedAccountId;
      metadata['toAccountId'] = _toAccountId;
    }

    int installments = 1;
    if (_formType == _TransactionFormType.installment) {
      installments = int.tryParse(_installmentsController.text) ?? 1;
    }

    PlanningType? planningType;
    final isPlannedFlow =
        _currentType == TransactionType.plannedExpense ||
        _currentType == TransactionType.plannedIncome;
    if (isPlannedFlow) {
      if (_formType == _TransactionFormType.installment) {
        planningType = PlanningType.parcelado;
      } else if (_formType == _TransactionFormType.recurrent) {
        planningType = PlanningType.recurrent;
      } else {
        planningType = PlanningType.unique;
      }
    }

    DateTime endDate = _selectedDate;
    if (planningType == PlanningType.recurrent) {
      endDate = _selectedDate.add(const Duration(days: 365 * 100));
    } else if (planningType == PlanningType.parcelado) {
      endDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + (installments - 1),
        _selectedDate.day,
      );
    }

    final result = await ref
        .read(transactionNotifierProvider.notifier)
        .saveTransaction(
          description: _descriptionController.text,
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          type: type,
          status: status,
          installments: installments,
          metadata: metadata,
          existingOrderId: _existingOrderId,
          isPlannedFlow: isPlannedFlow,
          planningType: planningType,
          planningInstallments: installments,
          startDate: _selectedDate,
          endDate: endDate,
          planningId: _planningId,
        );

    if (mounted) {
      if (result is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error.toString()),
            backgroundColor: AppColors.coralOrange,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.transactionSaveSuccess)));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accounts = ref.watch(accountsProvider).value ?? [];

    final isPlannedFlow =
        _currentType == TransactionType.plannedExpense ||
        _currentType == TransactionType.plannedIncome;

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
              if (_selectedCategory != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(
                        _selectedCategory!.color.replaceFirst('#', '0xFF'),
                      ),
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      _getIconData(_selectedCategory!.icon),
                      color: Color(
                        int.parse(
                          _selectedCategory!.color.replaceFirst('#', '0xFF'),
                        ),
                      ),
                    ),
                  ),
                  title: Text(_selectedCategory!.name),
                  subtitle: Text(l10n.transactionCategoriesSection),
                ),
                const SizedBox(height: 16),
              ] else if (_isTransfer) ...[
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
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.transactionDescriptionLabel,
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.transactionAmountLabel,
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isEmpty ?? true ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 16),

              if (!_isTransfer) ...[
                DropdownButtonFormField<_TransactionFormType>(
                  value: _formType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: _TransactionFormType.simple,
                      child: Text(l10n.transactionTypeSimple),
                    ),
                    DropdownMenuItem(
                      value: _TransactionFormType.installment,
                      child: Text(l10n.transactionTypeInstallment),
                    ),
                    DropdownMenuItem(
                      value: _TransactionFormType.recurrent,
                      child: Text(l10n.transactionTypeRecurrent),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _formType = v;
                        if (v == _TransactionFormType.simple) {
                          _installmentsController.text = '1';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],

              ListTile(
                title: Text(l10n.transactionDateLabel),
                subtitle: Text(DateFormat.yMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: isPlannedFlow ? DateTime.now() : DateTime(2000),
                    lastDate: isPlannedFlow ? DateTime(2100) : DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const Divider(),

              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: InputDecoration(
                  labelText: _isTransfer
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
                onChanged: (v) => setState(() => _selectedAccountId = v),
                validator: (v) => v == null ? l10n.fieldRequired : null,
              ),

              if (_isTransfer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _toAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.transactionToAccountLabel,
                  ),
                  items: accounts
                      .where((acc) => acc.id != _selectedAccountId)
                      .map(
                        (acc) => DropdownMenuItem(
                          value: acc.id,
                          child: Text(acc.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _toAccountId = v),
                  validator: (v) => v == null ? l10n.fieldRequired : null,
                ),
              ],

              if (_formType == _TransactionFormType.installment) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _installmentsController,
                  decoration: InputDecoration(
                    labelText: l10n.transactionInstallmentsLabel,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (_formType == _TransactionFormType.installment) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 1) return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(onPressed: _save, child: Text(l10n.saveButton)),
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
