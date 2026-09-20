import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/level_badge.dart';

/// A5 — o emblema do nível sumia dentro da própria pílula.
///
/// O selo é ouro a 14% com um escudo de ouro VIVO por cima. Sobre papel claro
/// isso dá 1,52:1: o escudo existia no código e não na tela. A barrinha de XP
/// era pior — 1,22:1 contra o trilho —, e o defeito só ficou visível depois
/// que B1 fez as barras voltarem a pintar.
///
/// Piso de 3:1: escudo e barra são elementos gráficos, não texto.

const double grafico = 3;

/// O fundo que o selo realmente pinta, composto sobre a superfície de baixo.
Color _fundoDoSelo(WidgetTester tester, Color superficie) {
  final container = tester.widget<Container>(
    find
        .descendant(of: find.byType(LevelBadge), matching: find.byType(Container))
        .first,
  );
  return Color.alphaBlend(
    (container.decoration! as BoxDecoration).color!,
    superficie,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  required Color superficie,
  bool onGame = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        backgroundColor: superficie,
        body: Center(
          child: LevelBadge(
            level: 7,
            progress: 0.4,
            label: 'Nv 7',
            onGame: onGame,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _escudo(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.shield_moon_outlined)).color!;

AppProgressBar _barra(WidgetTester tester) =>
    tester.widget<AppProgressBar>(find.byType(AppProgressBar));

void _exige(String oque, Color a, Color b) {
  final razao = AppColors.contrastRatio(a, b);
  expect(
    razao,
    greaterThanOrEqualTo(grafico),
    reason: '$oque: ${razao.toStringAsFixed(2)}:1, piso $grafico:1',
  );
}

void main() {
  testWidgets('A5 — no tema claro o escudo se enxerga', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      superficie: AppColors.paperLight,
    );

    _exige(
      'escudo sobre o selo claro',
      _escudo(tester),
      _fundoDoSelo(tester, AppColors.paperLight),
    );
    expect(_escudo(tester), AppPalette.light.rewardText);
  });

  testWidgets('A5 — no tema escuro o escudo continua de ouro vivo', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.dark,
      superficie: AppColors.paperDark,
    );

    _exige(
      'escudo sobre o selo escuro',
      _escudo(tester),
      _fundoDoSelo(tester, AppColors.paperDark),
    );
    expect(_escudo(tester), AppColors.gold);
  });

  testWidgets('A5 — sobre superfície de jogo o ouro vivo vale nos dois temas', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      superficie: AppColors.surfaceDeep,
      onGame: true,
    );

    expect(_escudo(tester), AppColors.gold);
    _exige(
      'escudo sobre o selo de jogo',
      _escudo(tester),
      _fundoDoSelo(tester, AppColors.surfaceDeep),
    );
  });

  testWidgets('A5 — a barra de XP se separa do próprio trilho', (tester) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      superficie: AppColors.paperLight,
    );

    final barra = _barra(tester);
    final selo = _fundoDoSelo(tester, AppColors.paperLight);

    _exige(
      'preenchimento contra o trilho',
      barra.color!,
      Color.alphaBlend(barra.trackColor!, selo),
    );
  });

  testWidgets('A5 — e continua PINTANDO, com a área da barra fina', (
    tester,
  ) async {
    await _pump(
      tester,
      theme: AppTheme.light,
      superficie: AppColors.paperLight,
    );

    final pintado = tester.getSize(find.byKey(AppProgressBar.fillKey));

    expect(pintado.height, AppProgressSize.thin.height);
    expect(
      pintado.width,
      closeTo(56 * 0.4, 0.5),
      reason: 'a barra do selo tem 56px e o XP está em 40%',
    );
  });

  testWidgets('o selo é um nó só para o leitor de tela', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: LevelBadge(
              level: 7,
              progress: 0.4,
              label: 'Nv 7',
              semanticLabel: 'Nível 7 do cofre, 40% para o próximo',
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Nível 7 do cofre, 40% para o próximo'),
      findsOneWidget,
    );

    handle.dispose();
  });
}
