import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/presentation/providers/account_view_providers.dart';
import 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';
import 'package:funances/features/finance/presentation/providers/period_summary_providers.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// Quantos dias para trás a Arena procura atraso.
///
/// Sem janela, a consulta de pendentes traria o histórico inteiro do
/// workspace só para somar um número. Meio ano é o horizonte em que uma
/// parcela esquecida ainda é uma dívida viva, e não arqueologia.
const int arenaOverdueLookbackDays = 180;

/// `YYYY-Www` → `(ano, semana)`. `null` quando o id não tem esse formato.
({int year, int week})? parseWeekId(String weekId) {
  final match = RegExp(r'^(\d{4})-W(\d{1,2})$').firstMatch(weekId.trim());
  if (match == null) return null;

  return (year: int.parse(match.group(1)!), week: int.parse(match.group(2)!));
}

sealed class ArenaViewProviders {
  /// A janela de datas da semana corrente.
  ///
  /// Sai de [ProductWeek], que é a definição única de semana do cliente: o
  /// domingo 00:00 e o sábado 23:59:59. O *id* da semana continua vindo do
  /// servidor (ver [JourneyViewProviders.currentWeekId]); só o recorte de
  /// datas da CONSULTA é local, porque uma query do Firestore precisa de
  /// `DateTime` e o servidor grava id, não intervalo.
  static final weekWindow =
      Provider.autoDispose<({DateTime start, DateTime end})>((ref) {
        final start = ProductWeek.startOf(ref.watch(todayProvider));
        final end = start
            .addCalendarDays(6)
            .add(const Duration(hours: 23, minutes: 59, seconds: 59));

        return (start: start, end: end);
      });

  /// Parcelas cuja `referenceDate` cai na semana.
  ///
  /// `referenceDate` é `paidDate ?? dueDate` — uma consulta só devolve tanto
  /// o que vence na semana quanto o que foi PAGO nela, que são as duas
  /// metades da conta do monstro.
  static final weekInstallments =
      StreamProvider.autoDispose<List<InstallmentModel>>((ref) {
        final window = ref.watch(weekWindow);

        return ref
            .watch(FinanceDomainProviders.service)
            .watchInstallments(startDate: window.start, endDate: window.end);
      });

  /// O que ficou de trás: pendente, vencido antes do domingo.
  static final overdueInstallments =
      StreamProvider.autoDispose<List<InstallmentModel>>((ref) {
        final window = ref.watch(weekWindow);

        return ref
            .watch(FinanceDomainProviders.service)
            .watchInstallments(
              startDate: window.start.addCalendarDays(
                -arenaOverdueLookbackDays,
              ),
              endDate: window.start.add(const Duration(seconds: -1)),
              status: InstallmentStatus.pending,
            );
      });

  /// `period_summaries/{weekId}`, pelo id que o SERVIDOR diz ser o corrente.
  static final weekSummary = StreamProvider.autoDispose<PeriodSummaryModel?>((
    ref,
  ) {
    final weekId = ref.watch(JourneyViewProviders.currentWeekId);
    final parsed =
        parseWeekId(weekId) ??
        (
          year: ProductWeek.yearOf(ref.watch(todayProvider)),
          week: ProductWeek.numberOf(ref.watch(todayProvider)),
        );

    return ref
        .watch(PeriodSummaryDomainProviders.service)
        .watchWeek(parsed.year, parsed.week);
  });

  /// Caixa: corrente + investimento.
  ///
  /// Cartão e dívida ficam de fora — o que está no cartão ainda não saiu da
  /// conta, e dívida não é caixa. Fica em `AsyncValue` porque um saldo que
  /// ainda não chegou vale ZERO na soma, e zero aqui seria um herói sem vida
  /// nenhuma piscando na tela antes do número certo.
  static final liquidBalance = Provider.autoDispose<AsyncValue<double>>((ref) {
    final checking = ref.watch(
      AccountViewProviders.latestBalanceByType(AccountType.checking),
    );
    final investment = ref.watch(
      AccountViewProviders.latestBalanceByType(AccountType.investment),
    );

    for (final async in [checking, investment]) {
      if (async.hasError) {
        return AsyncValue<double>.error(
          async.error!,
          async.stackTrace ?? StackTrace.current,
        );
      }
    }

    final a = checking.valueOrNull;
    final b = investment.valueOrNull;
    if (a == null || b == null) return const AsyncValue<double>.loading();

    return AsyncValue<double>.data(a + b);
  });

  /// O cartão "principal": o de maior fatura aberta.
  ///
  /// Não existe campo de cartão principal no modelo, e inventar um seria uma
  /// decisão de produto disfarçada de detalhe técnico. O maior é o que o
  /// casulo precisa mostrar de qualquer jeito.
  static final primaryInvoice = Provider.autoDispose<NextInvoice?>((ref) {
    final byType = ref.watch(AccountViewProviders.byTypeMap).valueOrNull;
    final cards = byType?[AccountType.creditCard] ?? const <AccountModel>[];

    final invoices = cards
        .whereType<CreditCardAccount>()
        .map((card) => card.nextInvoice)
        .nonNulls
        .where((invoice) => !invoice.isEmpty)
        .toList();

    if (invoices.isEmpty) return null;

    invoices.sort((a, b) => b.amount.compareTo(a.amount));
    return invoices.first;
  });

  /// A cena inteira.
  ///
  /// `AsyncLoading` enquanto QUALQUER número que a cena mostra ainda não
  /// chegou. Uma Arena que aparece com o monstro em zero e depois pula para
  /// R$ 1.930 não é um carregamento — é uma mentira curta.
  static final state = Provider.autoDispose<AsyncValue<ArenaState>>((ref) {
    final balance = ref.watch(liquidBalance);
    final week = ref.watch(weekInstallments);
    final overdue = ref.watch(overdueInstallments);
    final summary = ref.watch(weekSummary);
    final members = ref.watch(WorkspaceViewProviders.members);
    final xp = ref.watch(JourneyViewProviders.weeklyXp);

    final failure = [
      balance,
      week,
      overdue,
      summary,
      members,
    ].where((async) => async.hasError).firstOrNull;

    if (failure != null) {
      return AsyncValue<ArenaState>.error(
        failure.error!,
        failure.stackTrace ?? StackTrace.current,
      );
    }

    final liquid = balance.valueOrNull;
    final weekData = week.valueOrNull;
    final overdueData = overdue.valueOrNull;
    if (liquid == null || weekData == null || overdueData == null) {
      return const AsyncValue<ArenaState>.loading();
    }

    return AsyncValue<ArenaState>.data(
      ArenaCalculator.from(
        ArenaInputs(
          weekId: ref.watch(JourneyViewProviders.currentWeekId),
          liquidBalance: liquid,
          weekInstallments: weekData,
          overdueInstallments: overdueData,
          // O resumo e o XP são do servidor e podem ainda não existir; a cena
          // fica de pé sem eles (monstro só de parcelas, zero moeda).
          weekSummary: summary.valueOrNull,
          weeklyXp: xp.valueOrNull ?? 0,
          members: members.valueOrNull ?? const <UserModel>[],
          invoice: ref.watch(primaryInvoice),
        ),
      ),
    );
  });
}
