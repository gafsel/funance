import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
import 'package:go_router/go_router.dart';

import '../support/home_harness.dart';
import 'arena_harness.dart';

/// O golpe que espera a cena voltar à frente.
///
/// O defeito da rodada 1 estava numa bandeira: `_drainedPending` virava
/// `true` na primeira montagem e **nunca** voltava a falso. Como o formulário
/// de lançamento é uma rota empilhada POR CIMA da Home, a `ArenaView` nunca
/// desmonta — então o primeiro lançamento da sessão consumia a bandeira e
/// todos os seguintes eram engolidos em silêncio.
///
/// A condição certa não é "é a primeira vez": é **existe evento** e **a cena
/// está na frente**. Este teste percorre o caminho inteiro — Home, empilha o
/// formulário, lança, volta — e faz isso DUAS vezes, porque o segundo
/// lançamento é exatamente o que a rodada 1 perdia.

/// Quadros suficientes para a navegação assentar.
///
/// `pumpAndSettle` não serve aqui: o laço do Flame tem a respiração dos
/// bonecos, que nunca para — a cena é *feita* para não assentar.
Future<void> _navegar(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

/// A Home — que agora É a Arena — e uma rota empilhada que imita o formulário
/// de lançamento.
Widget _app() => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  routerConfig: GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: ArenaTab())),
      GoRoute(
        path: '/transactions/form',
        builder: (_, _) => const Scaffold(body: Center(child: Text('form'))),
      ),
    ],
  ),
  localizationsDelegates: arenaLocalizationDelegates,
  supportedLocales: arenaSupportedLocales,
  locale: const Locale('pt'),
);

/// Os mesmos dublês da Home: a cena carrega os ícones de missões, Bússola,
/// coach e pendências, e cada um deles lê um provider.
List<Override> _overrides() => homeOverrides(
  extra: [
    ArenaViewProviders.state.overrideWith(
      (ref) => AsyncValue<ArenaState>.data(arenaTestState()),
    ),
    ArenaViewProviders.isBusiness.overrideWith((ref) => false),
  ],
);

void main() {
  testWidgets(
    'o golpe espera o formulário sair da frente — e vale para o SEGUNDO '
    'lançamento também',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(overrides: _overrides());
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          UncontrolledProviderScope(container: container, child: _app()),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(Duration.zero);
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      });
      await arenaFrames(tester);

      final notifier = container.read(ArenaViewProviders.pendingEvent.notifier);

      Future<void> lancar(double valor) async {
        // 1. o usuário abre o formulário: a Home continua MONTADA, mas deixa
        //    de ser a rota da frente.
        final context = tester.element(find.byType(ArenaTab));
        unawaited(GoRouter.of(context).push<void>('/transactions/form'));
        await _navegar(tester);

        expect(find.text('form'), findsOneWidget);

        // 2. ele salva: o evento é guardado.
        notifier.push(ArenaPendingEvent(damage: valor));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));

        expect(
          container.read(ArenaViewProviders.pendingEvent),
          isNotNull,
          reason:
              'com o formulário na frente, o golpe espera: animar aqui seria '
              'animar numa cena que ninguém está vendo',
        );

        // 3. ele volta.
        GoRouter.of(tester.element(find.text('form'))).pop();
        await _navegar(tester);
        await arenaFrames(tester);
      }

      await lancar(89.90);
      expect(
        container.read(ArenaViewProviders.pendingEvent),
        isNull,
        reason: 'de volta à Home, o golpe foi consumido',
      );

      // O que a rodada 1 perdia: a bandeira nunca voltava a falso.
      await lancar(42);
      expect(
        container.read(ArenaViewProviders.pendingEvent),
        isNull,
        reason:
            'o segundo lançamento da sessão anima igual ao primeiro; era aqui '
            'que a bandeira de "já drenei" engolia o golpe',
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('evento que chega com a Arena já na frente anima na hora', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: _overrides());
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: _app()),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    });
    await arenaFrames(tester);

    container
        .read(ArenaViewProviders.pendingEvent.notifier)
        .push(const ArenaPendingEvent(healed: 6000));
    await tester.pump();
    await arenaFrames(tester);

    expect(container.read(ArenaViewProviders.pendingEvent), isNull);
  });
}
