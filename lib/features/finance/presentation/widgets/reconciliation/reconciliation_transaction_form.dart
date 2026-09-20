import 'package:flutter/material.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/reconciliation_model.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';

/// Formulário de registro/edição de um casamento, em folha modal.
///
/// Os quatro primeiros campos são leitura: valor, data, status e conta vêm do
/// extrato e não se discutem. O que o usuário decide é descrição, tipo,
/// categoria (ou conta de destino, se for transferência) e parcelamento.
class ReconciliationTransactionForm extends StatefulWidget {
  final ReconciliationMatch match;
  final AccountModel account;

  const ReconciliationTransactionForm({
    super.key,
    required this.match,
    required this.account,
  });

  @override
  State<ReconciliationTransactionForm> createState() =>
      _ReconciliationTransactionFormState();
}

class _ReconciliationTransactionFormState
    extends State<ReconciliationTransactionForm> {
  late String description;
  CategoryModel? category;
  late OrderType type;
  String? targetAccountId;
  int? installmentCount;
  bool isRecurring = false;

  @override
  void initState() {
    super.initState();
    description =
        widget.match.customDescription ??
        widget.match.systemInstallment?.description ??
        widget.match.documentTransaction?.description ??
        "";
    category =
        widget.match.customCategory ??
        widget.match.systemInstallment?.category ??
        widget.match.documentTransaction?.category;
    final docTx = widget.match.documentTransaction;
    final sysInst = widget.match.systemInstallment;

    // Se temos transação do documento, confiamos no tipo dela
    // Caso contrário (transação só do sistema), confiamos no tipo do sistema
    type = (widget.match.customType ?? docTx?.type ?? sysInst?.type)!;

    targetAccountId =
        widget.match.targetAccountId ??
        widget.match.systemInstallment?.accountIdTarget;
    installmentCount =
        widget.match.installmentCount ??
        widget.match.systemInstallment?.installmentCount;
    isRecurring = (installmentCount ?? 1) > 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = context.locale;
    final dTx = widget.match.documentTransaction;
    final sInst = widget.match.systemInstallment;

    final isCredit = dTx != null
        ? dTx.type == OrderType.income
        : (sInst?.type == OrderType.income);
    final isDebit = !isCredit;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: AppGradients.background,
        borderRadius: AppRadius.brSheet,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: AppSpacing.allLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.reconciliationActionRegister,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.inkInverse,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.inkInverse),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              // Valor, data, status e conta vêm do extrato: são leitura.
              _ReadOnlyMetadataGrid(
                amount: dTx != null
                    ? dTx.amount.abs().asCurrency(locale: locale)
                    : sInst?.referenceAmount.asCurrency(locale: locale),
                date: (dTx?.date ?? sInst?.referenceDate ?? DateTime.now())
                    .formated(l10n.formatSimpleDate, locale),
                accountName: widget.account.name,
                accountLabel: type == OrderType.transfer
                    ? (isCredit
                          ? l10n.transactionToAccountLabel
                          : l10n.transactionFromAccountLabel)
                    : l10n.reconciliationAccountLabel,
              ),
              AppSpacing.gapMd,
              TextFormField(
                initialValue: description,
                onChanged: (value) => setState(() => description = value),
                decoration: InputDecoration(
                  labelText: l10n.transactionDescriptionLabel,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkInverse,
                ),
              ),
              AppSpacing.gapMd,
              ChipFormField<OrderType>(
                initialValue: type,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      type = value;
                      if (type == OrderType.transfer) {
                        category = null;
                      }
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.transactionTypeLabel,
                ),
                options: [
                  if (isCredit)
                    ChipFormFieldOption(
                      value: OrderType.income,
                      label: l10n.transactionTypeIncome,
                    ),
                  if (isDebit)
                    ChipFormFieldOption(
                      value: OrderType.expense,
                      label: l10n.transactionTypeExpense,
                    ),
                  ChipFormFieldOption(
                    value: OrderType.transfer,
                    label: l10n.transactionTypeTransfer,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              if (type == OrderType.transfer) ...[
                AccountFormField(
                  initialValue: targetAccountId,
                  excludeAccountId: widget.account.id,
                  onChanged: (value) => setState(() => targetAccountId = value),
                  decoration: InputDecoration(
                    labelText: isCredit
                        ? l10n.transactionFromAccountLabel
                        : l10n.transactionToAccountLabel,
                  ),
                ),
              ] else ...[
                CategoryFormField(
                  initialValue: category,
                  categoryType: type.categoryType,
                  onChanged: (value) => setState(() => category = value),
                ),
              ],
              AppSpacing.gapMd,
              SwitchListTile(
                title: Text(
                  l10n.transactionTypeInstallment,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkInverse,
                  ),
                ),
                value: isRecurring,
                onChanged: (value) => setState(() {
                  isRecurring = value;
                  if (!value) installmentCount = null;
                  if (value && installmentCount == null) installmentCount = 2;
                }),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: theme.colorScheme.primary,
              ),
              if (isRecurring) ...[
                AppSpacing.gapMd,
                TextFormField(
                  initialValue: installmentCount?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      setState(() => installmentCount = int.tryParse(value)),
                  decoration: InputDecoration(
                    labelText: l10n.transactionInstallmentsLabel,
                    prefixIcon: const Icon(Icons.repeat),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkInverse,
                  ),
                ),
              ],
              AppSpacing.gapXl,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final updatedMatch = widget.match.copyWith(
                      status: ReconciliationMatchStatus.matched,
                      customDescription: description,
                      customCategory: category,
                      customType: type,
                      targetAccountId: targetAccountId,
                      installmentCount: installmentCount,
                    );
                    Navigator.pop(context, updatedMatch);
                  },
                  child: Text(l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Os quatro campos de leitura do topo do formulário.
///
/// Eram quatro `TextFormField` desabilitados escritos por extenso, idênticos
/// menos por rótulo, ícone e valor: 86 linhas para dizer a mesma coisa quatro
/// vezes.
class _ReadOnlyMetadataGrid extends StatelessWidget {
  const _ReadOnlyMetadataGrid({
    required this.amount,
    required this.date,
    required this.accountName,
    required this.accountLabel,
  });

  final String? amount;
  final String date;
  final String accountName;
  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      // O pai é um `SingleChildScrollView`: altura sem limite, então esta
      // coluna precisa se medir pelo conteúdo.
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _ReadOnlyField(
                value: amount,
                label: l10n.transactionAmountLabel,
                icon: Icons.attach_money,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ReadOnlyField(
                value: date,
                label: l10n.date,
                icon: Icons.calendar_today,
              ),
            ),
          ],
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: _ReadOnlyField(
                value: l10n.transactionStatusSettled,
                label: l10n.transactionStatusLabel,
                icon: Icons.assignment_turned_in,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ReadOnlyField(
                value: accountName,
                label: accountLabel,
                icon: Icons.account_balance,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String? value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A folha é escura; o campo desabilitado precisa da tinta terciária, que
    // é a mesma nos dois temas, e não da linha clara do tema de papel.
    final disabled = context.palette.ink3;

    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: disabled),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide(color: disabled),
        ),
      ),
      enabled: false,
      style: theme.textTheme.bodyMedium?.copyWith(color: disabled),
    );
  }
}
