// ─────────────────────────────────────────────────────────────────────────────
// Providers do HUD MENSAL — o rodapé da Arena.
//
// O embate é semanal; estes quatro números são do MÊS. Nada aqui inventa
// consulta: saldo por conta, `nextInvoice` e o sumário mensal já são lidos
// por outras telas. O que é novo são os dois documentos do servidor
// (`expectedIncome` e `monthly_reports`), que ninguém lia ainda.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/money/money.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/arena/data/repositories/hud_repository_impl.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/repositories/hud_repository.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers/account_view_providers.dart';
import 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';
import 'package:funances/features/finance/presentation/providers/period_summary_providers.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// Até quantos dias à frente o veneno procura a PRÓXIMA parcela da dívida.
///
/// Sessenta dias cobre a parcela deste mês e a do mês que vem, que é o que a
/// linha precisa dizer ("próximo vencimento"). Sem janela, a consulta traria
/// o cronograma inteiro de um financiamento de trinta anos para mostrar uma
/// data.
const int hudDebtLookaheadDays = 60;

/// Quantos meses fechados a folha da vila mostra.
const int hudHistoryMonths = 6;

sealed class HudDomainProviders {
  static final repository = Provider<IHudRepository>(
    (ref) => HudRepositoryImpl(),
  );
}

sealed class HudViewProviders {
  /// `YYYY-MM` do mês corrente, pelo relógio do app.
  static final monthKey = Provider<String>(
    (ref) => ref.watch(todayProvider).monthKey,
  );

  /// A receita prevista do mês, publicada pelo servidor.
  ///
  /// O app **lê** e nunca recalcula — duas implementações da mesma regra
  /// divergem, e já divergiram duas vezes neste produto. `null` é "ainda não
  /// sei".
  static final expectedIncome = StreamProvider.autoDispose<ExpectedIncome?>((
    ref,
  ) {
    final workspaceId = ref.watch(WorkspaceViewProviders.currentWorkspaceId);
    if (workspaceId == null) return Stream.value(null);

    return ref
        .watch(HudDomainProviders.repository)
        .watchExpectedIncome(workspaceId);
  });

  /// Os meses já fechados.
  static final monthlyReports =
      StreamProvider.autoDispose<List<HudMonthlyReport>>((ref) {
        final workspaceId = ref.watch(
          WorkspaceViewProviders.currentWorkspaceId,
        );
        if (workspaceId == null) {
          return Stream.value(const <HudMonthlyReport>[]);
        }

        return ref
            .watch(HudDomainProviders.repository)
            .watchMonthlyReports(workspaceId, limit: hudHistoryMonths);
      });

  /// As contas de um tipo, com o saldo de HOJE.
  ///
  /// O teto de data é o de `getLatestAccountBalance`, que pergunta pelo
  /// último documento **até hoje**. Ele não é preciosismo: os cartões deste
  /// cofre têm documento de saldo projetado até 2036, e "o último documento"
  /// traria o saldo de daqui a dez anos como se fosse o de agora.
  ///
  /// `AsyncLoading` enquanto QUALQUER conta ainda não respondeu — um saldo
  /// que ainda não chegou vale zero na soma, e zero aqui seria uma poção
  /// vazia piscando antes do número certo.
  static final balancesByType = Provider.autoDispose
      .family<AsyncValue<List<HudBalanceReading>>, AccountType>((ref, type) {
        final byType = ref.watch(AccountViewProviders.byTypeMap);
        if (byType.hasError) {
          return AsyncValue<List<HudBalanceReading>>.error(
            byType.error!,
            byType.stackTrace ?? StackTrace.current,
          );
        }

        final accounts = byType.valueOrNull?[type];
        if (accounts == null) {
          return const AsyncValue<List<HudBalanceReading>>.loading();
        }

        final readings = <HudBalanceReading>[];
        for (final account in accounts) {
          final balance = ref.watch(
            AccountViewProviders.latestBalanceById(account.id),
          );
          if (balance.hasError) {
            return AsyncValue<List<HudBalanceReading>>.error(
              balance.error!,
              balance.stackTrace ?? StackTrace.current,
            );
          }
          final value = balance.valueOrNull;
          if (value == null) {
            return const AsyncValue<List<HudBalanceReading>>.loading();
          }

          readings.add(
            HudBalanceReading(
              accountId: account.id,
              name: account.name,
              balance: value.balance,
              color: account.color,
            ),
          );
        }

        return AsyncValue<List<HudBalanceReading>>.data(readings);
      });

