import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/celebration/celebration_event.dart';
import 'package:funances/core/celebration/celebration_service.dart';
import 'package:funances/core/router/app_router.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/celebration_overlay.dart';
import 'package:funances/core/widgets/reward_toast.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/celebration/celebration_host.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'support/journey_fakes.dart';

/// F-design/4 — o canal de celebração deixou de ser o do erro.
///
/// Antes: badge virava `SnackBar` comum, missão concluída não fazia NADA,
/// subir de patente não tinha nem listener, e todo o feedback nascia de um
/// `ref.listen` dentro da `HomeScreen` — ou seja, só existia com a Home
/// montada. Estes testes são o contrato do que substituiu isso.

WorkspaceModel _workspace({
  String id = 'w1',
  int level = 1,
  int xp = 0,
  Map<String, String> badges = const {},
}) => WorkspaceModel(
  id: id,
  name: 'Casa',
  type: WorkspaceType.personal,
  createdAt: DateTime(2026, 1, 1),
  level: level,
  xp: xp,
  unlockedBadges: badges,
  currentWeekId: '2026-W37',
);

WeeklyMissionModel _mission({
  String id = 'm1',
  WeeklyMissionStatus status = WeeklyMissionStatus.active,
  String name = 'Planejar 5 categorias',
  int xp = 40,
}) => WeeklyMissionModel(
  id: id,
  name: name,
  type: WeeklyMissionType.consistency,
  status: status,
  weekId: '2026-W37',
  target: 5,
  progress: status.isCompleted ? 5 : 2,
  xp: xp,
);

FinancialHealth _health(FreedomTier tier) =>
    FinancialHealth(score: 48, tier: tier);

/// Monta o host exatamente como o `main.dart` monta: acima do conteúdo, e com
/// uma tela qualquer embaixo — de propósito NÃO a Home, porque o ponto do
/// pacote é justamente funcionar longe dela.
class _Harness extends StatelessWidget {
  const _Harness({required this.container});

  final ProviderContainer container;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        builder: (context, child) =>
            CelebrationHost(child: child ?? const SizedBox.shrink()),
        home: const Scaffold(body: Text('uma tela qualquer')),
      ),
    );
  }
}

/// O host montado como em produção: no `builder` de um `MaterialApp.router`,
/// ou seja ACIMA do `Router` na árvore. É essa posição — e só ela — que fazia
/// `GoRouter.of(context)` estourar quando alguém tocava no toast.
class _RouterHarness extends StatelessWidget {
  const _RouterHarness({required this.container, required this.router});

  final ProviderContainer container;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        builder: (context, child) =>
            CelebrationHost(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

GoRouter _fakeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('uma tela qualquer')),
    ),
    GoRoute(
      path: '/workspace/badges',
      builder: (_, _) => const Scaffold(body: Text('cofre de conquistas')),
    ),
  ],
);

