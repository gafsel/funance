import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/workspace/domain/models/badge_catalog_model.dart';
import 'package:funances/features/workspace/presentation/screens/badges_cabinet_screen.dart';

import 'golden_support.dart';

/// F4.8 §5.2 — 62% do arquivo era um mini design-system de emblemas
/// (`BadgeShapePainter`, `MetallicIcon3D`, formas, gradientes). Tudo isso é
/// pintura: se a extração mudar um stop de gradiente ou um offset, o golden
/// é o único lugar onde isso aparece.

const _catalog = BadgeCatalog(
  version: 'v1',
  badges: [
    BadgeCatalogItem(
      id: 'first_step',
      name: {'pt': 'Primeiro Passo'},
      icon: 'rocket_launch',
      xpReward: 100,
      category: BadgeCategory.advanced,
      description: {'pt': 'Concluir o onboarding.'},
    ),
    BadgeCatalogItem(
      id: 'maratonista',
      name: {'pt': 'Maratonista'},
      icon: 'bolt',
      xpReward: 200,
      category: BadgeCategory.advanced,
      description: {'pt': 'Oito semanas seguidas.'},
    ),
    BadgeCatalogItem(
      id: 'first_goal',
      name: {'pt': 'Sonhador'},
      icon: 'flag',
      xpReward: 50,
      category: BadgeCategory.goals,
      description: {'pt': 'Criar a primeira meta.'},
    ),
    BadgeCatalogItem(
      id: 'poupador',
      name: {'pt': 'Poupador'},
      icon: 'savings',
      xpReward: 80,
      category: BadgeCategory.savings,
      description: {'pt': 'Guardar 20% da renda.'},
    ),
    BadgeCatalogItem(
      id: 'time_unido',
      name: {'pt': 'Time Unido'},
      icon: 'groups',
      xpReward: 40,
      category: BadgeCategory.team,
      description: {'pt': 'Convidar alguém.'},
    ),
  ],
  levelThresholds: [0, 300, 900, 2100],
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
);

void main() {
  testWidgets('vitrine de emblemas — catálogo completo', (tester) async {
    await setGoldenSurface(tester, const Size(760, 1100));

    await tester.pumpWidget(
      goldenApp(
        const Scaffold(
          body: BadgesCabinetView(
            catalog: _catalog,
            isLoading: false,
            workspaceName: 'Casa',
            level: 2,
            xp: 450,
            weeklyStreaks: 3,
            unlockedBadges: {
              'first_step': '2026-03-01T10:00:00.000Z',
              'poupador': '2026-03-02T10:00:00.000Z',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BadgesCabinetView),
      matchesGoldenFile('images/badges_cabinet.png'),
    );
  });

  testWidgets('vitrine de emblemas — catálogo indisponível', (tester) async {
    await setGoldenSurface(tester, const Size(760, 460));

    await tester.pumpWidget(
      goldenApp(
        const Scaffold(
          body: BadgesCabinetView(
            catalog: null,
            isLoading: false,
            workspaceName: 'Casa',
            level: 1,
            xp: 0,
            weeklyStreaks: 0,
            unlockedBadges: {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BadgesCabinetView),
      matchesGoldenFile('images/badges_cabinet_indisponivel.png'),
    );
  });

  // M7 — a vitrine é a tela mais dourada do app; o ouro sobre papel escuro é
  // outro problema que o ouro sobre papel claro.
  testWidgets('vitrine de emblemas — catálogo completo (escuro)', (
    tester,
  ) async {
    await setGoldenSurface(tester, const Size(760, 1100));

    await tester.pumpWidget(
      goldenApp(
        brightness: Brightness.dark,
        const Scaffold(
          body: BadgesCabinetView(
            catalog: _catalog,
            isLoading: false,
            workspaceName: 'Casa',
            level: 2,
            xp: 450,
            weeklyStreaks: 3,
            unlockedBadges: {
              'first_step': '2026-03-01T10:00:00.000Z',
              'poupador': '2026-03-02T10:00:00.000Z',
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BadgesCabinetView),
      matchesGoldenFile('images/badges_cabinet_escuro.png'),
    );
  });
}
