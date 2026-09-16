import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/utils/date_extension.dart';

/// Fonte do "agora".
typedef Clock = DateTime Function();

/// Relógio do app.
///
/// Tudo que precisa da hora corrente passa por aqui: `DateTime.now()` no corpo
/// de um provider sem dispose congela a data no instante em que o provider foi
/// criado — o app aberto na virada do mês continuava mostrando o mês anterior
/// até ser reiniciado. Em teste, basta sobrescrever este provider.
final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// Piso do reagendamento da virada.
///
/// Se o cálculo devolver um atraso não positivo (relógio do sistema ajustado
/// para trás, timer que disparou cedo), reagendar para "agora" transformaria
/// o timer num laço quente. Um minuto é curto o bastante para a data virar
/// sem atraso perceptível e longo o bastante para não pesar.
@visibleForTesting
const midnightRescheduleFloor = Duration(minutes: 1);

/// Data corrente, normalizada à meia-noite local.
///
/// Reemite na virada do dia e quando o app volta do background (o timer não
/// roda enquanto o processo está suspenso, e o usuário volta no dia seguinte).
/// Todo cálculo de período em provider deriva daqui, para reagir à virada sem
/// depender de um rebuild acidental.
///
/// Observa o ciclo de vida do app, então em teste o binding precisa existir:
/// chame `TestWidgetsFlutterBinding.ensureInitialized()` antes de ler este
/// provider num `test()` (o `testWidgets()` já faz isso por você).
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

/// Quanto falta, a partir de [now], para a próxima meia-noite local.
///
/// Calculado por calendário: `today.add(const Duration(days: 1))` são 24h
/// absolutas e erra por uma hora nos dias em que o horário de verão entra ou
/// sai. No dia de 25h isso fazia o timer disparar às 23:00, a data não mudar
/// e o reagendamento cair em zero — um laço quente de uma hora.
Duration durationUntilNextMidnight(DateTime now) {
  final delay = DateTime(
    now.year,
    now.month,
    now.day,
  ).nextMidnight.difference(now);

  return delay < midnightRescheduleFloor ? midnightRescheduleFloor : delay;
}

class TodayNotifier extends Notifier<DateTime> with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  DateTime build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);

    ref.onDispose(() {
      _midnightTimer?.cancel();
      _midnightTimer = null;
      binding.removeObserver(this);
    });

    // Rebuilda o notifier inteiro se o relógio for trocado (teste).
    ref.watch(clockProvider);

    final today = _startOfToday();
    _scheduleMidnight();
    return today;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }

  /// Reavalia a data agora. Chamado na virada do dia e na volta do background.
  void refresh() {
    final today = _startOfToday();
    if (today != state) {
      state = today;
    }
    _scheduleMidnight();
  }

  DateTime _startOfToday() {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    _midnightTimer = Timer(
      durationUntilNextMidnight(ref.read(clockProvider)()),
      refresh,
    );
  }
}
