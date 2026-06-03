import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/color_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/icon_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/file_extension.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/controllers/account_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../domain/models/account_model.dart';

class AccountFormScreen extends ConsumerWidget {
  final AccountModel? account;
  final AccountType? initialType;

  const AccountFormScreen({super.key, this.account, this.initialType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final labelStyle = TextStyle(color: AppColors.darkNavy);
    final descriptionStyle = TextStyle(color: Colors.black54, fontSize: 13);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          account == null ? l10n.accountCreateTitle : l10n.accountEditTitle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ResponsiveForm<AccountFormState, void, AccountFormNotifier>(
              AccountViewProviders.form(
                AccountFormArgs(type: initialType, account: account),
              ),
              submitLabel: l10n.saveButton,
              extraActions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancelButton),
                ),
              ],
              onSuccess: (_) => Navigator.pop(context),
              fieldsBuilder: (context, snapshot) {
                final state = snapshot.model;
                final notifier = snapshot.notifier;

                return [
                  if (account == null) ...[
                    FullWidthItem(
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
                        onSelectionChanged: (v) =>
                            notifier.updateRegistrationMethod(v.first),
                      ),
                    ),
                  ],
                  if (state.registrationMethod ==
                      AccountRegistrationMethod.document) ...[
                    FullWidthItem(Text(l10n.accountDocumentDescription, style: descriptionStyle)),
                    FullWidthItem(
                      DropTarget(
                        onDragDone: (detail) {
                          if (detail.files.isNotEmpty) {
                            final file = detail.files.first;
                            final extension = file.name.split('.').last.toLowerCase();
                            if (extension == 'pdf' || extension == 'ofx') {
                                showLoadingModal(
                                  context,
                                  notifier.updateFile(
                                    kIsWeb ? null : File(file.path),
                                    file.name,
                                  ),
                                  child: AnalysisLoadingView(
                                    firstPhaseDuration:
                                        extension == 'ofx'
                                            ? const Duration(seconds: 20)
                                            : const Duration(minutes: 1),
                                    totalDuration:
                                        extension == 'ofx'
                                            ? const Duration(seconds: 45)
                                            : const Duration(minutes: 5),
                                  ),
                                );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.accountDocumentAcceptedTypes),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.deepTurquoise.withValues(alpha: 0.5),
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.deepTurquoise.withValues(alpha: 0.05),
                          ),
                          child: Column(
                            children: [
                              if (state.selectedFile != null)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.description,
                                  ),
                                  title: Text(
                                    state.selectedFile!.fileName,
                                    style: labelStyle,
                                  ),
                                  subtitle:
                                      state.processingStatus ==
                                          AccountProcessingStatus.pending
                                      ? Text(
                                          l10n.accountAnalyzing,
                                          style: const TextStyle(
                                            color: AppColors.deepTurquoise,
                                            fontSize: 10,
                                          ),
                                        )
                                      : state.processingStatus ==
                                              AccountProcessingStatus.failed
                                          ? Text(
                                              state.errorMessage ??
                                                  l10n.errorUnknown,
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                                fontSize: 10,
                                              ),
                                            )
                                          : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => notifier.updateFile(null, null),
                                  ),
                                )
                              else ...[
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: AppColors.deepTurquoise,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.accountDropFile,
                                  style: descriptionStyle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['pdf', 'ofx'],
                                        );

                                    if (result != null) {
                                        final extension =
                                            result.files.single.name
                                                .split('.')
                                                .last
                                                .toLowerCase();
                                        showLoadingModal(
                                          context,
                                          notifier.updateFile(
                                            kIsWeb
                                                ? null
                                                : File(result.files.single.path!),
                                            result.files.single.name,
                                          ),
                                          child: AnalysisLoadingView(
                                            firstPhaseDuration:
                                                extension == 'ofx'
                                                    ? const Duration(seconds: 20)
                                                    : const Duration(minutes: 1),
                                            totalDuration:
                                                extension == 'ofx'
                                                    ? const Duration(seconds: 45)
                                                    : const Duration(minutes: 5),
                                          ),
                                        );
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(l10n.accountSelectFile),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.deepTurquoise,
                                    side: const BorderSide(color: AppColors.deepTurquoise),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.processingStatus ==
                        AccountProcessingStatus.completed) ...[
                      _buildDetectedSummary(context, state, l10n),
                      ..._buildManualFields(
                        context,
                        state,
                        notifier,
                        l10n,
                        labelStyle,
                        theme,
                      ),
                    ],
                  ] else ...[
                    if (state.creation)
                      FullWidthItem(Text(l10n.accountManualDescription, style: descriptionStyle)),
                    ..._buildManualFields(
                      context,
                      state,
                      notifier,
                      l10n,
                      labelStyle,
                      theme,
                    ),
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectedSummary(
    BuildContext context,
    AccountFormState state,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountDetectedDataTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.receipt_long,
              l10n.accountDetectedTransactions(state.detectedOrders.length),
            ),
            if (state.detectedOrders.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _showDetectedList(
                  context,
                  l10n.accountDetectedTransactionsTitle,
                  state.detectedOrders.map((o) {
                    return "${o.description} - R\$ ${o.amount.toStringAsFixed(2)}";
                  }).toList(),
                ),
                child: Text(
                  l10n.accountViewTransactions,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.deepTurquoise,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.accountDetectedConfirmation,
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _showDetectedList(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: AppColors.darkNavy)),
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
                style: TextStyle(color: AppColors.darkNavy),
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[800]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.darkNavy),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildManualFields(
    BuildContext context,
    AccountFormState state,
    AccountFormNotifier notifier,
    AppLocalizations l10n,
    TextStyle labelStyle,
    ThemeData theme,
  ) {
    final v = context.validations;
    return [
      ChipFormField<AccountType>(
        initialValue: state.type,
        decoration: InputDecoration(
          labelText: l10n.accountTypeLabel,
          labelStyle: labelStyle,
        ),
        options: AccountType.values.map((type) {
          return ChipFormFieldOption(
            value: type,
            label: l10n.fromAccountType(type),
          );
        }).toList(),
        onChanged: state.creation
            ? (v) => v != null ? notifier.updateType(v) : null
            : null,
      ),
      TextFormField(
        initialValue: state.name,
        decoration: InputDecoration(
          labelText: l10n.accountNameLabel,
          labelStyle: labelStyle,
        ),
        onChanged: notifier.updateName,
      ),
      IconFormField(
        initialValue: state.icon,
        decoration: InputDecoration(labelText: l10n.accountIconLabel),
        validator: v.all([v.notEmpty()]),
        onChanged: (icon) {
          if (icon != null) {
            notifier.updateIcon(icon);
          }
        },
      ),
      ColorFormField(
        initialValue: state.color,
        decoration: InputDecoration(labelText: l10n.accountColorLabel),
        validator: v.all([v.notEmpty()]),
        onChanged: (value) {
          if (value != null) {
            notifier.updateColor(value);
          }
        },
      ),
      MoneyFormField(
        initialValue: state.initialBalance,
        decoration: InputDecoration(
          labelText: l10n.initialBalanceLabel,
          labelStyle: labelStyle,
        ),
        onChanged: (v) => notifier.updateInitialBalance(v ?? 0.0),
      ),
      DateFormField(
        initialValue: state.initialBalanceDate,
        validator: v.all([v.notNull()]),
        decoration: InputDecoration(
          labelText: l10n.initialBalanceDateLabel,
          labelStyle: labelStyle,
        ),
        onChanged: (date) =>
            notifier.updateInitialBalanceDate(date ?? DateTime.now()),
      ),
      if (state.type == AccountType.creditCard) ...[
        MoneyFormField(
          initialValue: state.limit,
          decoration: InputDecoration(
            labelText: l10n.accountLimitLabel,
            labelStyle: labelStyle,
          ),
          onChanged: (v) => notifier.updateLimit(v ?? 0.0),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: state.dueDay?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: l10n.accountDueDayLabel,
                  labelStyle: labelStyle,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.updateDueDay(int.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: state.closingDay?.toString() ?? '',
                decoration: InputDecoration(
                  labelText: l10n.accountClosingDayLabel,
                  labelStyle: labelStyle,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    notifier.updateClosingDay(int.tryParse(v) ?? 1),
              ),
            ),
          ],
        ),
      ],
      if (state.type == AccountType.investment ||
          state.type == AccountType.debt) ...[
        TextFormField(
          initialValue: state.interestRate?.toString() ?? '',
          decoration: InputDecoration(
            labelText: l10n.accountInterestRateLabel,
            labelStyle: labelStyle,
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) =>
              notifier.updateInterestRate(double.tryParse(v) ?? 0.0),
        ),
      ],
    ];
  }

}
