import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_card.dart';

/// baixo — `paper` e `raised` eram o mesmo cartão.
///
/// As duas variantes tinham a mesma superfície, a mesma borda, e diferiam só
/// por uma sombra que no tema claro quase não existe: escolher entre elas não
/// mudava nada que se visse, e a variante virou decoração no código. A
/// documentação já dizia a regra — "é plana, a separação vem de uma borda de
/// 1px" contra "pousado sobre o fundo" —, só o desenho é que não dizia.

BoxDecoration _decoracao(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(AppCard),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Future<void> _pump(
  WidgetTester tester,
  Widget card, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: card)),
    ),
  );
  await tester.pump();
}

void main() {
  for (final entry in {
    'claro': (theme: AppTheme.light, palette: AppPalette.light),
    'escuro': (theme: AppTheme.dark, palette: AppPalette.dark),
  }.entries) {
    final tema = entry.value;

    group('AppCard no tema ${entry.key}', () {
      testWidgets('paper separa por BORDA', (tester) async {
        await _pump(
          tester,
          const AppCard(child: Text('conteúdo')),
          theme: tema.theme,
        );

        final decoracao = _decoracao(tester);

        expect(decoracao.border, isNotNull);
        expect((decoracao.border! as Border).top.color, tema.palette.line);
        expect(decoracao.boxShadow, isEmpty);
      });

      testWidgets('raised separa por SOMBRA', (tester) async {
        await _pump(
          tester,
          const AppCard(
            variant: AppCardVariant.raised,
            child: Text('conteúdo'),
          ),
          theme: tema.theme,
        );

        final decoracao = _decoracao(tester);

        expect(
          decoracao.border,
          isNull,
          reason: 'borda E sombra ao mesmo tempo é a soma das duas regras',
        );
        expect(decoracao.boxShadow, isNotEmpty);
      });

      testWidgets('os dois continuam sendo papel', (tester) async {
        await _pump(
          tester,
          const AppCard(child: Text('conteúdo')),
          theme: tema.theme,
        );
        expect(_decoracao(tester).color, tema.palette.paper);

        await _pump(
          tester,
          const AppCard(
            variant: AppCardVariant.raised,
            child: Text('conteúdo'),
          ),
          theme: tema.theme,
        );
        expect(_decoracao(tester).color, tema.palette.paper);
      });

      testWidgets('o aro de recompensa manda mesmo em raised', (tester) async {
        await _pump(
          tester,
          const AppCard(
            variant: AppCardVariant.raised,
            rewarded: true,
            child: Text('conteúdo'),
          ),
          theme: tema.theme,
        );

        final borda = _decoracao(tester).border! as Border;

        expect(borda.top.color, AppColors.gold);
        expect(borda.top.width, 2);
      });

      testWidgets('uma borda pedida por quem chama também manda', (
        tester,
      ) async {
        await _pump(
          tester,
          const AppCard(
            variant: AppCardVariant.raised,
            borderColor: AppColors.violet,
            child: Text('conteúdo'),
          ),
          theme: tema.theme,
        );

        expect(
          (_decoracao(tester).border! as Border).top.color,
          AppColors.violet,
        );
      });

      testWidgets('game é o bloco escuro, nos dois temas', (tester) async {
        await _pump(
          tester,
          const AppCard.game(child: Text('conteúdo')),
          theme: tema.theme,
        );

        final decoracao = _decoracao(tester);

        expect(decoracao.gradient, isNotNull);
        expect(decoracao.color, isNull);
        expect((decoracao.border! as Border).top.color, AppColors.surfaceRaised);
      });
    });
  }
}
