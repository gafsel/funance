import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
import 'package:funances/features/user/presentation/widgets/avatar_picker.dart';

import '../arena/arena_harness.dart';
import '../arena/hud_harness.dart';
import '../support/home_harness.dart';
import 'golden_support.dart';

/// O seletor de avatar e o que ele produz na cena.
///
/// Os dois PNGs do seletor existem porque ele é feito de duas coisas que
/// nenhuma asserção alcança: o SPRITE ampliado sem interpolação (se alguém
/// trocar a tinta por uma com `FilterQuality.low`, a grade continua passando
/// em todos os testes e vira um borrão) e o ANEL de escolhido, que é a única
/// diferença visual entre "este é o meu herói" e "este é mais um boneco".
///
/// A pré-visualização entra nos dois: ela é a resposta à pergunta que o
/// usuário está de fato fazendo ("como eu vou ficar lá?"), e o único jeito de
/// conferir que o boneco na cena é o mesmo da grade — mesmo painter, mesma
/// folha, tamanho de cena — é olhando os dois lado a lado num PNG.
///
/// O terceiro PNG é a consequência: a mesma Arena de sempre com os avatares
/// ESCOLHIDOS no lugar dos da ordem de entrada, e com o distintivo do segundo
/// membro que repetiu o boneco do primeiro. É o único lugar onde se vê que o
/// anel dourado no chão separa dois sprites idênticos.

/// A folha de sprites é decodificada por `decodeImageFromList`, que depende
/// do relógio de VERDADE: sem estes quadros reais o PNG sai com a grade
/// montada e nenhum boneco dentro.
Future<void> _bombearSprites(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}

Future<void> _pumpSeletor(
  WidgetTester tester, {
  required Brightness brightness,
}) async {
  await setGoldenSurface(tester, const Size(400, 620));

  await tester.runAsync(() async {
    await tester.pumpWidget(
      goldenApp(
        Scaffold(
          body: Padding(
            padding: AppSpacing.allMd,
            child: Align(
              alignment: Alignment.topLeft,
              child: AvatarField(
                selected: HeroSkin.ranger,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
        brightness: brightness,
      ),
    );

    await _bombearSprites(tester);
  });

  await tester.pump();
}

void main() {
  testWidgets('golden — seletor de avatar, claro', (tester) async {
    await _pumpSeletor(tester, brightness: Brightness.light);

    await expectLater(
      find.byType(AvatarField),
      matchesGoldenFile('images/avatar_seletor.png'),
    );
  });

  testWidgets('golden — seletor de avatar, escuro', (tester) async {
    await _pumpSeletor(tester, brightness: Brightness.dark);

    await expectLater(
      find.byType(AvatarField),
      matchesGoldenFile('images/avatar_seletor_escuro.png'),
    );
  });

  testWidgets('golden — a Arena com os avatares escolhidos', (tester) async {
    await loadAppFonts();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // O casal escolheu o MESMO ferreiro. A cena tem de continuar dizendo que
    // são duas pessoas, e é o anel dourado do segundo que diz isso.
    final estado = arenaTestState().copyWith(
      heroes: const [
        ArenaHero(userId: 'u1', name: 'Gabriel', skin: HeroSkin.smith),
        ArenaHero(
          userId: 'u2',
          name: 'Ana',
          skin: HeroSkin.smith,
          duplicate: true,
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        homeApp(
          const ArenaTab(),
          brightness: Brightness.light,
          overrides: [
            ...homeOverrides(
              missions: homeTypicalMissions(),
              installments: homeTypicalInstallments(),
              goals: homeTypicalGoals(),
              categories: homeTypicalCategories,
              summary: homeTypicalSummary(),
              pendingAutomatic: homeTypicalPending(),
              lastInsight: homeTypicalInsight(),
              health: const FinancialHealth(
                score: 72,
                tier: FreedomTier.guardiao,
              ),
            ),
            ArenaViewProviders.state.overrideWith(
              (ref) => AsyncValue<ArenaState>.data(estado),
            ),
            ArenaViewProviders.isBusiness.overrideWith((ref) => false),
            HudViewProviders.state.overrideWith(
              (ref) => AsyncValue<HudState>.data(hudTestState()),
            ),
          ],
        ),
      );

      await _bombearSprites(tester);
    });

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    await expectLater(
      find.byType(ArenaTab),
      matchesGoldenFile('images/arena_avatar_repetido.png'),
    );
  });
}
