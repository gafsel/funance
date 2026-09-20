import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/core/utils/enum_messages.dart';
import 'package:funances/core/utils/string_util.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/core/widgets/money_text.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/presentation/retry.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/utils/error_messages.dart';

class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAccountsAsync = ref.watch(AccountViewProviders.byTypeMap);

    return groupedAccountsAsync.when(
      data: (groupedAccounts) {
        final types = AccountType.values
            .where((t) => groupedAccounts.containsKey(t))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...types.map(
              (type) => _buildExpandableType(
                context,
                ref,
                type,
                groupedAccounts[type] ?? [],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: AppSpacing.allMd,
        child: ErrorView.forError(
          context,
          e,
          onRetry: () => Retry.accounts(ref),
        ),
      ),
    );
  }

  Widget _buildExpandableType(
    BuildContext context,
    WidgetRef ref,
    AccountType type,
    List<AccountModel> accounts,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = context.locale;

    var total = Money.zero;
    Object? totalError;
    // Só o total somado de saldos pode estar carregando: os saldos chegam por
    // stream e mostrar R$ 0,00 enquanto isso é um número errado com cara de
    // definitivo.
    bool isTotalLoading = false;
    final Map<String, Money> totalsByMonth = {};

    if (type == AccountType.creditCard) {
      for (final account in accounts) {
        // F1.8: valor e vencimento vêm de `account.nextInvoice`, escrito pelo
        // servidor. Enquanto o resumo de ALGUM cartão não chegou, o total do
        // grupo está incompleto — e um total incompleto com cara de definitivo
        // é pior do que um indicador de carregamento.
        final nextInvoice = ref
            .watch(AccountViewProviders.nextInvoiceByAccountId(account.id))
            .value;

        if (nextInvoice == null) {
          isTotalLoading = true;
          continue;
        }

        final invoiceAmount = nextInvoice.amount.asMoney;
        total += invoiceAmount;
        final monthKey = nextInvoice.dueDate.formated('MMMM', locale);
        totalsByMonth[monthKey] =
            (totalsByMonth[monthKey] ?? Money.zero) + invoiceAmount;
      }
    } else {
      final totalAsync = ref.watch(
        AccountViewProviders.latestBalanceByType(type),
      );
      // R$ 0,00 no lugar de um saldo que não pôde ser lido é a mentira mais
      // cara que esta tela sabe contar.
      if (totalAsync.hasError) {
        totalError = totalAsync.error;
      }
      total = (totalAsync.valueOrNull ?? 0).asMoney;
      isTotalLoading = totalAsync.isLoading && !totalAsync.hasValue;
    }

    final List<String> sortedMonthKeys = totalsByMonth.keys.toList()
      ..sort((a, b) {
        final dateA = DateFormat('MMMM', locale).parse(a);
        final dateB = DateFormat('MMMM', locale).parse(b);
        return dateA.compareTo(dateB);
      });

    final showMonthlyTotal =
        type == AccountType.creditCard && totalsByMonth.length > 1;

    return Theme(
      data: theme.copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.fromAccountType(type),
          style: theme.textTheme.bodyMedium,
        ),
        trailing: totalError != null
            // Sem o saldo, a linha diz que não sabe — e oferece tentar de
            // novo — em vez de escrever R$ 0,00 com cara de saldo.
            // O texto completo do erro fica no tooltip: a linha do grupo não
            // comporta a frase inteira, mas também não pode virar só um ícone
            // sem nome — nem R$ 0,00, que era o que havia aqui.
            ? Tooltip(
                message: errorMessageFor(context, totalError),
                child: TextButton.icon(
                  icon: Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(l10n.retry),
                  onPressed: () => Retry.accounts(ref),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              )
            : showMonthlyTotal
            ? Text(
                sortedMonthKeys
                    .map(
                      (month) =>
                          '${month.capitalize()}: ${totalsByMonth[month]!.format(locale: locale)}',
                    )
                    .join(" | "),
                style: theme.textTheme.titleSmall,
              )
            : isTotalLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                total.format(locale: locale),
                style: theme.textTheme.titleSmall,
              ),
        children: accounts
            .map((account) => _buildAccountItem(context, ref, account))
            .toList(),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref,
    AccountModel account,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final balanceAsync = ref.watch(
      AccountViewProviders.latestBalanceById(account.id),
    );

    return balanceAsync.when(
      data: (balance) {
        final color = Color(int.parse(account.color.replaceAll('#', '0xFF')));

        if (account.type == AccountType.creditCard) {
          final creditCard = account as CreditCardAccount;
          final nextInvoiceAsync = ref.watch(
            AccountViewProviders.nextInvoiceByAccountId(account.id),
          );
          // O id da parcela vem do próprio resumo que o servidor grava na
          // conta (`nextInvoice.installmentId`). Antes havia uma segunda
          // consulta só para descobrir a parcela, porque a rota recebia o
          // modelo inteiro; agora a rota recebe o id, e o id já estava aqui.
          final invoiceInstallmentId =
              nextInvoiceAsync.valueOrNull?.installmentId;
          final usedLimit = -balance.balance;
          final availableLimit = (creditCard.limit - usedLimit).clamp(
            0.0,
            creditCard.limit,
          );
          final progress = creditCard.limit > 0
              ? (usedLimit / creditCard.limit).clamp(0.0, 1.0)
              : 0.0;

          return ListTile(
            onTap: () {
              if (invoiceInstallmentId != null) {
                context.push('/invoices/$invoiceInstallmentId');
              } else {
                context.push('/workspace/accounts?type=${account.type.name}');
              }
            },
            contentPadding: AppSpacing.hMd,
            leading: AccountLogo(account: account, size: 32, showMembers: true),
            title: Text(
              account.displayName(l10n),
              style: theme.textTheme.bodySmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpacing.gapXxs,
                AppProgressBar(
                  value: progress,
                  size: AppProgressSize.thin,
                  color: color,
                ),
                AppSpacing.gapXxs,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MoneyText(
                      usedLimit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink3,
                      ),
                    ),
                    MoneyText(
                      availableLimit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: nextInvoiceAsync.when(
              // `nextInvoice` nulo = o servidor ainda não publicou o resumo
              // desta conta (base anterior ao backfill). Mostrar "calculando" é
              // honesto; R$ 0,00 seria um valor errado com cara de definitivo.
              data: (nextInvoice) => nextInvoice == null
                  ? Text(
                      l10n.invoiceCalculating,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.ink3,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MoneyText(
                          nextInvoice.amount,
                          style: theme.textTheme.labelMedium,
                        ),
                        Text(
                          nextInvoice.dueDate.formated(l10n.formatSimpleDate),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          );
        }

        return ListTile(
          onTap: () {
            if (account.type == AccountType.creditCard) {
              context.push('/workspace/accounts?type=${account.type.name}');
            } else {
              context.push('/accounts/${account.id}/statement');
            }
          },
          contentPadding: AppSpacing.hMd,
          leading: AccountLogo(account: account, size: 32, showMembers: true),
          title: Text(
            account.displayName(context.l10n),
            style: theme.textTheme.bodySmall,
          ),
          trailing: MoneyText(
            balance.balance,
            style: theme.textTheme.bodySmall,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
