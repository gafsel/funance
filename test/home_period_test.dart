import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/features/home/presentation/provider.dart';

/// Relógio de mentira: o teste move o ponteiro à mão.
class _FakeClock {
  _FakeClock(this._now);

  DateTime _now;

  DateTime call() => _now;

  set now(DateTime value) => _now = value;
}

void main() {
  setUp(TestWidgetsFlutterBinding.ensureInitialized);

  group('período escolhido pelo usuário', () {
    test('segue o dia corrente enquanto ninguém escolhe', () {
      fakeAsync((async) {
        final clock = _FakeClock(DateTime(2026, 3, 31, 23, 59));
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(clock.call)],
        );
        addTearDown(container.dispose);

        container.listen(HomeViewProviders.period, (_, _) {},
            fireImmediately: true);
        expect(container.read(HomeViewProviders.period), DateTime(2026, 3, 31));

        clock.now = DateTime(2026, 4, 1);
        async.elapse(const Duration(minutes: 1));

        expect(container.read(HomeViewProviders.period), DateTime(2026, 4, 1));
      });
    });

    test('a virada do dia não descarta o mês escolhido à mão', () {
      fakeAsync((async) {
        final clock = _FakeClock(DateTime(2026, 3, 31, 23, 59));
        final container = ProviderContainer(
          overrides: [clockProvider.overrideWithValue(clock.call)],
        );
        addTearDown(container.dispose);

        container.listen(HomeViewProviders.period, (_, _) {},
            fireImmediately: true);

        // O usuário volta para janeiro.
        container
            .read(HomeViewProviders.period.notifier)
            .choose(DateTime(2026, 1));
        expect(container.read(HomeViewProviders.period), DateTime(2026, 1));

        clock.now = DateTime(2026, 4, 1);
        async.elapse(const Duration(minutes: 1));

        expect(container.read(todayProvider), DateTime(2026, 4, 1));
        expect(
          container.read(HomeViewProviders.period),
          DateTime(2026, 1),
          reason: 'a virada do dia sobrescreveu a escolha do usuário',
        );

        // E ele pode voltar a seguir o relógio.
        container.read(HomeViewProviders.period.notifier).chooseToday();
        expect(container.read(HomeViewProviders.period), DateTime(2026, 4, 1));
      });
    });
  });
}