  /// As faturas por vir, lidas de `accounts.nextInvoice`.
  ///
  /// Cartão cujo servidor ainda não gravou o resumo fica de fora: ele é
  /// "ainda não sei", e somar zero por ele encolheria os incubados com uma
  /// certeza
  /// que não existe.
  ///
  /// O SALDO de cada cartão entra junto, e não é consulta nova: é o mesmo
  /// `latestBalanceById` que a poção e o veneno já leem, e é dele que sai o
  /// limite comprometido (`-saldo`) que a Visão Geral desenha na barra de
  /// uso. O dono pediu essa progressão na folha dos incubados, e pediu que
  /// fosse a MESMA visão — então é o mesmo dado e o mesmo componente.
  static final invoices = Provider.autoDispose
      .family<AsyncValue<List<HudInvoiceReading>>, DateTime>((ref, today) {
        final byType = ref.watch(AccountViewProviders.byTypeMap);
        if (byType.hasError) {
          return AsyncValue<List<HudInvoiceReading>>.error(
            byType.error!,
            byType.stackTrace ?? StackTrace.current,
          );
        }

        final cards = byType.valueOrNull?[AccountType.creditCard];
        if (cards == null) {
          return const AsyncValue<List<HudInvoiceReading>>.loading();
        }

        final readings = <HudInvoiceReading>[];
        for (final card in cards) {
          if (card is! CreditCardAccount || card.nextInvoice == null) continue;

          // O saldo só é pedido para cartão que TEM fatura publicada: os
          // outros já estavam fora da soma dos incubados, e ler o saldo seria
          // segurar a faixa inteira por um dado que ninguém vai mostrar.
          final balance = ref.watch(
            AccountViewProviders.latestBalanceById(card.id),
          );
          if (balance.hasError) {
            return AsyncValue<List<HudInvoiceReading>>.error(
              balance.error!,
              balance.stackTrace ?? StackTrace.current,
            );
          }
          final value = balance.valueOrNull;
          if (value == null) {
            return const AsyncValue<List<HudInvoiceReading>>.loading();
          }

          readings.add(
            HudInvoiceReading(
              accountId: card.id,
              name: card.name,
              amount: card.nextInvoice!.amount,
              closingDate: card.nextInvoice!.closingDate,
              dueDate: card.nextInvoice!.dueDate,
              // O ciclo está aberto enquanto o fechamento não passou: até
              // lá o valor é o acumulado e ainda sobe. Depois dele é
              // cobrança fechada.
              isOpenCycle: card.nextInvoice!.closingDate.isAfter(today),
              color: card.color,
              installmentId: card.nextInvoice!.installmentId,
              overdueDays: _overdueDays(card.nextInvoice!.dueDate, today),
              limit: card.limit,
              usedLimit: -value.balance,
            ),
          );
        }

        return AsyncValue<List<HudInvoiceReading>>.data(readings);
      });

  /// Há quantos dias a fatura venceu — zero enquanto o vencimento não passou.
  ///
  /// A conta é em DIAS DE CALENDÁRIO, pelas datas sem hora: a fatura que
  /// vence hoje não está vencida (o usuário tem o dia inteiro), e a que
  /// venceu ontem está vencida há um dia, seja qual for a hora em que o app
  /// abriu.
  static int _overdueDays(DateTime dueDate, DateTime today) {
    // Em UTC de propósito: `DateTime` local, no dia em que o horário de verão
    // vira, dá 23 h entre duas meia-noites e `inDays` devolveria zero para um
    // dia inteiro de atraso.
    final due = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);
    final now = DateTime.utc(today.year, today.month, today.day);
    if (!due.isBefore(now)) return 0;

