import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/goal/presentation/providers/goal_form_provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

class GoalFormScreen extends ConsumerWidget {
  final GoalModel? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal == null ? l10n.addGoalButton : l10n.continueButton),
      ),
      body: SingleChildScrollView(
        child: ResponsiveForm<GoalFormState, void, GoalFormNotifier>(
          GoalViewProvider.form,
          submitLabel: l10n.continueButton,
          onSuccess: (_) => Navigator.pop(context),
          extraActions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
          ],
          fieldsBuilder: (context, snapshot) {
            final state = snapshot.model;
            final notifier = snapshot.notifier;
            final v = context.validations;

            return [
              // Tipo de Meta (Somente leitura se estiver editando)
              ChipFormField<GoalType>(
                initialValue: state.type,
                decoration: InputDecoration(labelText: l10n.goalTypeLabel),
                options: GoalType.values.map((type) {
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
                      label = l10n.goalTypePayDebt;
                      break;
                  }
                  return ChipFormFieldOption(value: type, label: label);
                }).toList(),
                onChanged: goal == null
                    ? (value) {
                        if (value != null) notifier.updateType(value);
                      }
                    : null,
                validator: v.all([v.notNull()]),
              ),
              TextFormField(
                initialValue: state.name,
                decoration: InputDecoration(labelText: l10n.goalNameLabel),
                onChanged: notifier.updateName,
                validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
              ),
              if (state.type == GoalType.saveMoney) ...[
                TextFormField(
                  initialValue: state.targetAmount > 0
                      ? state.targetAmount.toString()
                      : '',
                  decoration: InputDecoration(
                    labelText: l10n.goalTargetAmountLabel,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: v.all([v.notEmpty()]),
                ),
                TextFormField(
                  initialValue: state.currentAmount > 0
                      ? state.currentAmount.toString()
                      : '0.0',
                  decoration: InputDecoration(
                    labelText: l10n.goalCurrentAmountLabel,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: state.accountId == null,
                  onChanged: (v) =>
                      notifier.updateCurrentAmount(double.tryParse(v) ?? 0),
                  validator: v.all([v.notEmpty()]),
                ),
              ] else if (state.type == GoalType.payDebt) ...[
                TextFormField(
                  initialValue: state.targetAmount > 0
                      ? state.targetAmount.toString()
                      : '',
                  decoration: InputDecoration(
                    labelText: 'Valor Total da Dívida',
                    hintText: 'Quanto você deve no total?',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: v.all([v.notEmpty()]),
                ),
                TextFormField(
                  initialValue: state.currentAmount > 0
                      ? state.currentAmount.toString()
                      : '0.0',
                  decoration: InputDecoration(
                    labelText: 'Valor Já Pago',
                    hintText: 'Quanto você já amortizou?',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: state.accountId == null,
                  onChanged: (v) =>
                      notifier.updateCurrentAmount(double.tryParse(v) ?? 0),
                  validator: (v) => v == null || double.tryParse(v) == null
                      ? l10n.errorUnknown
                      : null,
                ),
                AccountFormField(
                  initialValue: state.accountId,
                  decoration: InputDecoration(
                    labelText: 'Vincular à Conta de Dívida',
                  ),
                  onChanged: notifier.updateAccountId,
                  validator: v.all([v.notEmpty()]),
                ),
              ] else ...[
                // Para redução de gastos
                TextFormField(
                  initialValue: state.targetAmount > 0
                      ? state.targetAmount.toString()
                      : '',
                  decoration: InputDecoration(
                    labelText: l10n.goalTargetAmountLabel,
                    hintText: 'Ex: 500.00 (Limite de gasto)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      notifier.updateTargetAmount(double.tryParse(v) ?? 0),
                  validator: v.all([v.notEmpty()]),
                ),
                TextFormField(
                  initialValue: state.averageSpending > 0
                      ? state.averageSpending.toString()
                      : '',
                  decoration: InputDecoration(
                    labelText: l10n.goalAverageSpendingLabel,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) =>
                      notifier.updateAverageSpending(double.tryParse(v) ?? 0),
                  validator: v.all([v.notEmpty()]),
                ),
              ],
              if (state.type == GoalType.reduceExpense)
                CategoryFormField(
                  initialValue: state.category,
                  decoration: InputDecoration(
                    labelText: l10n.goalCategoryLabel,
                  ),
                  onChanged: notifier.updateCategory,
                  validator: v.all([v.notNull()]),
                  categoryType: CategoryType.expense,
                ),
              if (state.type == GoalType.reduceCreditCard)
                AccountFormField(
                  initialValue: state.accountId,
                  decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                  onChanged: notifier.updateAccountId,
                  validator: v.all([v.notEmpty()]),
                ),
              if (state.type == GoalType.saveMoney)
                AccountFormField(
                  initialValue: state.accountId,
                  decoration: InputDecoration(labelText: l10n.goalAccountLabel),
                  onChanged: notifier.updateAccountId,
                  validator: v.all([v.notEmpty()]),
                ),
              DateFormField(
                initialValue: state.startDate,
                decoration: InputDecoration(labelText: l10n.goalStartDateLabel),
                validator: v.all([v.notNull()]),
                onChanged: (date) {
                  if (date != null) {
                    notifier.updateStartDate(date);
                  }
                },
              ),
              DateFormField(
                initialValue: state.deadline,
                decoration: InputDecoration(labelText: l10n.goalDeadlineLabel),
                validator: v.all([v.notNull()]),
                onChanged: (date) {
                  if (date != null) {
                    notifier.updateDeadline(date);
                  }
                },
              ),
            ];
          },
        ),
      ),
    );
  }
}
