import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_chip.dart';

/// A4 — a pílula dourada era a única ilegível.
///
/// `StatusPill` pintava fundo, borda, ícone e texto com UMA cor. Para as
/// semânticas isso funciona: a tinta de texto diluída a 12% dá um fundo
/// discreto do mesmo matiz. Para a recompensa não funciona, porque ouro é
/// cor de preenchimento: `goldDeep` como texto sobre a própria pílula dava
/// 2,23:1. A pílula que celebra era a que não dava para ler.
///
/// A correção separa os dois papéis — `fill` pinta, `ink` escreve — em vez de
/// escolher entre "pílula dourada" e "pílula legível".

/// A cor de fundo que a pílula realmente pinta, já composta sobre o papel.
Color _fundoDaPilula(WidgetTester tester, Color papel) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(StatusPill),
      matching: find.byType(Container),
    ),
  );
  final decoration = container.decoration! as BoxDecoration;
  return Color.alphaBlend(decoration.color!, papel);
}

Color _tinta(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

Future<void> _pump(
  WidgetTester tester,
  Widget pill, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: pill)),
    ),
  );
}

void main() {
  final temas = {
    'claro': (theme: AppTheme.light, palette: AppPalette.light),
    'escuro': (theme: AppTheme.dark, palette: AppPalette.dark),
  };

  temas.forEach((nome, tema) {
    group('StatusPill no tema $nome', () {
      for (final tone in StatusTone.values) {
        testWidgets('A4 — a pílula ${tone.name} se lê sobre si mesma', (
          tester,
        ) async {
          await _pump(
            tester,
            StatusPill(label: 'XP', tone: tone),
            theme: tema.theme,
          );

          final razao = AppColors.contrastRatio(
            _tinta(tester, 'XP'),
            _fundoDaPilula(tester, tema.palette.paper),
          );

          expect(
            razao,
            greaterThanOrEqualTo(4.5),
            reason:
                'pílula ${tone.name}: ${razao.toStringAsFixed(2)}:1 sobre o '
                'próprio fundo',
          );
        });
      }

      testWidgets('A4 — a pílula de recompensa continua DOURADA', (
        tester,
      ) async {
        await _pump(
          tester,
          const StatusPill(label: 'XP', tone: StatusTone.reward),
          theme: tema.theme,
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(StatusPill),
            matching: find.byType(Container),
          ),
        );
        final decoration = container.decoration! as BoxDecoration;

        expect(
          decoration.color,
          AppColors.gold.withValues(alpha: 0.12),
          reason:
              'a saída fácil seria pintar o fundo com a tinta escura e perder '
              'o ouro; a pílula que celebra tem de parecer que celebra',
        );
        expect(decoration.border, isNotNull);
      });
    });
  });

  testWidgets('a cor explícita continua mandando em tudo', (tester) async {
    await _pump(
      tester,
      const StatusPill(
        label: 'Moradia',
        tone: StatusTone.reward,
        color: AppColors.violet,
      ),
      theme: AppTheme.light,
    );

    expect(_tinta(tester, 'Moradia'), AppColors.violet);
    expect(
      _fundoDaPilula(tester, AppColors.paperLight),
      Color.alphaBlend(
        AppColors.violet.withValues(alpha: 0.12),
        AppColors.paperLight,
      ),
      reason: 'quando o assunto da pílula é a própria cor, ela vale inteira',
    );
  });

  /// M1 — a pílula sobre superfície de JOGO.
  ///
  /// A tinta semântica é feita para papel. Sobre `surfaceRaised` — a mais
  /// clara das superfícies de jogo, e onde `AppTheme.onGame` põe o `paper2` —
  /// ela dá 3,64:1 a 4,21:1, abaixo do piso de TEXTO. O teste antigo cobrava
  /// 3:1 ali, como se a pílula fosse um elemento gráfico.
  group('StatusPill sobre superfície de jogo', () {
    for (final tone in StatusTone.values) {
      testWidgets('M1 — o texto de ${tone.name} chega a 4,5:1', (
        tester,
      ) async {
        await _pump(
          tester,
          StatusPill(label: 'XP', tone: tone, onGame: true),
          theme: AppTheme.light,
        );

        final razao = AppColors.contrastRatio(
          _tinta(tester, 'XP'),
          _fundoDaPilula(tester, AppColors.surfaceRaised),
        );

        expect(
          razao,
          greaterThanOrEqualTo(4.5),
          reason: '${tone.name}: ${razao.toStringAsFixed(2)}:1',
        );
      });
    }

    testWidgets('M1 — e o TOM continua no fundo, não some com a tinta', (
      tester,
    ) async {
      await _pump(
        tester,
        const StatusPill(
          label: 'Atrasado',
          tone: StatusTone.danger,
          onGame: true,
        ),
        theme: AppTheme.dark,
      );

      final decoration =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(StatusPill),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      expect(
        decoration.color,
        AppPalette.dark.dangerText.withValues(alpha: 0.12),
        reason:
            'clarear as três tintas até passarem sobre jogo faria o vermelho '
            'virar pêssego e o laranja virar amarelo; o tom fica no fundo',
      );
      expect(_tinta(tester, 'Atrasado'), AppColors.inkInverse);
    });

    testWidgets('M1 — sobre papel nada muda', (tester) async {
      await _pump(
        tester,
        const StatusPill(label: 'Atrasado', tone: StatusTone.danger),
        theme: AppTheme.light,
      );

      expect(_tinta(tester, 'Atrasado'), AppPalette.light.dangerText);
    });
  });

  group('AppChip', () {
    /// baixo — `onDeleted` só chegava ao `Chip` estático. Um chip
    /// selecionável com `onDeleted` compilava, parecia certo na leitura do
    /// código e simplesmente não desenhava o "x": o filtro de transações
    /// escolhe E remove, e a segunda metade não existia.
    testWidgets('o "x" funciona também no chip selecionável', (tester) async {
      var removeu = false;

      await _pump(
        tester,
        AppChip(
          label: 'Moradia',
          selected: true,
          onSelected: (_) {},
          onDeleted: () => removeu = true,
        ),
        theme: AppTheme.light,
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(removeu, isTrue);
    });

    testWidgets('sem onDeleted não desenha um "x" que não faz nada', (
      tester,
    ) async {
      await _pump(
        tester,
        AppChip(label: 'Moradia', selected: true, onSelected: (_) {}),
        theme: AppTheme.light,
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('M10 — escolher devolve o novo estado', (tester) async {
      bool? escolhido;

      await _pump(
        tester,
        AppChip(
          label: 'Moradia',
          onSelected: (value) => escolhido = value,
        ),
        theme: AppTheme.light,
      );

      await tester.tap(find.text('Moradia'));
      expect(escolhido, isTrue);
    });

    testWidgets('M10 — sem onSelected é um rótulo, não um filtro', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppChip(label: 'Moradia'),
        theme: AppTheme.light,
      );

      expect(find.byType(FilterChip), findsNothing);
      expect(find.byType(Chip), findsOneWidget);
    });
  });

  testWidgets('o ícone da pílula usa a tinta, não a cor de fundo', (
    tester,
  ) async {
    await _pump(
      tester,
      const StatusPill(
        label: 'Nível 7',
        tone: StatusTone.reward,
        icon: Icons.stars,
      ),
      theme: AppTheme.light,
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.stars)).color,
      AppPalette.light.rewardText,
    );
  });
}
