import 'package:flutter/material.dart';
import 'package:funances/core/exceptions/callable_error_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/core/widgets/loading_modal.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/analysis_loading_view.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/goal/domain/models/goal_feasibility_model.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/model/goal_view_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/goal/presentation/providers/goal_form_provider.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

import '../../../../core/validation/validation.dart';

class GoalFormScreen extends ConsumerWidget {
  final GoalModel? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(goal == null ? l10n.addGoalButton : l10n.goalEditButton),
      ),
      body: SingleChildScrollView(
        child: ResponsiveForm<GoalFormState, void, GoalFormNotifier>(
          GoalViewProvider.form,
          submitLabel: l10n.continueButton,
          onSuccess: (_) => Navigator.pop(context),
          onCancel: () => Navigator.pop(context),
          extraActions: [_GoalAiAnalyzeButton(goal: goal)],
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
                validator: v.notEmpty().and(v.length(max: 150, min: 3)),
              ),
              // Valor de referência da meta. O rótulo muda porque o número
              // significa coisas diferentes: em `saveMoney`/`payDebt` é o
              // quanto se quer juntar/quitar; nas de redução é um TETO.
              MoneyFormField(
                initialValue: state.targetAmount > 0
                    ? state.targetAmount
                    : null,
                decoration: InputDecoration(
                  labelText: switch (state.type) {
                    GoalType.saveMoney => l10n.goalTargetAmountLabel,
                    GoalType.payDebt => l10n.goalDebtTotalLabel,
                    GoalType.reduceExpense ||
                    GoalType.reduceCreditCard => l10n.goalSpendingLimitLabel,
                  },
                  hintText: switch (state.type) {
                    GoalType.saveMoney => null,
                    GoalType.payDebt => l10n.goalDebtTotalHint,
                    GoalType.reduceExpense ||
                    GoalType.reduceCreditCard => l10n.goalSpendingLimitHint,
                  },
                ),
                onChanged: (v) => notifier.updateTargetAmount(v ?? 0),
                validator: v.notNull(),
              ),
              // O "valor atual" saiu do formulário: quem o mantém é o servidor,
              // pelos pagamentos, pelo realizado da categoria ou pelo saldo da
              // conta de dívida. Pedi-lo ao usuário era pedir um número que
              // seria sobrescrito no próximo lançamento.
              if (state.type == GoalType.reduceExpense)
                CategoryFormField(
                  initialValue: state.category,
                  decoration: InputDecoration(
                    labelText: l10n.goalCategoryLabel,
                  ),
                  onChanged: notifier.updateCategory,
                  validator: v.notNull(),
                  categoryType: CategoryType.expense,
                )
              else
                // O vínculo é decidido pelo TIPO, e o tipo decide também quais
                // contas fazem sentido: o servidor lê a amortização da conta
                // de dívida/cartão em `payDebt` e o gasto do cartão em
                // `reduceCreditCard`. Oferecer uma conta corrente ali seria
                // oferecer uma meta que nunca sai de zero.
                AccountFormField(
                  initialValue: state.accountId,
                  decoration: InputDecoration(
                    labelText: state.type == GoalType.payDebt
                        ? l10n.goalDebtAccountLabel
                        : l10n.goalAccountLabel,
                  ),
                  onChanged: notifier.updateAccountId,
                  validator: v.notEmpty(),
                  allowedTypes: switch (state.type) {
                    GoalType.payDebt => const {
                      AccountType.debt,
                      AccountType.creditCard,
                    },
                    GoalType.reduceCreditCard => const {AccountType.creditCard},
                    _ => null,
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

// ---------------------------------------------------------------------------
// Botão de análise IA — separado para poder usar Consumer e ler o form state
// ---------------------------------------------------------------------------
class _GoalAiAnalyzeButton extends ConsumerWidget {
  final GoalModel? goal;

  const _GoalAiAnalyzeButton({this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(GoalViewProvider.form);

    final isReady = formState.targetAmount > 0 && formState.name.isNotEmpty;

    return OutlinedButton.icon(
      icon: const Icon(Icons.auto_awesome, size: 18),
      label: Text(l10n.goalAnalyzeWithAi),
      onPressed: isReady
          ? () async {
              final messenger = ScaffoldMessenger.of(context);

              try {
                final result = await showLoadingModal(
                  context,
                  ref
                      .read(GoalViewProvider.feasibility.notifier)
                      .analyze(formState),
                  child: AnalysisLoadingView(
                    title: l10n.goalAiAnalyzing,
                    description: l10n.goalAiAnalyzingDesc,
                    firstPhaseDuration: const Duration(seconds: 15),
                    totalDuration: const Duration(seconds: 60),
                  ),
                );
                if (context.mounted) {
                  _showResultBottomSheet(context, l10n, result);
                }
              } catch (e) {
                // Limite diário de IA precisa chegar ao usuário; antes o erro
                // subia sem nenhum aviso na tela.
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      callableErrorMessage(
                        e,
                        l10n.goalAiError,
                        offlineMessage: l10n.errorOfflineCallable,
                      ),
                    ),
                  ),
                );
              }
            }
          : null,
    );
  }

  void _showResultBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    GoalFeasibilityModel result,
  ) {
    final (
      Color statusColor,
      IconData statusIcon,
      String statusLabel,
    ) = switch (result.status) {
      GoalFeasibilityStatus.feasible => (
        AppColors.success,
        Icons.check_circle_outline,
        l10n.goalAiFeasible,
      ),
      GoalFeasibilityStatus.challenging => (
        AppColors.warning,
        Icons.warning_amber_outlined,
        l10n.goalAiChallenging,
      ),
      GoalFeasibilityStatus.unrealistic => (
        AppColors.danger,
        Icons.cancel_outlined,
        l10n.goalAiUnrealistic,
      ),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final mq = MediaQuery.of(ctx);

        return Padding(
          // A alça da folha vem do `bottomSheetTheme` (`showDragHandle`); a
          // que era desenhada aqui à mão virava uma segunda alça.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + mq.padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: AppSpacing.allXs,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 32),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.goalAiResultTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        AppSpacing.gapXxs,
                        StatusPill(
                          label: statusLabel,
                          color: statusColor,
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLg,
              Text(l10n.goalAiReason, style: theme.textTheme.labelMedium),
              AppSpacing.gapXxs,
              Text(result.reason, style: theme.textTheme.bodyMedium),
              AppSpacing.gapMd,
              Text(l10n.goalAiSuggestion, style: theme.textTheme.labelMedium),
              AppSpacing.gapXxs,
              Text(
                result.suggestion,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              AppSpacing.gapLg,
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: statusColor,
                  foregroundColor: AppColors.inkInverse,
                ),
                child: Text(l10n.goalAiClose),
              ),
            ],
          ),
        );
      },
    );
  }
}
