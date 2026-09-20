import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/services/arena_calculator.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/presentation/providers/account_view_providers.dart';
import 'package:funances/features/finance/presentation/providers/finance_domain_providers.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

/// Quantos dias para trás a Arena procura atraso.
///
/// Sem janela, a consulta de pendentes traria o histórico inteiro do
/// workspace só para somar um número. Meio ano é o horizonte em que uma
/// parcela esquecida ainda é uma dívida viva, e não arqueologia.
const int arenaOverdueLookbackDays = 180;

/// As contas que contam como CAIXA: corrente e investimento.
///
/// Cartão e dívida ficam de fora — o que está no cartão ainda não saiu da
/// conta, e dívida não é caixa.
const List<AccountType> arenaLiquidTypes = <AccountType>[
  AccountType.checking,
  AccountType.investment,
];

/// O evento que a cena ainda não mostrou.
///
/// Vive em memória e **não** é `autoDispose`: quem lança um gasto está no
/// formulário, não na Home, e a cena só existe de novo quando o usuário
/// volta. Um provider que morresse junto com a tela perderia exatamente o
/// evento que ele existe para guardar.
class ArenaPendingEventNotifier extends StateNotifier<ArenaPendingEvent?> {
  ArenaPendingEventNotifier() : super(null);

  void push(ArenaPendingEvent event) => state = event;

  /// Lê e limpa: um evento anima UMA vez.
  ArenaPendingEvent? take() {
    final event = state;
    state = null;
    return event;
  }
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

  /// As contas líquidas, na ordem em que o app as devolve.
  static final liquidAccounts =
      Provider.autoDispose<AsyncValue<List<AccountModel>>>((ref) {
        final byType = ref.watch(AccountViewProviders.byTypeMap);

        return byType.whenData(
          (map) => [
            for (final type in arenaLiquidTypes) ...map[type] ?? const [],
          ],
        );
      });

  /// Saldo de UMA conta no começo da semana e agora.
  ///
  /// O "começo da semana" é o último documento `accounts/{id}/balance/{dia}`
  /// com data ANTERIOR ao domingo — por isso a consulta pede o sábado: o
  /// repositório usa `<=`, e o domingo cru traria o saldo do próprio domingo
  /// (já com os lançamentos do dia) como se fosse o de partida.
  ///
  /// Conta sem documento nenhum antes do domingo — criada durante a semana —
  /// devolve zero, que é a verdade: ela não existia no começo da luta.
  static final accountLife = Provider.autoDispose
      .family<AsyncValue<ArenaAccountReading>, AccountModel>((ref, account) {
        final window = ref.watch(weekWindow);
        final beforeSunday = window.start.addCalendarDays(-1);

        final current = ref.watch(
          AccountViewProviders.latestBalanceById(account.id),
        );
        final initial = ref.watch(
          AccountViewProviders.balanceAtDate((
            accountId: account.id,
            date: beforeSunday,
          )),
        );

        for (final async in [current, initial]) {
          if (async.hasError) {
            return AsyncValue<ArenaAccountReading>.error(
              async.error!,
              async.stackTrace ?? StackTrace.current,
            );
          }
        }

        final now = current.valueOrNull;
        final then = initial.valueOrNull;
        if (now == null || then == null) {
          return const AsyncValue<ArenaAccountReading>.loading();
        }

        return AsyncValue<ArenaAccountReading>.data(
          ArenaAccountReading(
            accountId: account.id,
            name: account.name,
            initial: then.balance,
            current: now.balance,
          ),
        );
      });

  /// As contas líquidas com os dois saldos.
  ///
  /// `AsyncLoading` enquanto QUALQUER conta ainda não respondeu: um saldo que
  /// ainda não chegou vale zero na soma, e zero aqui seria um herói sem vida
  /// nenhuma piscando na tela antes do número certo.
  static final accountLives =
      Provider.autoDispose<AsyncValue<List<ArenaAccountReading>>>((ref) {
        final accounts = ref.watch(liquidAccounts);
        if (accounts.hasError) {
          return AsyncValue<List<ArenaAccountReading>>.error(
            accounts.error!,
            accounts.stackTrace ?? StackTrace.current,
          );
        }

        final list = accounts.valueOrNull;
        if (list == null) {
          return const AsyncValue<List<ArenaAccountReading>>.loading();
        }

        final readings = <ArenaAccountReading>[];
        for (final account in list) {
          final life = ref.watch(accountLife(account));
          if (life.hasError) {
            return AsyncValue<List<ArenaAccountReading>>.error(
              life.error!,
              life.stackTrace ?? StackTrace.current,
            );
          }
          final value = life.valueOrNull;
          if (value == null) {
            return const AsyncValue<List<ArenaAccountReading>>.loading();
          }
          readings.add(value);
        }

        return AsyncValue<List<ArenaAccountReading>>.data(readings);
      });

  /// O evento pendente de animação.
  static final pendingEvent =
      StateNotifierProvider<ArenaPendingEventNotifier, ArenaPendingEvent?>(
        (ref) => ArenaPendingEventNotifier(),
      );

  /// `true` quando o cofre corrente é empresa: troca "categorias" por
  /// "centros de custo" e "compromissos" por "contas a pagar".
  static final isBusiness = Provider<bool>(
    (ref) => ref.watch(
      WorkspaceViewProviders.workspace.select(
        (state) => state.currentWorkspace?.type == WorkspaceType.business,
      ),
    ),
  );

  /// A cena inteira.
  static final state = Provider.autoDispose<AsyncValue<ArenaState>>((ref) {
    final lives = ref.watch(accountLives);
    final week = ref.watch(weekInstallments);
    final overdue = ref.watch(overdueInstallments);
    final members = ref.watch(WorkspaceViewProviders.members);
    final xp = ref.watch(JourneyViewProviders.weeklyXp);

    final failure = [
      lives,
      week,
      overdue,
      members,
    ].where((async) => async.hasError).firstOrNull;

    if (failure != null) {
      return AsyncValue<ArenaState>.error(
        failure.error!,
        failure.stackTrace ?? StackTrace.current,
      );
    }

    final accounts = lives.valueOrNull;
    final weekData = week.valueOrNull;
    final overdueData = overdue.valueOrNull;
    if (accounts == null || weekData == null || overdueData == null) {
      return const AsyncValue<ArenaState>.loading();
    }

    return AsyncValue<ArenaState>.data(
      ArenaCalculator.from(
        ArenaInputs(
          weekId: ref.watch(JourneyViewProviders.currentWeekId),
          today: ref.watch(todayProvider),
          accounts: accounts,
          weekInstallments: weekData,
          overdueInstallments: overdueData,
          // O XP é do servidor e pode ainda não existir; a cena fica de pé
          // sem ele (zero moeda).
          weeklyXp: xp.valueOrNull ?? 0,
          members: members.valueOrNull ?? const <UserModel>[],
        ),
      ),
    );
  });
}
