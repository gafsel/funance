import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_submit_flow.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_advanced_options.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_amount_field.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_category_accounts_section.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_delete_dialog.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_description_field.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_due_date_field.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_match_banners.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_payment_section.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_form/transaction_readonly_metadata.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Formulário de lançamento
//
// `build` tinha 749 linhas e ZERO widgets privados: um `fieldsBuilder` de 543
// linhas com os dois modos do formulário (editável e leitura) aninhados um no
// `else` do outro, mais o fluxo de save, os dois banners e o diálogo de
// exclusão. Agora cada seção é um arquivo em
// `presentation/widgets/transaction_form/` e o `build` só diz a ORDEM delas.
//
// As seções que emitem vários campos são FUNÇÕES e não widgets de propósito:
// o `ResponsiveForm` decide a largura item a item (`FullWidthItem` ocupa a
// linha, o resto divide em colunas), e agrupar campos num widget só os faria
// virar uma coluna única em tela larga.
// ─────────────────────────────────────────────────────────────────────────────

class TransactionFormScreen extends ConsumerWidget {
  final OrderType type;
  final OrderModel? order;
  final InstallmentModel? installment;
  final CategoryModel? category;
  final String? accountIdSource;
  final String? accountIdTarget;
  final InstallmentStatus? status;
  final String? description;
  final DateTime? dueDate;
  final double? amount;

  /// Avulso, parcelado ou recorrente. Só o nudge de gasto não planejado
  /// preenche: ele abre o formulário já em "toda vez".
  final InstallmentType? installmentType;

  /// Data de quitação forçada. Só o casamento com agendamento usa: o usuário
  /// está registrando o que gastou hoje, então a parcela é paga hoje.
  final DateTime? paidOn;

  /// Desfaz o casamento com um agendamento. Só a quitação aberta pelo banner
  /// recebe: é a única tela em que o usuário chegou por um toque que pode ter
  /// sido no agendamento errado, e sem esta saída ele fica editando a parcela
  /// de outra conta sem entender como voltar.
  final VoidCallback? onUnmatch;

  const TransactionFormScreen._({
    required this.type,
    this.status,
    this.order,
    this.installment,
    this.category,
    this.accountIdSource,
    this.accountIdTarget,
    this.description,
    this.dueDate,
    this.amount,
    this.installmentType,
    this.paidOn,
    this.onUnmatch,
  });

  factory TransactionFormScreen.creation({
    required OrderType type,
    InstallmentStatus? status,
    InstallmentType? installmentType,
    CategoryModel? category,
    String? accountIdSource,
    String? accountIdTarget,
    String? description,
    double? amount,
    DateTime? dueDate,
  }) {
    return TransactionFormScreen._(
      type: type,
      status: status,
      installmentType: installmentType,
      category: category,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
      description: description,
      amount: amount,
      dueDate: dueDate,
    );
  }

  factory TransactionFormScreen.updateInstallment({
    required InstallmentModel installment,
    InstallmentStatus? status,
    DateTime? paidOn,
    VoidCallback? onUnmatch,
  }) {
    return TransactionFormScreen._(
      type: installment.type,
      installment: installment,
      status: status,
      paidOn: paidOn,
      onUnmatch: onUnmatch,
    );
  }

  factory TransactionFormScreen.updateOrder({required OrderModel order}) {
    return TransactionFormScreen._(type: order.type, order: order);
  }

  bool get updateOrder => order != null;

  bool get updateInstallment => installment != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final creationArgs = TransactionCreationArgs(
      type: type,
      status: status,
      installmentType: installmentType,
      category: category,
      accountIdSource: accountIdSource,
      accountIdTarget: accountIdTarget,
      description: description,
      amount: amount,
      date: dueDate,
    );

    // O usuário escolheu um agendamento no banner: a tela deixa de criar uma
    // order e passa a quitar aquela parcela. Sem isso o lançamento novo
    // conviveria com o agendamento pendente, e o planejado contaria em dobro.
    if (!updateOrder && !updateInstallment) {
      final creationProvider = FinanceViewProviders.creationForm(creationArgs);
      final matched = ref.watch(
        creationProvider.select((state) => state.matchedInstallment),
      );

      if (matched != null) {
        return TransactionFormScreen.updateInstallment(
          installment: matched,
          status: InstallmentStatus.paid,
          paidOn: ref.watch(todayProvider),
          // O notifier de criação segue vivo enquanto esta tela está à
          // frente (o `watch` acima o segura), então desfazer o casamento
          // devolve o formulário com o valor e a descrição já digitados.
          onUnmatch: ref.read(creationProvider.notifier).clearMatch,
        );
      }
    }

    final provider = updateOrder
        ? FinanceViewProviders.updateOrderForm(order!)
        : updateInstallment && status == InstallmentStatus.paid
        // Confirmação de pagamento (ex.: vindo do wizard): abre o formulário
        // já como pago, com os campos de pagamento visíveis e preenchidos.
        ? FinanceViewProviders.transactionPaymentForm(
            TransactionPaymentArgs(installment: installment!, paidOn: paidOn),
          )
        : updateInstallment
        ? FinanceViewProviders.updateInstallmentForm(installment!)
        : FinanceViewProviders.creationForm(creationArgs);

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            if (updateOrder || updateInstallment) {
              return Text(l10n.historyEdit);
            }