    return now.difference(due).inDays;
  }

  /// A próxima parcela pendente de cada conta de dívida.
  ///
  /// A leitura é pelo lado de CRÉDITO do lançamento — é assim que o app
  /// registra a parcela do empréstimo: uma transferência da corrente para a
  /// dívida. Olhar `accountIdTarget` não serviria, porque aquele getter só
  /// responde para transferências e a fatura em aberto nasce sem origem.
  static final debtInstallments =
      Provider.autoDispose<
        AsyncValue<Map<String, ({Money amount, DateTime dueDate})>>
      >((ref) {
        final today = ref.watch(todayProvider);
        final types = ref.watch(AccountViewProviders.byTypeMap);
        final pending = ref.watch(_pendingAhead);

        if (types.hasError || pending.hasError) {
          final failure = types.hasError ? types : pending;
          return AsyncValue.error(
            failure.error!,
            failure.stackTrace ?? StackTrace.current,
          );
        }

        final debtAccounts = types.valueOrNull?[AccountType.debt];
        final installments = pending.valueOrNull;
        if (debtAccounts == null || installments == null) {
          return const AsyncValue.loading();
        }

        final ids = debtAccounts.map((a) => a.id).toSet();
        final next = <String, ({Money amount, DateTime dueDate})>{};

        for (final installment in installments) {
          if (installment.type == OrderType.income) continue;

          final credit = installment.accounts.entries
              .where((entry) => entry.value == AccountImpact.credit)
              .map((entry) => entry.key)
              .firstOrNull;
          if (credit == null || !ids.contains(credit)) continue;
          if (installment.dueDate.isBefore(today)) continue;

          final current = next[credit];
          if (current != null &&
              !installment.dueDate.isBefore(current.dueDate)) {
            continue;
          }

          next[credit] = (
            amount: Money.fromDouble(installment.referenceAmount),
            dueDate: installment.dueDate,
          );
        }

        return AsyncValue.data(next);
      });

  /// Parcelas pendentes de hoje até [hudDebtLookaheadDays] dias à frente.
  static final _pendingAhead =
      StreamProvider.autoDispose<List<InstallmentModel>>((ref) {
        final today = ref.watch(todayProvider);

        return ref
            .watch(FinanceDomainProviders.service)
            .watchInstallments(
              startDate: DateTime(today.year, today.month, today.day),
              endDate: today.addCalendarDays(hudDebtLookaheadDays),
              status: InstallmentStatus.pending,
            );
      });

  /// As categorias do mês, já cruzadas com o documento de cada uma.
  ///
  /// Reaproveita `PeriodSummaryViewProviders.monthSummary`, que é a mesma
  /// leitura da Visão Geral — inclusive a peneira que descarta id de
  /// categoria que o app não conhece.
  static final categories = Provider.autoDispose
      .family<AsyncValue<List<HudCategoryReading>>, String>((ref, monthKey) {
        return ref
            .watch(PeriodSummaryViewProviders.monthSummary(monthKey))
            .whenData(
              (summaries) => <HudCategoryReading>[
                for (final s in summaries)
                  if (!s.category.isDeleted)
                    HudCategoryReading(
                      categoryId: s.category.id,
                      name: s.category.name,
                      icon: s.category.icon,
                      color: s.category.color,
                      isExpense: s.category.type == CategoryType.expense,
                      isSystem: s.category.isSystem,
                      // O ORÇAMENTO é o `generalPlannedAmount`, e só ele. O
                      // `specificPlannedAmount` são as parcelas agendadas do
                      // mês — dinheiro que já tem dono, não o limite da
                      // categoria. Confundir os dois foi o defeito que, em
                      // produção, fez uma missão de margem concluir de graça.
                      planned: s.generalPlannedAmount,
                      actual: s.actualAmount,
                      // A allocation que o 50/30/20 já usa. É ela que
                      // inverte a leitura do aldeão: em categoria de
                      // investimento o planejado é META, e não teto.
                      isInvestment:
                          s.category.allocation ==
                          CategoryAllocation.investment,
                    ),
              ],
            );
      });

  /// O rodapé inteiro.
  ///
  /// `AsyncLoading` enquanto qualquer parte falta, `AsyncError` na primeira
  /// falha. A única ausência que NÃO é carregamento é a da receita prevista:
  /// ela tem estado próprio na tela (o ícone neutro), porque o servidor pode
  /// legitimamente ainda não saber.
  static final state = Provider.autoDispose<AsyncValue<HudState>>((ref) {
    final monthKey = ref.watch(HudViewProviders.monthKey);
    final today = ref.watch(todayProvider);

    final income = ref.watch(expectedIncome);
    final reports = ref.watch(monthlyReports);
    final investments = ref.watch(balancesByType(AccountType.investment));
    final debts = ref.watch(balancesByType(AccountType.debt));
    final cards = ref.watch(invoices(today));
    final cats = ref.watch(categories(monthKey));
    final parcels = ref.watch(debtInstallments);

    final failure = <AsyncValue<Object?>>[
      income,
      reports,
      investments,
      debts,
      cards,
      cats,
      parcels,
    ].where((async) => async.hasError).firstOrNull;

    if (failure != null) {
      return AsyncValue<HudState>.error(
        failure.error!,
        failure.stackTrace ?? StackTrace.current,
      );
    }

    final investmentData = investments.valueOrNull;
    final debtData = debts.valueOrNull;
    final cardData = cards.valueOrNull;
    final categoryData = cats.valueOrNull;
    final parcelData = parcels.valueOrNull;
    final reportData = reports.valueOrNull;

    if (investmentData == null ||
        debtData == null ||
        cardData == null ||
        categoryData == null ||
        parcelData == null ||
        reportData == null ||
        income.isLoading) {
      return const AsyncValue<HudState>.loading();
    }

    return AsyncValue<HudState>.data(
      HudCalculator.from(
        HudInputs(
          monthKey: monthKey,
          income: income.valueOrNull,
          investments: investmentData,
          debts: debtData,
          invoices: cardData,
          categories: categoryData,
          history: reportData,
          debtInstallments: parcelData,
        ),
      ),
    );
  });
}
