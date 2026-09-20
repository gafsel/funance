/// A DEFINIÇÃO ÚNICA DE SEMANA no cliente.
///
/// O app tinha DUAS aritméticas de semana, e elas não davam o mesmo
/// resultado:
///
/// - `JourneyService.weekIdFor`, que subtraía os dias em calendário e media o
///   dia do ano em UTC — correta na virada do horário de verão;
/// - `MissionService._getWeekNumber`/`_getWeekYear`, que faziam as duas
///   contas com `Duration(days:)` e `difference().inDays`, ou seja, em
///   blocos de 24 horas. Num domingo que tem 23 ou 25 horas, isso escorrega
///   um dia e muda o NÚMERO da semana — e a semana errada é o checklist e o
///   XP do período errado.
///
/// A fórmula aqui é a do servidor
/// (`functions/src/core/utils/week.utils.ts`): a semana começa no **domingo**,
/// o ano é o do domingo que a inicia e o número é
/// `floor(dia_do_ano_do_domingo / 7) + 1`. Não é a semana ISO — é a convenção
/// que já está gravada em `weekly_missions`, `weekly_xp` e
/// `period_summaries`, e mudá-la invalidaria os ids existentes.
///
/// **Quem manda continua sendo o servidor.** Ele grava `currentWeekId` e
/// `currentWeekStart` no documento do workspace (`week_sync.service.ts`), no
/// fuso do produto (America/Sao_Paulo); isto aqui é o fallback para quando o
/// campo ainda não existe. E é por isso que estas funções trabalham sobre o
/// CALENDÁRIO LOCAL, não sobre um instante UTC: a conversão de fuso é do
/// servidor, que tem a base de fusos; o cliente só sabe fazer a aritmética de
/// calendário, e é essa parte que
/// `functions/src/test/fixtures/week_vectors.json` verifica.
library;

import 'package:funances/core/utils/date_extension.dart';

abstract final class ProductWeek {
  /// O domingo 00:00 que inicia a semana de [reference].
  ///
  /// A soma é de dias de CALENDÁRIO (`addCalendarDays`), e não de 24 horas:
  /// no domingo da virada do horário de verão as duas respostas diferem.
  static DateTime startOf(DateTime reference) => DateTime(
    reference.year,
    reference.month,
    reference.day,
  ).addCalendarDays(-(reference.weekday % 7));

  /// Número da semana (1-based).
  static int numberOf(DateTime reference) {
    final start = startOf(reference);

    // A diferença é medida em UTC de propósito: `difference().inDays` em
    // horário local perde (ou ganha) uma hora na semana da virada do horário
    // de verão e pode mudar o número da semana.
    final dayOfYear = DateTime.utc(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime.utc(start.year, 1, 1)).inDays;

    return (dayOfYear / 7).floor() + 1;
  }

  /// Ano da semana: o do domingo que a inicia — o que importa na virada de
  /// ano, quando 1º de janeiro cai no meio de uma semana que começou em
  /// dezembro.
  static int yearOf(DateTime reference) => startOf(reference).year;

  /// Id `YYYY-Www`.
  static String idOf(DateTime reference) =>
      '${yearOf(reference)}-W${numberOf(reference).toString().padLeft(2, '0')}';
}