            // O título lê o MESMO campo que decide o status do lançamento:
            // ler o parâmetro da rota fazia a tela dizer "Lançar" enquanto o
            // estado nascia como agendamento.
            final formState = ref.watch(provider);

            return Text(_creationTitle(l10n, formState));
          },
        ),
        actions: [
          if (onUnmatch != null)
            TextButton(
              key: const ValueKey('unmatch-action'),
              onPressed: onUnmatch,
              child: Text(l10n.transactionMatchUndo),
            ),
          if (updateOrder || updateInstallment)
            IconButton(
              icon: Icon(Icons.delete_outline, color: palette.dangerText),
              onPressed: () => TransactionDeleteDialog.show(context, provider),
            ),
        ],
      ),
      body:
          ResponsiveForm<
            TransactionFormState,
            dynamic,
            TransactionFormNotifier
          >(
            provider,
            submitLabel: l10n.saveButton,
            onCancel: () => Navigator.pop(context),
            onSubmit: (snapshot, loading) => submitTransactionForm(
              context,
              ref: ref,
              snapshot: snapshot,
              loading: loading,
              messenger: messenger,
              navigator: navigator,
            ),
            bannerBuilder: (context, snapshot) {
              final state = snapshot.model;
              final notifier = snapshot.notifier;

              if (!state.creation &&
                  state.status == InstallmentStatus.settled) {
                return MaterialBanner(
                  backgroundColor: AppColors.gold,
                  // O ouro é constante nos dois temas, então a tinta do aviso
                  // também precisa ser — a do tema escuro sumiria nele.
                  contentTextStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.goldInk,
                  ),
                  content: Text(l10n.transactionSettledAlert),
                  actions: [
                    TextButton(
                      onPressed: notifier.unsettle,
                      child: Text(l10n.transactionUnsettleAction),
                    ),
                  ],
                );
              }

              if (state.hasPendingMatches) {
                return pendingMatchesBanner(context, state, notifier);
              }

              if (state.searchingMatches) {
                return searchingMatchesBanner(context, state, notifier);
              }

              return null;
            },
            fieldsBuilder: (context, snapshot) {
              final state = snapshot.model;
              final notifier = snapshot.notifier;
              final isSettled = state.status == InstallmentStatus.settled;
              final isPaid = state.status == InstallmentStatus.paid;

              final isEditable =
                  !state.isInvoice && (!isSettled || state.creation);

              return [
                // 1. Badge de Tipo de Transação (Apenas em Edição)
                if (!state.creation)
                  FullWidthItem(TransactionTypeChip(state: state)),

                // 2. Campo de Valor (MoneyFormField ou Texto Estático)
                if (state.creation || state.hasAmount)
                  FullWidthItem(
                    TransactionAmountField(
                      state: state,
                      notifier: notifier,
                      isEditable: isEditable,
                    ),
                  ),

                // 3. Campo de Descrição (TextFormField ou Texto Estático)
                FullWidthItem(
                  TransactionDescriptionField(
                    state: state,
                    notifier: notifier,
                    isEditable: isEditable,
                  ),
                ),

                // 4. Seção de Categoria e Contas (Editável ou Metadados)
                if (state.creation || !isSettled)
                  ...transactionCategoryAndAccountFields(
                    context,
                    state,
                    notifier,
                  )
                else
                  ...transactionReadOnlyMetadata(context, state),

                // 5. Data de Vencimento / Transação (Editável ou Metadado)
                if (state.creation || state.hasAmount)
                  if (isEditable)
                    transactionDueDateInput(context, state, notifier)
                  else
                    FullWidthItem(
                      TransactionDueDateField(state: state, notifier: notifier),
                    ),

                // 6. Configurações Avançadas ("Mais Opções")
                FullWidthItem(
                  TransactionAdvancedOptions(
                    state: state,
                    notifier: notifier,
                    isSettled: isSettled,
                  ),
                ),

                // 7. Informações de Pagamento (Se não for Criação e estiver
                // Pago/Liquidado ou sem planejamento)
                if (!state.creation &&
                    (isPaid || isSettled || !state.hasAmount))
                  ...transactionPaymentFields(
                    context,
                    state,
                    notifier,
                    isSettled: isSettled,
                  ),
              ];
            },
          ),
    );
  }

  /// Título do formulário de criação.
  ///
  /// O status vem do ponto de entrada e não é mais editável aqui, então o
  /// título é o que diz ao usuário se ele está registrando algo que já
  /// aconteceu ou agendando algo que ainda vai acontecer.
  String _creationTitle(AppLocalizations l10n, TransactionFormState state) {
    final scheduled = state.status == InstallmentStatus.pending;

    return switch (state.type) {
      OrderType.income =>
        scheduled ? l10n.transactionPlanIncome : l10n.transactionAddIncome,
      OrderType.expense =>
        scheduled ? l10n.transactionPlanExpense : l10n.transactionAddExpense,
      OrderType.transfer =>
        scheduled ? l10n.transactionPlanTransfer : l10n.transactionTransfer,
    };
  }
}
