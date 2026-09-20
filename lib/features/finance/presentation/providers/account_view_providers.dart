// ─────────────────────────────────────────────────────────────────────────────
// Providers de CONTA para as telas.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import 'package:funances/core/analytics/analytics_providers.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/presentation/controllers/account_form_notifier.dart';
import 'package:funances/features/finance/presentation/model/account_view_models.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';

class AccountViewProviders {
  static final latestBalanceById = StreamProvider.autoDispose
      .family<AccountBalanceModel, String>((ref, accountId) {
        return ref
            .watch(AccountDomainProviders.service)
            .getLatestAccountBalance(accountId);
      });

  static final all = StreamProvider(
    (ref) => ref.watch(AccountDomainProviders.service).getAccounts(),
  );

  static final byId = StreamProvider.autoDispose.family<AccountModel?, String>((
    ref,
    accountId,
  ) {
    final accounts = ref.watch(all);

    return accounts.when(
      data: (data) => Stream.value(
        data.where((account) => account.id == accountId).firstOrNull,
      ),
      error: (error, stack) => Stream.error(error, stack),
      loading: () => Stream.empty(),
    );
  });

  static final byTypeMap = StreamProvider(
    (ref) => ref.watch(AccountDomainProviders.service).getAccountsByType(),
  );

  /// As contas indexadas por id, para quem só tem o id na mão.
  ///
  /// É um DERIVADO de [byTypeMap] e não uma leitura nova: a regra do projeto
  /// é que consulta nova custa índice e teste em produção, e quem precisa
  /// disto — as folhas da Arena, que recebem leituras com `accountId` e
  /// precisam da logo do banco e dos donos — não tem por que pagar uma
  /// segunda assinatura do mesmo stream.
  ///
  /// Mapa VAZIO enquanto a lista não chegou (ou se ela falhar): quem usa
  /// desenha o ícone genérico e a tela continua de pé.
  static final byIdMap = Provider<Map<String, AccountModel>>((ref) {
    final porTipo =
        ref.watch(byTypeMap).valueOrNull ??
        const <AccountType, List<AccountModel>>{};

    return {
      for (final contas in porTipo.values)
        for (final conta in contas) conta.id: conta,
    };
  });

  static final form = StateNotifierProvider.autoDispose
      .family<AccountFormNotifier, AccountFormState, AccountFormArgs>((
        ref,
        args,
      ) {
        return AccountFormNotifier(
          accountService: ref.watch(AccountDomainProviders.service),
          financeService: ref.watch(FinanceDomainProviders.service),
          categoryService: ref.watch(CategoryDomainProviders.service),
          analytics: ref.watch(analyticsServiceProvider),
          account: args.account,
          type: args.type,
        );
      });

  /// Soma dos saldos das contas de um tipo.
  ///
  /// Os saldos são combinados num único stream em vez de um `ref.watch` por
  /// conta dentro do `map`: o `watch` em loop registrava uma dependência nova
  /// a cada rebuild e somava 0 para toda conta cujo saldo ainda não tivesse
  /// chegado, mostrando um total errado como se fosse definitivo. Agora o
  /// provider só emite quando todas as contas já responderam — enquanto isso
  /// fica em `AsyncLoading`, e a tela deve mostrar carregamento em vez de
  /// zero.
  static final latestBalanceByType = StreamProvider.autoDispose
      .family<double, AccountType>((ref, type) {
        final List<AccountModel> accounts = ref.watch(
          AccountViewProviders.byTypeMap.select(
            (acc) => acc.value?[type] ?? const <AccountModel>[],
          ),
        );

        if (accounts.isEmpty) {
          return Stream.value(0);
        }

        final service = ref.watch(AccountDomainProviders.service);

        return Rx.combineLatestList(
          accounts.map(
            (account) => service.getLatestAccountBalance(account.id),
          ),
        ).map(
          (balances) =>
              Money.sumOf(balances, (balance) => balance.balance).toDouble(),
        );
      });

  /// Resumo da próxima fatura, LIDO do documento da conta (F1.8).
  ///
  /// O servidor é a única fonte de vencimento, fechamento e janela de ciclo.
  /// `null` significa "ainda não sei" — conta que não é cartão, ou cartão cujo
  /// resumo o servidor ainda não gravou (base anterior ao backfill). A tela
  /// mostra "calculando" nesse caso, e nunca um valor inventado.
  static final nextInvoiceByAccountId = StreamProvider.autoDispose
      .family<NextInvoice?, String>((ref, accountId) {
        final accountAsync = ref.watch(AccountViewProviders.byId(accountId));

        return accountAsync.when(
          data: (account) => Stream.value(
            account is CreditCardAccount ? account.nextInvoice : null,
          ),
          error: (error, stack) => Stream.error(error, stack),
          loading: () => const Stream.empty(),
        );
      });

  static final balanceAtDate = StreamProvider.autoDispose
      .family<AccountBalanceModel, ({String accountId, DateTime date})>((
        ref,
        args,
      ) {
        return ref
            .watch(AccountDomainProviders.service)
            .getAccountBalanceAtDate(args.accountId, args.date);
      });
}
