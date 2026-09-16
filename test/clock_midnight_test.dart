import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/date_extension.dart';

/// Relógio de mentira: o teste move o ponteiro à mão.
class _FakeClock {
  _FakeClock(this._now);

  DateTime _now;
  int reads = 0;

  DateTime call() {
    reads++;
    return _now;
  }

  set now(DateTime value) => _now = value;
}

/// Procura, no fuso local, um dia que não tenha 24h (entrada ou saída do
/// horário de verão). Devolve null onde o fuso não pratica DST — o ambiente
/// padrão deste projeto (America/Sao_Paulo) é um desses.
DateTime? _findIrregularLocalDay() {
  for (var day = DateTime(2025, 1, 1); day.year < 2028; day = day.addCalendarDays(1)) {
    final next = day.nextMidnight;
    if (next.difference(day) != const Duration(hours: 24)) {
      return day;
    }
  }
  return null;
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('durationUntilNextMidnight', () {
    test('conta o que falta para a meia-noite do dia seguinte', () {
      final delay = durationUntilNextMidnight(DateTime(2026, 3, 31, 23, 30));

      expect(delay, const Duration(minutes: 30));
    });

    test('à meia-noite aponta para a meia-noite seguinte, não para agora', () {
      final midnight = DateTime(2026, 3, 31);
      final delay = durationUntilNextMidnight(midnight);

      expect(delay, greaterThan(const Duration(hours: 20)));
      expect(midnight.add(delay), DateTime(2026, 4, 1));
    });

    test('nunca devolve atraso não positivo', () {
      // Fim do dia, virada do mês, virada do ano e o instante exato da
      // meia-noite: nenhum pode agendar um timer para "agora".
      for (final now in [
        DateTime(2026, 3, 31, 23, 59, 59, 999),
        DateTime(2026, 12, 31, 23, 59, 59, 999),
        DateTime(2026, 2, 28, 23, 59, 59, 999),
        DateTime(2026, 1, 1),
      ]) {
        expect(
          durationUntilNextMidnight(now),
          greaterThanOrEqualTo(midnightRescheduleFloor),
          reason: 'atraso inválido para $now',
        );
      }
    });

    test('cai no piso quando o alvo já passou', () {
      // Um relógio de sistema ajustado para a frente coloca "agora" depois da
      // meia-noite que estava agendada.
      final delay = durationUntilNextMidnight(
        DateTime(2026, 3, 31, 23, 59, 59, 999),
      );

      expect(delay, midnightRescheduleFloor);
    });

    test('num dia de 23h ou 25h ainda aponta para a meia-noite', () {
      final irregularDay = _findIrregularLocalDay();
      if (irregularDay == null) {
        markTestSkipped(
          'O fuso local não pratica horário de verão; a aritmética de '
          'calendário está coberta pelos demais casos.',
        );
        return;
      }

      final midMorning = irregularDay.add(const Duration(hours: 9));
      final delay = durationUntilNextMidnight(midMorning);

      // O ponto do bug: com `add(Duration(days: 1))` isto cairia às 23:00 (ou
      // 01:00) em vez da meia-noite.
      expect(midMorning.add(delay), irregularDay.nextMidnight);
      expect(midMorning.add(delay).hour, 0);
    });
  });

  group('todayProvider', () {
    test('o timer vira a data à meia-noite', () {
      fakeAsync((async) {
        final clock = _FakeClock(DateTime(2026, 3, 31, 23, 59));
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(clock.call)],
        );
        addTearDown(container.dispose);

        container.listen(todayProvider, (_, _) {}, fireImmediately: true);
        expect(container.read(todayProvider), DateTime(2026, 3, 31));

        clock.now = DateTime(2026, 4, 1);
        async.elapse(const Duration(minutes: 1));

        expect(container.read(todayProvider), DateTime(2026, 4, 1));
      });
    });

    test('um timer que dispara cedo não vira laço quente', () {
      fakeAsync((async) {
        // Reproduz o que o dia de 25h provocava: o timer acorda, a data ainda
        // não virou e o próximo alvo já passou. Sem piso o reagendamento cai
        // em zero e vira laço quente; com piso, um disparo por minuto.
        final clock = _FakeClock(DateTime(2026, 11, 1, 23, 59, 59, 999, 999));
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(clock.call)],
        );
        addTearDown(container.dispose);

        container.listen(todayProvider, (_, _) {}, fireImmediately: true);
        expect(container.read(todayProvider), DateTime(2026, 11, 1));

        expect(
          durationUntilNextMidnight(clock.call()),
          midnightRescheduleFloor,
        );

        final readsBefore = clock.reads;
        // Uma hora inteira com o relógio parado na véspera da meia-noite.
        async.elapse(const Duration(hours: 1));

        // Com o piso de 1 minuto são ~60 refreshes (2 leituras de relógio
        // cada); o bug original fazia centenas de milhares em milissegundos.
        final refreshes = (clock.reads - readsBefore) ~/ 2;
        expect(refreshes, lessThanOrEqualTo(61));
        expect(refreshes, greaterThan(0));
        expect(container.read(todayProvider), DateTime(2026, 11, 1));

        // E quando o relógio finalmente passa da meia-noite, a data vira.
        clock.now = DateTime(2026, 11, 2, 0, 0, 30);
        async.elapse(midnightRescheduleFloor * 2);

        expect(container.read(todayProvider), DateTime(2026, 11, 2));
      });
    });

    test('o timer é cancelado no dispose', () {
      fakeAsync((async) {
        final clock = _FakeClock(DateTime(2026, 3, 31, 12));
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(clock.call)],
        );

        container.listen(todayProvider, (_, _) {}, fireImmediately: true);
        container.dispose();

        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
