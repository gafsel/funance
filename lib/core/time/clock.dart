import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fonte do "agora".
typedef Clock = DateTime Function();

/// Relógio do app.
///
/// Tudo que precisa da hora corrente passa por aqui: `DateTime.now()` no corpo
/// de um provider sem dispose congela a data no instante em que o provider foi
/// criado — o app aberto na virada do mês continuava mostrando o mês anterior
/// até ser reiniciado. Em teste, basta sobrescrever este provider.
final clockProvider = Provider<Clock>((ref) => DateTime.now);

/// Data corrente, normalizada à meia-noite local.
///
/// Reemite na virada do dia e quando o app volta do background (o timer não
/// roda enquanto o processo está suspenso, e o usuário volta no dia seguinte).
/// Todo cálculo de período em provider deriva daqui, para reagir à virada sem
/// depender de um rebuild acidental.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

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
    _scheduleMidnight(today);
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
    _scheduleMidnight(today);
  }

  DateTime _startOfToday() {
    final now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }

  void _scheduleMidnight(DateTime today) {
    _midnightTimer?.cancel();

    final now = ref.read(clockProvider)();
    final delay = today.add(const Duration(days: 1)).difference(now);

    _midnightTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      refresh,
    );
  }
}
