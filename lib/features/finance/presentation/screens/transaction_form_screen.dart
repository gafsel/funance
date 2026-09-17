import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/form/chip_form_field.dart';
import 'package:funances/core/form/date_form_field.dart';
import 'package:funances/core/form/loading_button.dart';
import 'package:funances/core/form/responsive_form.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/color_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/icons_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:funances/features/finance/presentation/widgets/category_form_field.dart';
import 'package:funances/features/finance/presentation/widgets/replication_cascade_dialog.dart';
import 'package:funances/features/finance/presentation/widgets/unplanned_nudge_sheet.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Traduz o estado do formulário na pergunta que o [UnplannedNudgeService]
/// responde (F3.2).
///
/// Fica fora da tela para ser testável sem widget: o que decide o convite é
/// esta combinação de sinais, não a renderização.
Future<UnplannedNudge?> evaluateUnplannedNudge(
  UnplannedNudgeService service,
  TransactionFormState before,
  DateTime today,
) {
  return service.evaluate(
    category: before.category,
    type: before.type,
    status: before.status,
    // Só lançamento novo: editar uma order antiga ou quitar uma parcela não
    // é "gastei fora do plano agora".
    isNewOrder: before.creation,
    // Se o usuário casou com um agendamento, o gasto estava previsto — e
    // nesse caminho quem salva nem é este formulário.
    matchedPending: before.matchedInstallmentId != null,
    amount: before.amount,
    dueDate: before.dueDate,
    today: today,
    accountId: before.accountIdSource,
  );
}

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
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context, provider),
            ),
        ],
      ),
      body: ResponsiveForm<TransactionFormState, dynamic, TransactionFormNotifier>(
        provider,
        submitLabel: l10n.saveButton,
        onCancel: () => Navigator.pop(context),
        onSubmit: (snapshot, loading) async {
          if (!snapshot.validate()) return;

          final notifier = snapshot.notifier;

          // Lidos no início do submit, e não no build: o convite de gasto não
          // planejado acontece DEPOIS que esta tela sai da pilha, quando o
          // `ref` dela já não responde. Lê-los no build criaria o serviço em
          // toda abertura do formulário, inclusive nas que nunca salvam.
          final nudgeService = ref.read(UnplannedNudgeDomainProviders.service);
          final analytics = ref.read(analyticsServiceProvider);
          final today = ref.read(todayProvider);

          ReplicationCascade cascade = ReplicationCascade.none;

          // `shouldAskCascade` já compara o estado com a parcela persistida:
          // só chega aqui quem mexeu em algo que faz sentido replicar.
          if (notifier.shouldAskCascade) {
            final selectedCascade = await ReplicationCascadeDialog.showUpdate(
              context,
            );

            if (selectedCascade == null) return;
            cascade = selectedCascade;
          }

          notifier.updateReplicationCascade(cascade);

          // O estado ANTES do save: `submit()` grava o `orderId`, e a partir
          // daí `creation` é falso — perguntar depois faria o convite nunca
          // aparecer para o caso que ele existe para atender.
          final before = snapshot.model;

          final result = await loading(notifier.submit());
          if (result == null) return;

          unawaited(HapticFeedback.mediumImpact());

          // O que prometer depende de o servidor ter confirmado. As parcelas
          // do lançamento nascem de um trigger no servidor: enquanto a escrita
          // estiver pendente elas não existem em lugar nenhum, e dizer
          // "salvo!" faria o usuário procurar na lista algo que ainda não está
          // lá — foi assim que o lançamento "sumia" offline.
          final pendingSync = notifier.lastWriteIsPending;

          messenger.showSnackBar(
            SnackBar(
              content: Text(switch ((pendingSync, before.creation)) {
                (false, _) => l10n.transactionSaveSuccess,
                // Só a CRIAÇÃO promete parcelas: numa edição elas já
                // existem, e repetir a frase delas confundiria.
                (true, true) => l10n.transactionSavePendingSync,
                (true, false) => l10n.savePendingSync,
              }),
              duration: pendingSync
                  ? const Duration(seconds: 6)
                  : const Duration(seconds: 4),
            ),
          );

          // F3.2 — o convite é decidido ANTES do pop (o `ref` desta tela
          // morre com ela) e mostrado DEPOIS (sobre ele, o usuário navega
          // para a recorrência ou para o limite sem o formulário atrás).
          final nudge = await evaluateUnplannedNudge(
            nudgeService,
            before,
            today,
          );

          // O contexto do próprio Navigator sobrevive ao pop desta rota; o
          // desta tela, não.
          final sheetContext = navigator.context;

          navigator.pop(true);

          if (nudge == null || !sheetContext.mounted) return;

          final shown = await UnplannedNudgeSheet.show(
            sheetContext,
            nudge: nudge,
            analytics: analytics,
          );

          // Marca só o que de fato apareceu: gravar antes de abrir fazia o
          // usuário perder o convite do dia quando o sheet não chegava à tela
          // (contexto já desmontado), sem nunca ter visto nada.
          if (shown) {
            await nudgeService.markShown(nudge.category.id, today);
          }
        },
        bannerBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;

          if (!state.creation && state.status == InstallmentStatus.settled) {
            return MaterialBanner(
              backgroundColor: AppColors.successGold,
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
            return _pendingMatchesBanner(context, state, notifier);
          }

          if (state.searchingMatches) {
            return _searchingMatchesBanner(context, state, notifier);
          }

          return null;
        },
        fieldsBuilder: (context, snapshot) {
          final state = snapshot.model;
          final notifier = snapshot.notifier;
          final theme = Theme.of(context);
          final l10n = context.l10n;
          final v = context.validations;
          final isSettled = state.status == InstallmentStatus.settled;
          final isPaid = state.status == InstallmentStatus.paid;

          final isEditable = !state.isInvoice && (!isSettled || state.creation);

          String amountLabel = l10n.transactionAmountLabel;
          if (state.installmentType == InstallmentType.recurring) {
            amountLabel = l10n.transactionAmountRecurringLabel;
          } else if (state.installmentType == InstallmentType.installment) {
            if (!state.creation ||
                state.amountType == TransactionAmountType.installment) {
              amountLabel = l10n.transactionAmountInstallmentLabel;
            } else {
              amountLabel = l10n.transactionAmountTotalLabel;
            }
          }

          return [
            // 1. Badge de Tipo de Transação (Apenas em Edição)
            if (!state.creation)
              FullWidthItem(
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      state.type == OrderType.expense
                          ? l10n.transactionTypeExpense
                          : state.type == OrderType.income
                          ? l10n.transactionTypeIncome
                          : l10n.transactionTypeTransfer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: state.type == OrderType.expense
                        ? AppColors.error
                        : state.type == OrderType.income
                        ? AppColors.limeGreen
                        : theme.colorScheme.primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

            // 2. Campo de Valor (MoneyFormField ou Texto Estático)
            if (state.creation || state.hasAmount)
              if (isEditable)
                FullWidthItem(
                  MoneyFormField(
                    initialValue: state.amount,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: state.type == OrderType.expense
                          ? AppColors.error
                          : state.type == OrderType.income
                          ? AppColors.limeGreen
                          : theme.colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      labelText: amountLabel,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (v) => notifier.updateAmount(v ?? 0.0),
                    validator: v.all([v.notNull()]),
                    enabled: true,
                  ),
                )
              else
                FullWidthItem(
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            amountLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.amount.asCurrency(locale: context.locale),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: state.type == OrderType.expense
                                  ? AppColors.error
                                  : state.type == OrderType.income
                                  ? AppColors.limeGreen
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            // 3. Campo de Descrição (TextFormField ou Texto Estático)
            if (isEditable)
              FullWidthItem(
                TextFormField(
                  initialValue: state.description,
                  decoration: InputDecoration(
                    labelText: l10n.transactionDescriptionLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: notifier.updateDescription,
                  validator: v.all([v.notEmpty(), v.length(max: 150, min: 3)]),
                  enabled: true,
                ),
              )
            else
              FullWidthItem(
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      state.description,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // 4. Seção de Categoria e Contas (Editável ou Metadados)
            if (state.creation || !isSettled) ...[
              // Modo Editável
              if (state.isInvoice)
                CategoryFormField.invoice(
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                )
              else if (state.type == OrderType.transfer) ...[
                CategoryFormField.transfer(
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                ),
                // A transferência não escolhe categoria: o servidor deriva
                // uma categoria virtual dos tipos das contas. O chip conta
                // isso em vez de trocar a categoria por baixo dos panos.
                if (state.transferAccounting != null)
                  FullWidthItem(
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: Icon(
                          state.transferAccounting == TransferAccounting.debt
                              ? Icons.trending_down
                              : Icons.savings_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        label: Text(
                          state.transferAccounting == TransferAccounting.debt
                              ? l10n.transactionTransferCountsAsDebt
                              : l10n.transactionTransferCountsAsInvestment,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ] else
                CategoryFormField(
                  initialValue: state.category,
                  categoryType: state.type.categoryType,
                  decoration: InputDecoration(
                    labelText: l10n.transactionCategoriesSection,
                  ),
                  onChanged: notifier.updateCategory,
                  validator: v.all([v.notNull()]),
                  autoOpen: state.creation && state.type != OrderType.transfer,
                ),

              AccountFormField(
                // O FormField semeia o valor no primeiro build; a conta
                // padrão chega depois, de uma consulta. A key faz o campo
                // renascer com o default já preenchido.
                key: ValueKey('account-source-${state.accountIdSource}'),
                initialValue: state.accountIdSource,
                decoration: InputDecoration(
                  labelText: state.type == OrderType.transfer
                      ? l10n.transactionFromAccountLabel
                      : l10n.transactionAccountLabel,
                ),
                onChanged: notifier.updateAccountIdSource,
                // Conta é obrigatória também em agendamento: um lançamento
                // futuro sem conta não entra em projeção de saldo nenhuma.
                validator: v.all([v.notEmpty()]),
                autoOpen:
                    state.creation &&
                    !state.resolvingAccount &&
                    state.accountIdSource == null,
              ),
              if (state.type == OrderType.transfer)
                AccountFormField(
                  initialValue: state.accountIdTarget,
                  decoration: InputDecoration(
                    labelText: l10n.transactionToAccountLabel,
                  ),
                  onChanged: notifier.updateAccountIdTarget,
                  validator: v.all([v.notEmpty()]),
                  autoOpen:
                      state.creation &&
                      state.accountIdSource != null &&
                      state.type == OrderType.transfer,
                ),
            ] else ...[
              // Modo Leitura (Metadados Limpos)
              if (state.category != null)
                FullWidthItem(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "${l10n.transactionCategoriesSection}: ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: state.category!.color
                                .asColor()
                                .withValues(alpha: 0.2),
                            child: Icon(
                              state.category!.icon.asIcon(),
                              size: 12,
                              color: state.category!.color.asColor(),
                            ),
                          ),
                          label: Text(state.category!.name),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),

              if (state.accountIdSource != null)
                FullWidthItem(
                  Consumer(
                    builder: (context, ref, child) {
                      final accountAsync = ref.watch(
                        AccountViewProviders.byId(state.accountIdSource!),
                      );
                      return accountAsync.when(
                        data: (account) {
                          if (account == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  state.type == OrderType.transfer
                                      ? "${l10n.transactionFromAccountLabel}: "
                                      : "${l10n.transactionAccountLabel}: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AccountLogo(account: account, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  account.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),

              if (state.type == OrderType.transfer &&
                  state.accountIdTarget != null)
                FullWidthItem(
                  Consumer(
                    builder: (context, ref, child) {
                      final accountAsync = ref.watch(
                        AccountViewProviders.byId(state.accountIdTarget!),
                      );
                      return accountAsync.when(
                        data: (account) {
                          if (account == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "${l10n.transactionToAccountLabel}: ",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AccountLogo(account: account, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  account.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ),
            ],

            // 5. Data de Vencimento / Transação (Editável ou Metadado)
            if (state.creation || state.hasAmount)
              if (isEditable)
                DateFormField(
                  initialValue: state.dueDate,
                  onChanged: (date) {
                    if (date != null) {
                      notifier.updateDueDate(date);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.transactionDateLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: v.all([v.notNull()]),
                )
              else
                FullWidthItem(
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          "${l10n.transactionDateLabel}: ",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.dueDate.formated(l10n.formatSimpleDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            // 6. Configurações Avançadas ("Mais Opções")
            FullWidthItem(
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    l10n.transactionMoreOptions,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.all(8),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        if (state.creation)
                          ChipFormField<OrderType>(
                            initialValue: state.type,
                            decoration: InputDecoration(
                              labelText: l10n.transactionOrderTypeLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: OrderType.expense,
                                label: l10n.transactionTypeExpense,
                              ),
                              ChipFormFieldOption(
                                value: OrderType.income,
                                label: l10n.transactionTypeIncome,
                              ),
                              ChipFormFieldOption(
                                value: OrderType.transfer,
                                label: l10n.transactionTypeTransfer,
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                notifier.updateOrderType(v);
                              }
                            },
                            validator: v.all([v.notNull()]),
                          ),
                        if (state.type != OrderType.transfer) ...[
                          ChipFormField<InstallmentType>(
                            initialValue: state.installmentType,
                            decoration: InputDecoration(
                              labelText: l10n.transactionTypeLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: InstallmentType.single,
                                label: l10n.transactionTypeSimple,
                              ),
                              ChipFormFieldOption(
                                value: InstallmentType.installment,
                                label: l10n.transactionTypeInstallment,
                              ),
                              ChipFormFieldOption(
                                value: InstallmentType.recurring,
                                label: l10n.transactionTypeRecurrent,
                              ),
                            ],
                            onChanged: state.creation
                                ? (v) {
                                    if (v != null) {
                                      notifier.updateInstallmentType(v);
                                    }
                                  }
                                : null,
                          ),
                        ],
                        if (state.installmentType ==
                            InstallmentType.installment)
                          TextFormField(
                            initialValue: (state.installmentCount ?? 1)
                                .toString(),
                            onChanged: (installment) =>
                                notifier.updateInstallmentCount(
                                  int.tryParse(installment) ?? 1,
                                ),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.transactionInstallmentsLabel,
                            ),
                            validator: v.all([v.notEmpty()]),
                            enabled: state.creation,
                          ),
                        if (state.installmentType ==
                                InstallmentType.installment &&
                            state.creation &&
                            !isSettled)
                          ChipFormField<TransactionAmountType>(
                            initialValue: state.amountType,
                            decoration: InputDecoration(
                              labelText: l10n.transactionAmountLabel,
                            ),
                            options: [
                              ChipFormFieldOption(
                                value: TransactionAmountType.total,
                                label: l10n.transactionAmountTotalLabel,
                              ),
                              ChipFormFieldOption(
                                value: TransactionAmountType.installment,
                                label: l10n.transactionAmountInstallmentLabel,
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                notifier.updateAmountType(v);
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 7. Informações de Pagamento (Se não for Criação e estiver Pago/Liquidado ou sem planejamento)
            if (!state.creation &&
                (isPaid || isSettled || !state.hasAmount)) ...[
              FullWidthItem(const Divider()),
              FullWidthItem(
                Text(l10n.paymentInfo, style: theme.textTheme.titleMedium),
              ),
              DateFormField(
                initialValue: state.paidDate,
                onChanged: (date) {
                  if (date != null) {
                    notifier.updatePaidDate(date);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.transactionDateLabel,
                ),
                validator: v.all([v.notNull()]),
                enabled: !isSettled,
              ),
              MoneyFormField(
                initialValue: state.paidAmount,
                decoration: InputDecoration(
                  labelText: l10n.transactionAmountLabel,
                ),
                onChanged: (v) => notifier.updatePaidAmount(v ?? 0.0),
                validator: v.all([v.notNull()]),
                enabled: !isSettled,
              ),
            ],
          ];
        },
      ),
    );
  }

  /// Oferta de casamento com um agendamento já existente.
  ///
  /// Aparece antes dos campos porque a pergunta muda o que o save vai fazer:
  /// quitar a parcela agendada ou criar um lançamento novo. Sem a pergunta, o
  /// usuário criava o lançamento novo sem perceber e o agendamento ficava
  /// pendente para sempre — planejado em dobro no 50-30-20, missão atrasada
  /// que nunca fecha e saldo projetado errado.
  /// Altura reservada para a oferta de agendamentos, em pixels lógicos.
  ///
  /// É a altura do conteúdo da oferta com um agendamento: título em duas
  /// linhas mais uma linha de agendamento. O banner ocupa esse espaço já
  /// durante a busca para que os campos nasçam na posição final — a oferta
  /// chegando depois empurraria o campo de valor para baixo bem quando o dedo
  /// do usuário está descendo nele, e o toque que era do valor viraria toque
  /// no agendamento.
  ///
  /// O número é medido, não deduzido, e o teste "o espaço da oferta é
  /// reservado enquanto a busca corre" o mantém honesto: se o banner mudar de
  /// tamanho, é ele que quebra. A reserva é exata no caso comum — um
  /// agendamento, tamanho de texto padrão; com dois ou mais o banner ainda
  /// cresce, e aí o usuário já está lendo uma lista, não digitando.
  static const double _reservedMatchesHeight = 100;

  /// Espaço reservado enquanto a busca por agendamentos corre.
  ///
  /// O indicador é discreto de propósito: explica o vão no topo sem competir
  /// com o formulário, que já está utilizável. Quem já sabe que o lançamento
  /// é novo pode recusar a oferta antes mesmo dela chegar.
  MaterialBanner _searchingMatchesBanner(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return MaterialBanner(
      backgroundColor: theme.colorScheme.secondaryContainer,
      content: SizedBox(
        height: _reservedMatchesHeight,
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            Expanded(
              child: Text(
                l10n.transactionMatchSearching,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: notifier.dismissMatches,
          child: Text(
            state.type == OrderType.income
                ? l10n.transactionMatchDismissIncome
                : l10n.transactionMatchDismiss,
          ),
        ),
      ],
    );
  }

  MaterialBanner _pendingMatchesBanner(
    BuildContext context,
    TransactionFormState state,
    TransactionFormNotifier notifier,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;
    final likelyId = state.likelyMatchId;

    return MaterialBanner(
      backgroundColor: theme.colorScheme.secondaryContainer,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.transactionMatchTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...state.pendingMatches.map((match) {
            final likely = match.id == likelyId;

            return InkWell(
              key: ValueKey('pending-match-${match.id}'),
              onTap: () => notifier.selectMatch(match),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                // O destaque é do valor que bate com o digitado. A cor
                // sozinha não serve a quem não a distingue, então o rótulo
                // "mesmo valor" diz em texto por que esta linha é diferente.
                decoration: likely
                    ? BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  spacing: 8,
                  children: [
                    const Icon(Icons.event_available_outlined, size: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${match.amount.asCurrency(locale: locale)} · '
                            '${match.dueDate.formated(l10n.formatSimpleDate)}'
                            '${likely ? ' · ${l10n.transactionMatchSameAmount}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: likely
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      l10n.transactionMatchSettle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: notifier.dismissMatches,
          child: Text(
            state.type == OrderType.income
                ? l10n.transactionMatchDismissIncome
                : l10n.transactionMatchDismiss,
          ),
        ),
      ],
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

  void _confirmDelete(
    BuildContext context,
    AutoDisposeStateNotifierProvider<
      TransactionFormNotifier,
      TransactionFormState
    >
    provider,
  ) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.historyDeleteTitle),
        content: Text(l10n.historyDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(provider.notifier);
              final state = ref.watch(provider.select((s) => s));

              return LoadingButton.text(
                onPressed: (loading) async {
                  final navigator = Navigator.of(context);
                  ReplicationCascade cascade = ReplicationCascade.none;

                  if (state.installmentType != InstallmentType.single) {
                    final selectedCascade =
                        await ReplicationCascadeDialog.showDeletion(context);

                    if (selectedCascade == null) return;
                    cascade = selectedCascade;
                  }

                  notifier.updateReplicationCascade(cascade);
                  await loading(notifier.delete());

                  navigator.pop(); // Fecha dialog de confirmação
                  if (context.mounted) {
                    Navigator.of(context).pop(true); // Fecha tela de form
                  }
                },
                child: Text(
                  l10n.deleteButton,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
