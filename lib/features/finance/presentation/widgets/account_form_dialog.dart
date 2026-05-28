import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/planning_model.dart';
import '../../domain/models/account_model.dart';
import '../providers/account_form_provider.dart';

class AccountFormDialog extends ConsumerWidget {
  final AccountModel? account;
  final AccountType? initialType;
  final Function(AccountModel, List<OrderModel>, List<PlanningModel>)? onSave;

  const AccountFormDialog({
    super.key,
    this.account,
    this.initialType,
    this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final args = AccountFormArgs(account: account, initialType: initialType);
    final state = ref.watch(accountFormProvider(args));
    final notifier = ref.read(accountFormProvider(args).notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labelStyle = TextStyle(color: isDark ? AppColors.pureWhite : AppColors.darkNavy);
    final descriptionStyle = TextStyle(color: isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : Colors.black54, fontSize: 13);

    ref.listen(accountFormProvider(args), (previous, next) {
      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } else if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.coralOrange),
        );
      }
    });

    return AlertDialog(
      title: Text(
        account == null ? l10n.accountCreateTitle : l10n.accountEditTitle,
        style: TextStyle(color: isDark ? AppColors.pureWhite : null),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account == null) ...[
              SegmentedButton<AccountRegistrationMethod>(
                segments: [
                  ButtonSegment(
                    value: AccountRegistrationMethod.document,
                    label: Text(l10n.accountMethodDocument),
                    icon: const Icon(Icons.description),
                  ),
                  ButtonSegment(
                    value: AccountRegistrationMethod.manual,
                    label: Text(l10n.accountMethodManual),
                    icon: const Icon(Icons.edit),
                  ),
                ],
                selected: {state.registrationMethod},
                onSelectionChanged: (v) => notifier.updateRegistrationMethod(v.first),
              ),
              const SizedBox(height: 24),
            ],
            if (state.registrationMethod == AccountRegistrationMethod.document) ...[
              Text(
                l10n.accountDocumentDescription,
                style: descriptionStyle,
              ),
              const SizedBox(height: 16),
              DropTarget(
                onDragDone: (detail) {
                  if (detail.files.isNotEmpty) {
                    final file = detail.files.first;
                    final extension = file.name.split('.').last.toLowerCase();
                    if (extension == 'pdf' || extension == 'ofx') {
                      notifier.updateFile(
                        kIsWeb ? null : File(file.path),
                        file.name,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.accountDocumentAcceptedTypes)),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.paleGold.withValues(alpha: 0.5),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.paleGold.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    children: [
                      if (state.fileName != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description, color: AppColors.paleGold),
                          title: Text(state.fileName!, style: labelStyle),
                          subtitle: state.processingStatus == AccountProcessingStatus.pending
                              ? Text(l10n.accountAnalyzing, style: const TextStyle(color: AppColors.paleGold, fontSize: 10))
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => notifier.updateFile(null, null),
                          ),
                        )
                      else ...[
                        const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.paleGold),
                        const SizedBox(height: 12),
                        Text(
                          l10n.accountDropFile,
                          style: descriptionStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'ofx'],
                            );
                            if (result != null) {
                              notifier.updateFile(
                                kIsWeb ? null : File(result.files.single.path!),
                                result.files.single.name,
                              );
                            }
                          },
                          icon: const Icon(Icons.upload_file),
                          label: Text(l10n.accountSelectFile),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.paleGold,
                            side: const BorderSide(color: AppColors.paleGold),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.processingStatus == AccountProcessingStatus.completed) ...[
                const SizedBox(height: 24),
                _buildDetectedSummary(context, state, isDark, l10n),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildManualFields(context, state, notifier, l10n, labelStyle, theme, isDark),
              ],
            ] else ...[
              Text(
                l10n.accountManualDescription,
                style: descriptionStyle,
              ),
              const SizedBox(height: 24),
              _buildManualFields(context, state, notifier, l10n, labelStyle, theme, isDark),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.cancelButton, style: TextStyle(color: isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : null)),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : () => notifier.submit(onSave: onSave),
          child: state.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.saveButton),
        ),
      ],
    );
  }

  Widget _buildDetectedSummary(BuildContext context, AccountFormState state, bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountDetectedDataTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.paleGold : AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.receipt_long,
              l10n.accountDetectedTransactions(state.detectedOrders.length),
              isDark,
            ),
            if (state.detectedOrders.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showDetectedList(
                  context,
                  l10n.accountDetectedTransactionsTitle,
                  state.detectedOrders.map((o) {
                    return "${o.description} - R\$ ${o.totalAmount.toStringAsFixed(2)}";
                  }).toList(),
                  isDark,
                ),
                child: Text(l10n.accountViewTransactions, style: const TextStyle(fontSize: 12, color: AppColors.paleGold)),
              ),
            ],
          ],
        ),
        if (state.detectedPlannings.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                Icons.insights,
                l10n.accountDetectedPlannings(state.detectedPlannings.length),
                isDark,
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showDetectedList(
                  context,
                  l10n.accountDetectedPlanningsTitle,
                  state.detectedPlannings.map((p) {
                    return "${p.category.name} - R\$ ${p.amount.toStringAsFixed(2)}";
                  }).toList(),
                  isDark,
                ),
                child: Text(l10n.accountViewPlannings, style: const TextStyle(fontSize: 12, color: AppColors.paleGold)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.accountDetectedConfirmation,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.pureWhite.withValues(alpha: 0.6) : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDetectedList(BuildContext context, String title, List<String> items, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNavy : null,
        title: Text(title, style: TextStyle(color: isDark ? AppColors.paleGold : AppColors.darkNavy)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                items[index],
                style: TextStyle(color: isDark ? AppColors.pureWhite : AppColors.darkNavy),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.paleGold.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.paleGold.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? AppColors.paleGold : Colors.blue[800],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.pureWhite : AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFields(
    BuildContext context,
    AccountFormState state,
    AccountFormNotifier notifier,
    AppLocalizations l10n,
    TextStyle labelStyle,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AccountType>(
          value: state.type,
          decoration: InputDecoration(
            labelText: l10n.accountTypeLabel,
            labelStyle: labelStyle,
          ),
          dropdownColor: isDark ? AppColors.darkNavy : null,
          items: AccountType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(
                _getAccountTypeName(context, type),
                style: TextStyle(color: isDark ? AppColors.pureWhite : null),
              ),
            );
          }).toList(),
          onChanged: (v) => v != null ? notifier.updateType(v) : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: TextEditingController(text: state.name)
            ..selection = TextSelection.collapsed(offset: state.name.length),
          style: TextStyle(color: isDark ? AppColors.pureWhite : null),
          decoration: InputDecoration(
            labelText: l10n.accountNameLabel,
            labelStyle: labelStyle,
          ),
          onChanged: notifier.updateName,
        ),
        const SizedBox(height: 16),
        Text(l10n.accountIconLabel,
            style: theme.textTheme.titleSmall?.copyWith(color: isDark ? AppColors.pureWhite : AppColors.darkNavy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _availableIcons.entries.map((entry) {
            final isSelected = state.icon == entry.key;
            return GestureDetector(
              onTap: () => notifier.updateIcon(entry.key),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: theme.colorScheme.primary) : null,
                ),
                child: Icon(
                  entry.value,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.pureWhite.withValues(alpha: 0.5) : Colors.grey),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(l10n.accountColorLabel,
            style: theme.textTheme.titleSmall?.copyWith(color: isDark ? AppColors.pureWhite : AppColors.darkNavy)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppColors.categoryColors.map((color) {
            final colorHex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
            final isSelected = state.color.toUpperCase() == colorHex;
            return GestureDetector(
              onTap: () => notifier.updateColor(colorHex),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                  boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        TextFormField(
          controller: TextEditingController(text: state.initialBalance.toString())
            ..selection = TextSelection.collapsed(offset: state.initialBalance.toString().length),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: isDark ? AppColors.pureWhite : null),
          decoration: InputDecoration(
            labelText: l10n.initialBalanceLabel,
            labelStyle: labelStyle,
          ),
          onChanged: (v) => notifier.updateInitialBalance(double.tryParse(v) ?? 0.0),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.initialBalanceDateLabel, style: labelStyle),
          subtitle: Text(
            DateFormat.yMd(Localizations.localeOf(context).languageCode).format(state.initialBalanceDate),
            style: TextStyle(color: isDark ? AppColors.pureWhite.withValues(alpha: 0.7) : Colors.black87),
          ),
          trailing: Icon(Icons.calendar_today, color: isDark ? AppColors.pureWhite : AppColors.darkNavy),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.initialBalanceDate,
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              notifier.updateInitialBalanceDate(picked);
            }
          },
        ),
        if (state.type == AccountType.creditCard) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: TextEditingController(text: state.limit?.toString() ?? '')
              ..selection = TextSelection.collapsed(offset: (state.limit?.toString() ?? '').length),
            style: TextStyle(color: isDark ? AppColors.pureWhite : null),
            decoration: InputDecoration(
              labelText: l10n.accountLimitLabel,
              labelStyle: labelStyle,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => notifier.updateMetadata('limit', double.tryParse(v)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: state.dueDay?.toString() ?? '')
                    ..selection = TextSelection.collapsed(offset: (state.dueDay?.toString() ?? '').length),
                  style: TextStyle(color: isDark ? AppColors.pureWhite : null),
                  decoration: InputDecoration(
                    labelText: l10n.accountDueDayLabel,
                    labelStyle: labelStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateMetadata('dueDay', int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: TextEditingController(text: state.closingDay?.toString() ?? '')
                    ..selection = TextSelection.collapsed(offset: (state.closingDay?.toString() ?? '').length),
                  style: TextStyle(color: isDark ? AppColors.pureWhite : null),
                  decoration: InputDecoration(
                    labelText: l10n.accountClosingDayLabel,
                    labelStyle: labelStyle,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => notifier.updateMetadata('closingDay', int.tryParse(v)),
                ),
              ),
            ],
          ),
        ],
        if (state.type == AccountType.investment || state.type == AccountType.debt) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: TextEditingController(text: state.interestRate?.toString() ?? '')
              ..selection = TextSelection.collapsed(offset: (state.interestRate?.toString() ?? '').length),
            style: TextStyle(color: isDark ? AppColors.pureWhite : null),
            decoration: InputDecoration(
              labelText: l10n.accountInterestRateLabel,
              labelStyle: labelStyle,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => notifier.updateMetadata('interestRate', double.tryParse(v)),
          ),
        ],
      ],
    );
  }

  String _getAccountTypeName(BuildContext context, AccountType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case AccountType.checking:
        return l10n.accountTypeChecking;
      case AccountType.investment:
        return l10n.accountTypeInvestment;
      case AccountType.creditCard:
        return l10n.accountTypeCreditCard;
      case AccountType.debt:
        return l10n.accountTypeDebt;
    }
  }

  static const Map<String, IconData> _availableIcons = {
    'account_balance': Icons.account_balance,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'account_balance_wallet': Icons.account_balance_wallet,
    'money': Icons.money,
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'trending_down': Icons.trending_down,
    'payments': Icons.payments,
    'wallet': Icons.wallet,
    'show_chart': Icons.show_chart,
    'pie_chart': Icons.pie_chart,
    'monetization_on': Icons.monetization_on,
  };
}
