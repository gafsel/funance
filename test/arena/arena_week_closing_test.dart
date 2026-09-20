import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/time/product_week.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/arena_week_closing.dart';
import 'package:funances/features/arena/presentation/widgets/arena_week_closing_banner.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arena_harness.dart';

/// O placar da semana que fechou.
///
/// Uma semana de jogo sem placar é uma semana sem fim: a barra zera no
/// domingo e o que aconteceu some junto. O risco desta peça não é ela deixar
/// de aparecer — é ela aparecer DEMAIS: um aviso que volta a cada abertura
/// durante sete dias deixa de ser aviso no terceiro dia.
///
/// Por isso os testes aqui são quase todos sobre quando ela NÃO aparece.

final _wednesday = DateTime(2026, 9, 23, 10);

/// A semana que fechou no sábado 19/09/2026 — calculada, e não escrita à
/// mão: a numeração é a do produto (domingo a sábado), e um id chutado
/// passaria a valer só por coincidência.
final _semanaPassada = ProductWeek.idOf(DateTime(2026, 9, 19));

Widget _app(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt'),
    home: const Scaffold(body: ArenaWeekClosingBanner()),
  ),
);

ProviderContainer _container({
  ArenaState? lastWeek,
  Map<String, Object> prefs = const {},
}) {
  SharedPreferences.setMockInitialValues(prefs);

  // Sem `addTearDown`: o `flutter_test` confere "não ficou timer pendente"
  // ANTES de rodar os tearDowns, e o `todayProvider` agenda um timer para a
  // virada da meia-noite. Quem descarta é o próprio corpo do teste.
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _wednesday),
      ArenaViewProviders.lastWeekState.overrideWith(
        (ref) => lastWeek == null
            ? const AsyncValue<ArenaState>.loading()
            : AsyncValue<ArenaState>.data(lastWeek),
      ),
    ],
  );
  return container;
}

/// Espera a leitura do `SharedPreferences` chegar.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('a semana que fechou vira placar, uma vez', (tester) async {
    final container = _container(
      lastWeek: arenaTestState(
        currentBalance: 3115.02,
        commitments: [
          arenaTestCommitment(paid: true),
          arenaTestCommitment(
            id: 'luz',
            description: 'Luz',
            amount: 180,
            dayOffset: 2,
            paid: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsOneWidget);
    expect(find.text('Semana passada: monstro derrotado'), findsOneWidget);
    expect(find.textContaining('2 de 2 compromissos pagos'), findsOneWidget);
    expect(find.textContaining('3.115,02'), findsOneWidget);

    container.dispose();
  });

  testWidgets('monstro que escapou mostra com quanto ele ficou', (
    tester,
  ) async {
    final container = _container(
      lastWeek: arenaTestState(
        commitments: [
          arenaTestCommitment(paid: true),
          arenaTestCommitment(
            id: 'luz',
            description: 'Luz',
            amount: 180,
            dayOffset: 2,
          ),
        ],
      ),
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.textContaining('o monstro escapou'), findsOneWidget);
    expect(find.textContaining('1 de 2'), findsOneWidget);

    container.dispose();
  });

  testWidgets('dispensar grava, e ele não volta', (tester) async {
    final container = _container(
      lastWeek: arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('arena-week-closing-dismiss')));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsNothing);
    expect(container.read(ArenaWeekClosingProviders.seen).seen, _semanaPassada);

    container.dispose();
  });

  testWidgets('quem já viu não vê de novo', (tester) async {
    final container = _container(
      lastWeek: arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
      prefs: {ArenaWeekClosingNotifier.storageKey: _semanaPassada},
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsNothing);

    container.dispose();
  });

  testWidgets('quem viu o placar de OUTRA semana vê o desta', (tester) async {
    final container = _container(
      lastWeek: arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
      prefs: {ArenaWeekClosingNotifier.storageKey: '2026-W30'},
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsOneWidget);

    container.dispose();
  });

  testWidgets('semana passada sem compromisso nenhum não tem placar', (
    tester,
  ) async {
    // "0 de 0 compromissos pagos" é pior que silêncio.
    final container = _container(
      lastWeek: arenaTestState(commitments: const []),
    );

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsNothing);

    container.dispose();
  });

  testWidgets('enquanto os números não chegam, nada aparece', (tester) async {
    final container = _container();

    await tester.pumpWidget(_app(container));
    await _settle(tester);

    expect(find.byKey(const ValueKey('arena-week-closing')), findsNothing);

    container.dispose();
  });

  testWidgets('o placar não pisca antes de o disco responder', (tester) async {
    // Se o widget decidisse no primeiro quadro, quem já dispensou veria o
    // placar aparecer e sumir — e um aviso que pisca é pior que um aviso que
    // não aparece.
    final container = _container(
      lastWeek: arenaTestState(commitments: [arenaTestCommitment(paid: true)]),
      prefs: {ArenaWeekClosingNotifier.storageKey: _semanaPassada},
    );

    await tester.pumpWidget(_app(container));
    // SEM assentar: é o primeiro quadro.
    expect(find.byKey(const ValueKey('arena-week-closing')), findsNothing);

    container.dispose();
  });
}
