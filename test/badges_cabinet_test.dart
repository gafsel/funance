import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/screens/badges_cabinet_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/badges/badge_theme.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F2.7 — a vitrine renderiza a partir do catálogo servido pelo backend
/// (`config/badges`), não mais de uma cópia escrita à mão neste app.
const _catalog = BadgeCatalog(
  version: 'v1',
  badges: [
    BadgeCatalogItem(
      id: 'first_step',
      name: {'pt': 'Primeiro Passo', 'en': 'Primeiro Passo (en)'},
      icon: 'rocket_launch',
      xpReward: 100,
      category: BadgeCategory.advanced,
      description: {'pt': 'Concluir o onboarding.'},
    ),
    BadgeCatalogItem(
      id: 'first_goal',
      name: {'pt': 'Sonhador', 'en': 'Sonhador (en)'},
      icon: 'flag',
      xpReward: 50,
      category: BadgeCategory.firstSteps,
      description: {'pt': 'Criar a primeira meta.'},
    ),
    BadgeCatalogItem(
      id: 'badge_do_futuro',
      name: {'pt': 'Badge do Futuro', 'en': 'Badge do Futuro (en)'},
      icon: 'icone_que_o_app_nao_conhece',
      xpReward: 10,
      category: BadgeCategory.unknown,
      description: {'pt': 'Publicado por um servidor mais novo que o app.'},
    ),
  ],
  // Mesma régua do servidor: 300 * (2^(n-1) - 1).
  levelThresholds: [0, 300, 900, 2100],
);

Widget _app(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('pt', 'BR')],
    locale: const Locale('pt', 'BR'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('BadgesCabinetView', () {
    testWidgets('renderiza as seções e os nomes vindos do catálogo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const BadgesCabinetView(
            catalog: _catalog,
            isLoading: false,
            workspaceName: 'Casa',
            level: 2,
            xp: 450,
            weeklyStreaks: 0,
            unlockedBadges: {'first_step': '2026-03-01T10:00:00.000Z'},
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text('Primeiro Passo'), findsOneWidget);
      expect(find.text(l10n.badgeCategoryAdvanced), findsOneWidget);
      expect(find.text(l10n.badgeCategoryFirstSteps), findsOneWidget);
      // Contador do topo: 1 desbloqueado de 3 badges publicados.
      expect(find.text(l10n.badgeCatalogTotal(1, 3)), findsOneWidget);
    });

    testWidgets('o nível sai dos levelThresholds do catálogo', (tester) async {
      await tester.pumpWidget(
        _app(
          const BadgesCabinetView(
            catalog: _catalog,
            isLoading: false,
            workspaceName: 'Casa',
            level: 2,
            xp: 450,
            weeklyStreaks: 0,
            unlockedBadges: {},
          ),
        ),
      );
      await tester.pump();

      // Nível 2 abre em 300 e o 3 em 900: 450 XP são 150 dentro de um degrau
      // de 600. Nada disso é calculado no app.
      expect(find.text('150 / 600 XP'), findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(0.25, 0.0001));
    });

    testWidgets('sem catálogo publicado, mostra o estado indisponível', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const BadgesCabinetView(
            catalog: null,
            isLoading: false,
            workspaceName: 'Casa',
            level: 1,
            xp: 0,
            weeklyStreaks: 0,
            unlockedBadges: {},
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.badgeCatalogUnavailableTitle), findsOneWidget);
      expect(find.text(l10n.badgeCatalogUnavailableMessage), findsOneWidget);
    });

    testWidgets('"Como ganhar XP" sai do catálogo do servidor', (tester) async {
      await tester.pumpWidget(
        _app(
          const BadgesCabinetView(
            catalog: BadgeCatalog(
              version: 'v1',
              badges: [
                BadgeCatalogItem(
                  id: 'first_step',
                  name: {'pt': 'Primeiro Passo'},
                  icon: 'rocket_launch',
                  xpReward: 100,
                  category: BadgeCategory.advanced,
                ),
              ],
              levelThresholds: [0, 300],
              xpSources: [
                XpSource(
                  id: 'transaction_logged',
                  name: {'pt': 'Registrar um lançamento'},
                  xp: 5,
                  description: {'pt': 'Cada gasto ou receita anotado.'},
                ),
                XpSource(
                  id: 'weekly_mission',
                  name: {'pt': 'Concluir uma missão semanal'},
                  xp: 150,
                ),
              ],
            ),
            isLoading: false,
            workspaceName: 'Casa',
            level: 1,
            xp: 0,
            weeklyStreaks: 0,
            unlockedBadges: {},
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.xpSourcesTitle), findsOneWidget);
      expect(find.text('Registrar um lançamento'), findsOneWidget);
      expect(find.text('Cada gasto ou receita anotado.'), findsOneWidget);
      expect(find.text(l10n.xpValue('150')), findsOneWidget);
    });

    testWidgets('sem xpSources publicados, a seção some', (tester) async {
      await tester.pumpWidget(
        _app(
          const BadgesCabinetView(
            catalog: _catalog,
            isLoading: false,
            workspaceName: 'Casa',
            level: 1,
            xp: 0,
            weeklyStreaks: 0,
            unlockedBadges: {},
          ),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );

      expect(find.text(l10n.xpSourcesTitle), findsNothing);
    });
  });

  group('BadgeCatalog', () {
    test('xpForLevel segue a tabela publicada', () {
      expect(_catalog.xpForLevel(1), 0);
      expect(_catalog.xpForLevel(2), 300);
      expect(_catalog.xpForLevel(3), 900);
      // Acima da tabela, satura no último limiar em vez de estourar o índice.
      expect(_catalog.xpForLevel(99), 2100);
    });

    test('levelProgress é 0 quando o catálogo ainda não tem tabela', () {
      const vazio = BadgeCatalog();
      expect(vazio.levelProgress(3, 5000), 0);
    });

    test('categorias vazias não viram seção', () {
      expect(_catalog.categories, [
        BadgeCategory.advanced,
        BadgeCategory.firstSteps,
        BadgeCategory.unknown,
      ]);
    });
  });

  group('badgeIconFor', () {
    test('um ícone desconhecido cai num troféu genérico', () {
      expect(badgeIconFor('icone_que_o_app_nao_conhece'), Icons.emoji_events);
      expect(badgeIconFor('rocket_launch'), Icons.rocket_launch);
    });
  });
}
