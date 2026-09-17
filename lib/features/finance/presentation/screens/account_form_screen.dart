import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/color_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/icon_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/presentation/controllers/account_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form/bank_logo_option.dart';
import 'package:funances/features/finance/presentation/widgets/account_form/detected_summary.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:funances/features/workspace/presentation/widgets/members_form_field.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../domain/models/account_model.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:funances/core/utils/error_messages.dart';

class AccountFormScreen extends ConsumerWidget {
  final AccountModel? account;
  final AccountType? initialType;

  const AccountFormScreen({super.key, this.account, this.initialType});

  static const List<BankLogo> bankLogos = BankLogo.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final palette = context.palette;
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(color: palette.ink);
    final descriptionStyle = theme.textTheme.bodySmall?.copyWith(
      color: palette.ink2,
    );

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
              onCancel: () => Navigator.pop(context),
              onSuccess: (_) => Navigator.pop(context),
              pendingSyncMessage: l10n.accountSavePendingSync,
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
                    FullWidthItem(
                      Text(
                        l10n.accountDocumentDescription,
                        style: descriptionStyle,
                      ),
                    ),
                    FullWidthItem(
                      state.selectedFile != null
                          ? Container(
                              padding: AppSpacing.allMd,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: palette.tealText.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                borderRadius: AppRadius.brMd,
                                color: palette.tealText.withValues(alpha: 0.05),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.description,
                                  color: palette.tealText,
                                ),
                                title: Text(
                                  state.selectedFile!.name,
                                  style: labelStyle,
                                ),
                                subtitle:
                                    state.processingStatus ==
                                        AccountProcessingStatus.pending
                                    ? Text(
                                        l10n.accountAnalyzing,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: palette.tealText),
                                      )
                                    : state.processingStatus ==
                                          AccountProcessingStatus.failed
                                    ? Text(
                                        callableErrorMessage(
                                          state.analysisError ?? '',
                                          errorMessageFor(
                                            context,
                                            state.analysisError,
                                          ),
                                        ),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: palette.dangerText,
                                            ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: palette.dangerText,
                                  ),
                                  onPressed: () => notifier.updateFile(
                                    null,
                                    unnamedAccountLabel: l10n.unnamedAccount,
                                  ),
                                ),
                              ),
                            )
                          : StatementUploadPanel(
                              allowedExtensions: const ['pdf', 'ofx'],
                              title: l10n.accountDropFile,
                              dragOverTitle: l10n.statementDragOverTitle,
                              supportedFormatsText:
                                  l10n.accountDocumentAcceptedTypes,
                              selectFileButtonText: l10n.accountSelectFile,
                              onFileSelected: (document) {
                                final extension = document.extension;
                                showLoadingModal(
                                  context,
                                  notifier.updateFile(
                                    document,
                                    unnamedAccountLabel: l10n.unnamedAccount,
                                  ),
                                  child: AnalysisLoadingView(
                                    firstPhaseDuration: extension == 'ofx'
                                        ? const Duration(seconds: 20)
                                        : const Duration(minutes: 1),
                                    totalDuration: extension == 'ofx'
                                        ? const Duration(seconds: 45)
                                        : const Duration(minutes: 5),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (state.processingStatus ==
                        AccountProcessingStatus.completed) ...[
                      buildDetectedSummary(context, state, l10n),
                      ..._buildManualFields(
                        context,
                        ref,
                        state,
                        notifier,
                        l10n,
                        labelStyle,
                        theme,
                      ),
                    ],
                  ] else ...[
                    if (state.creation)
                      FullWidthItem(
                        Text(
                          l10n.accountManualDescription,
                          style: descriptionStyle,
                        ),
                      ),
                    ..._buildManualFields(
                      context,
                      ref,
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

  List<Widget> _buildManualFields(
    BuildContext context,
    WidgetRef ref,
    AccountFormState state,
    AccountFormNotifier notifier,
    AppLocalizations l10n,
    TextStyle? labelStyle,
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
      FullWidthItem(
        InputDecorator(
          decoration: InputDecoration(
            labelText: "Banco / Bandeira",
            labelStyle: labelStyle,
            border: const OutlineInputBorder(),
          ),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              BankLogoOption(
                logo: BankLogo.none,
                isSelected: state.bankLogo == BankLogo.none,
                onSelected: () => notifier.updateBankLogo(BankLogo.none),
                label: "Personalizado",
              ),
              ...BankLogo.values
                  .where((l) => l != BankLogo.none)
                  .map(
                    (logo) => BankLogoOption(
                      logo: logo,
                      isSelected: state.bankLogo == logo,
                      onSelected: () => notifier.updateBankLogo(logo),
                    ),
                  ),
            ],
          ),
        ),
      ),
      if (state.bankLogo == BankLogo.none) ...[
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
      ],
      FullWidthItem(
        MembersFormField(
          initialValue: state.ownerIds,
          onChanged: notifier.updateOwnerIds,
          label: context.l10n.accountOwnersLabel,
        ),
      ),
      if (state.creation) ...[
        MoneyFormField(
          initialValue: state.initialBalance,
          decoration: InputDecoration(
            labelText: _getInitialBalanceLabel(state.type, l10n),
            labelStyle: labelStyle,
          ),
          onChanged: (v) => notifier.updateInitialBalance(v ?? 0.0),
        ),
        DateFormField(
          initialValue: state.initialBalanceDate,
          validator: v.all([v.notNull()]),
          decoration: InputDecoration(
            labelText: _getInitialBalanceDateLabel(state.type, l10n),
            labelStyle: labelStyle,
          ),
          onChanged: (date) =>
              notifier.updateInitialBalanceDate(date ?? DateTime.now()),
        ),
      ],
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
            const SizedBox(width: AppSpacing.md),
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

  String _getInitialBalanceLabel(AccountType type, AppLocalizations l10n) {
    switch (type) {
      case AccountType.creditCard:
        return l10n.initialBalanceCreditCardLabel;
      case AccountType.investment:
        return l10n.initialBalanceInvestmentLabel;
      case AccountType.debt:
        return l10n.initialBalanceDebtLabel;
      case AccountType.checking:
        return l10n.initialBalanceLabel;
    }
  }

  String _getInitialBalanceDateLabel(AccountType type, AppLocalizations l10n) {
    switch (type) {
      case AccountType.investment:
        return l10n.initialBalanceInvestmentDateLabel;
      case AccountType.debt:
        return l10n.initialBalanceDebtDateLabel;
      default:
        return l10n.initialBalanceDateLabel;
    }
  }
}