void main() {
  group('CelebrationService', () {
    test('a mesma conquista não é celebrada duas vezes', () {
      final service = CelebrationService();

      expect(
        service.celebrate(CelebrationEvent.badge('primeiro_passo')),
        isTrue,
      );
      expect(
        service.celebrate(CelebrationEvent.badge('primeiro_passo')),
        isFalse,
        reason:
            'o Firestore reemite o documento a cada escrita; sem idempotência '
            'mexer numa missão faria a badge de ontem piscar de novo',
      );
      expect(service.state, hasLength(1));
    });

    test('a fila tem teto e mantém as mais recentes', () {
      final service = CelebrationService();

      for (var i = 0; i < 6; i++) {
        service.celebrate(CelebrationEvent.xp(10, sequence: i));
      }

      expect(service.state, hasLength(CelebrationService.maxVisible));
      expect(service.state.first.key, 'xp:3');
      expect(service.state.last.key, 'xp:5');
    });

    test('celebrateAll empilha da menor para a maior conquista', () {
      final service = CelebrationService()
        ..celebrateAll([
          CelebrationEvent.level(3),
          CelebrationEvent.xp(40, sequence: 1),
          CelebrationEvent.badge('b'),
        ]);

      expect(service.state.map((e) => e.kind).toList(), [
        CelebrationKind.xp,
        CelebrationKind.badge,
        CelebrationKind.level,
      ]);
    });

    test('trocar de workspace esquece o que já foi celebrado', () {
      final service = CelebrationService()
        ..celebrate(CelebrationEvent.level(7));
      expect(service.hasSeen('level:7'), isTrue);

      service.reset();

      expect(service.state, isEmpty);
      expect(service.hasSeen('level:7'), isFalse);
      expect(service.celebrate(CelebrationEvent.level(7)), isTrue);
    });

    test('dispensar tira só a conquista pedida', () {
      final service = CelebrationService()
        ..celebrate(CelebrationEvent.xp(10, sequence: 1))
        ..celebrate(CelebrationEvent.badge('b'));

      service.dismiss('xp:1');

      expect(service.state.single.key, 'badge:b');
    });
  });

  group('CelebrationOverlay', () {
    testWidgets('sem conquista, não embrulha nada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CelebrationOverlay(toasts: [], child: Text('conteúdo')),
        ),
      );

      expect(find.byType(Stack), findsNothing);
      expect(find.text('conteúdo'), findsOneWidget);
    });

    testWidgets('empilha os toasts no TOPO, longe da barra inferior', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CelebrationOverlay(
            toasts: const [
              RewardToast(icon: Icons.bolt, title: 'um'),
              RewardToast(icon: Icons.bolt, title: 'dois'),
            ],
            child: const Scaffold(
              body: SizedBox.expand(),
              bottomNavigationBar: SizedBox(height: 60, child: Text('barra')),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final toastTop = tester.getTopLeft(find.text('dois')).dy;
      final barTop = tester.getTopLeft(find.text('barra')).dy;

      expect(find.byType(RewardToast), findsNWidgets(2));
      expect(
        toastTop,
        lessThan(barTop),
        reason:
            'a tarja de sync já ensinou que uma camada colada embaixo cobre a '
            'barra e o botão de lançar',
      );
      expect(toastTop, lessThan(200));
    });
  });

  group('RewardToast', () {
    testWidgets('anuncia título, subtítulo e XP para o leitor de tela', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: RewardToast(
              icon: Icons.task_alt,
              title: 'Missão concluída',
              subtitle: 'Planejar 5 categorias',
              xpLabel: '+40 XP',
              major: true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Missão concluída'), findsOneWidget);
      expect(find.text('Planejar 5 categorias'), findsOneWidget);
      expect(find.text('+40 XP'), findsOneWidget);

      // Uma frase só para o leitor de tela, não três fragmentos soltos.
      expect(
        find.bySemanticsLabel(
          'Missão concluída. Planejar 5 categorias. +40 XP',
        ),
        findsOneWidget,
      );
    });

    testWidgets('some sozinho e avisa quem o montou', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: RewardToast(
              icon: Icons.bolt,
              title: 'XP ganho',
              dwell: const Duration(milliseconds: 300),
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 450));
      expect(dismissed, isFalse);

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(dismissed, isTrue);
    });

    testWidgets('com "reduzir movimento" não escala nem desloca', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: RewardToast(icon: Icons.bolt, title: 'XP ganho'),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: find.byType(RewardToast),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(RewardToast),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(find.text('XP ganho'), findsOneWidget);
    });
  });

  group('CelebrationHost', () {
    late FakeJourneyRepository journey;
    late TestWorkspaceNotifier notifier;

    ProviderContainer build({
      List<WeeklyMissionModel> missions = const [],
      FinancialHealth? health,
    }) {
      journey = FakeJourneyRepository(missions: missions, health: health);
      notifier = TestWorkspaceNotifier(
        WorkspaceState(currentWorkspace: _workspace()),
      );

      return ProviderContainer(
        overrides: [
          WorkspaceViewProviders.workspace.overrideWith((ref) => notifier),
          JourneyDomainProviders.repository.overrideWithValue(journey),
        ],
      );
    }

    testWidgets('XP ganho aparece LONGE da Home', (tester) async {
      final container = build();
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      expect(find.byType(RewardToast), findsNothing);

      notifier.state = WorkspaceState(currentWorkspace: _workspace(xp: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('uma tela qualquer'), findsOneWidget);
      expect(find.byType(RewardToast), findsOneWidget);
      expect(find.text('+40 XP'), findsOneWidget);
    });

    testWidgets('subir de nível não duplica o toast de XP', (tester) async {
      final container = build();
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(level: 2, xp: 500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RewardToast), findsOneWidget);
      expect(find.text('Nível 2'), findsOneWidget);
    });

    testWidgets('badge desbloqueada tem canal próprio, não um SnackBar', (
      tester,
    ) async {
      final container = build();
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(
          badges: const {'primeiro_passo': '2026-09-17T10:00:00.000Z'},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Conquista desbloqueada'), findsOneWidget);
    });

    testWidgets('a primeira emissão nunca celebra', (tester) async {
      final container = build(
        missions: [_mission(status: WeeklyMissionStatus.completed)],
        health: _health(FreedomTier.mestre),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(RewardToast),
        findsNothing,
        reason:
            'abrir o app com a semana já cumprida não é uma conquista de agora',
      );
    });

    testWidgets(
      'missão que fecha vira conquista — o que antes não fazia nada',
      (tester) async {
        final container = build(missions: [_mission()]);
        addTearDown(container.dispose);

        await tester.pumpWidget(_Harness(container: container));
        await tester.pump();
        expect(find.byType(RewardToast), findsNothing);

        journey.emitMissions([_mission(status: WeeklyMissionStatus.completed)]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Missão concluída'), findsOneWidget);
        expect(find.text('Planejar 5 categorias'), findsOneWidget);
        expect(find.text('+40 XP'), findsOneWidget);
      },
    );

    testWidgets('progresso de missão não celebra; só a virada', (tester) async {
      final container = build(missions: [_mission()]);
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      journey.emitMissions([_mission()]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RewardToast), findsNothing);
    });

    testWidgets('subir de patente celebra; cair, não', (tester) async {
      final container = build(health: _health(FreedomTier.guardiao));
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      journey.emitHealth(_health(FreedomTier.estrategista));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nova patente'), findsOneWidget);
      expect(find.text('Estrategista'), findsOneWidget);
    });

    testWidgets('cair de patente não vira conquista', (tester) async {
      final container = build(health: _health(FreedomTier.mestre));
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      journey.emitHealth(_health(FreedomTier.guardiao));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(RewardToast),
        findsNothing,
        reason: 'cair de patente é informação, não conquista',
      );
    });

    testWidgets('a mesma badge reemitida não pisca de novo', (tester) async {
      final container = build();
      addTearDown(container.dispose);

      await tester.pumpWidget(_Harness(container: container));
      await tester.pump();

      const badges = {'primeiro_passo': '2026-09-17T10:00:00.000Z'};
      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(badges: badges),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(RewardToast), findsOneWidget);

      // O serviço lembra a chave; nem sem o toast na tela ela volta.
      container.read(CelebrationProviders.queue.notifier).dismissAll();
      await tester.pump();
      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(badges: badges, xp: 1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Conquista desbloqueada'), findsNothing);
    });
  });

  /// B2 — tocar no toast derrubava o app.
  ///
  /// O host mora no `builder` do `MaterialApp.router`, acima do `Router`.
  /// `GoRouter.of(context)` sobe a árvore procurando um `InheritedGoRouter`
  /// que, daquele ponto, não existe: o toque respondia com
  /// "No GoRouter found in context" em vez de abrir o cofre. Quem ganhava a
  /// primeira badge do app tinha o app fechado na cara.
  group('CelebrationHost — o toque no toast', () {
    late TestWorkspaceNotifier notifier;

    ProviderContainer build(GoRouter router) {
      notifier = TestWorkspaceNotifier(
        WorkspaceState(currentWorkspace: _workspace()),
      );
      return ProviderContainer(
        overrides: [
          WorkspaceViewProviders.workspace.overrideWith((ref) => notifier),
          JourneyDomainProviders.repository.overrideWithValue(
            FakeJourneyRepository(),
          ),
          routerProvider.overrideWithValue(router),
        ],
      );
    }

    testWidgets('badge: o toque abre o cofre em vez de estourar', (
      tester,
    ) async {
      final router = _fakeRouter();
      addTearDown(router.dispose);
      final container = build(router);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _RouterHarness(container: container, router: router),
      );
      await tester.pump();

      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(
          badges: const {'primeiro_passo': '2026-09-17T10:00:00.000Z'},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Conquista desbloqueada'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('cofre de conquistas'), findsOneWidget);
    });

    testWidgets('nível: o toque abre o cofre em vez de estourar', (
      tester,
    ) async {
      final router = _fakeRouter();
      addTearDown(router.dispose);
      final container = build(router);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _RouterHarness(container: container, router: router),
      );
      await tester.pump();

      notifier.state = WorkspaceState(
        currentWorkspace: _workspace(level: 2, xp: 500),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Nível 2'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('cofre de conquistas'), findsOneWidget);
    });

    testWidgets('XP não navega para lugar nenhum', (tester) async {
      final router = _fakeRouter();
      addTearDown(router.dispose);
      final container = build(router);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        _RouterHarness(container: container, router: router),
      );
      await tester.pump();

      notifier.state = WorkspaceState(currentWorkspace: _workspace(xp: 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('+40 XP'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('cofre de conquistas'), findsNothing);
      expect(find.text('uma tela qualquer'), findsOneWidget);
    });
  });
}
