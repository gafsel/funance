import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Qual foi a última semana cujo fechamento o usuário já viu.
///
/// O placar da semana passada aparece UMA vez por semana. Sem memória, ele
/// voltaria a cada abertura do app durante sete dias — e um aviso que se
/// repete deixa de ser aviso no terceiro dia.
///
/// A memória é do APARELHO, como a do tema e a do nudge de gasto não
/// planejado: é sobre o que esta pessoa já olhou, não sobre o cofre.
///
/// A leitura do disco é assíncrona e o app não pode esperar por ela para
/// desenhar o primeiro quadro.
///
/// Por isso o "já leu o disco?" é parte do ESTADO, e não um campo do
/// notifier. Como campo ele não reconstruía nada: numa instalação nova o
/// valor guardado é `null`, a leitura terminava sem mudar o estado, e quem
/// observava continuava vendo "ainda não sei" para sempre — o placar nunca
/// aparecia. Um `bool` no estado é o que faz a chegada da resposta ser um
/// evento.
typedef ArenaWeekClosingState = ({bool ready, String? seen});

class ArenaWeekClosingNotifier extends StateNotifier<ArenaWeekClosingState> {
  ArenaWeekClosingNotifier({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance(),
      super((ready: false, seen: null)) {
    _restore();
  }

  static const String storageKey = 'arena_week_closing_seen';

  final Future<SharedPreferences> _prefs;

  Future<void> _restore() async {
    String? stored;

    try {
      stored = (await _prefs).getString(storageKey);
    } on Exception {
      // Preferência ilegível não é motivo para o app não abrir: no pior caso
      // o placar aparece uma vez a mais.
      stored = null;
    }

    if (!mounted) return;
    state = (ready: true, seen: stored);
  }

  Future<void> markSeen(String weekId) async {
    if (state.seen == weekId) return;
    state = (ready: true, seen: weekId);

    try {
      await (await _prefs).setString(storageKey, weekId);
    } on Exception {
      // Gravação falhou: o placar volta na próxima abertura. É melhor do que
      // estourar no meio da Home.
    }
  }
}

sealed class ArenaWeekClosingProviders {
  static final seen =
      StateNotifierProvider<ArenaWeekClosingNotifier, ArenaWeekClosingState>(
        (ref) => ArenaWeekClosingNotifier(),
      );

  /// O id da semana que acabou de fechar.
  ///
  /// `addCalendarDays(-1)` e não `subtract(Duration(days: 1))`: no domingo em
  /// que o horário de verão entra, o dia tem 23 horas, e vinte e quatro horas
  /// antes da meia-noite de domingo ainda é domingo. O id sairia o da semana
  /// que está começando, e o placar mostraria a luta que ainda não aconteceu
  /// — exatamente no dia em que ele aparece.
  static final lastWeekId = Provider.autoDispose<String>((ref) {
    return ProductWeek.idOf(
      ProductWeek.startOf(ref.watch(todayProvider)).addCalendarDays(-1),
    );
  });

  /// Mostrar o placar agora?
  ///
  /// Duas condições, e as duas importam:
  ///
  /// - a leitura do disco já respondeu (senão o placar piscaria para quem já
  ///   o dispensou);
  /// - o fechamento desta semana ainda não foi visto.
  ///
  /// Repare que NÃO há condição de "é domingo". O usuário que só abre o app
  /// na quarta continua merecendo saber como a semana dele fechou — amarrar o
  /// placar ao primeiro dia faria justamente quem menos usa o app perder o
  /// único resumo que ele dá.
  static final shouldShow = Provider.autoDispose<bool>((ref) {
    final memoria = ref.watch(seen);

    if (!memoria.ready) return false;

    return memoria.seen != ref.watch(lastWeekId);
  });
}
