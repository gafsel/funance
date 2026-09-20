import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/theme/app_typography.dart';

/// D5 — a família de fonte de CADA slot, nos dois temas.
///
/// O dono relatou telas com "a fonte errada" no tema claro. A investigação
/// achou duas causas distintas, e nenhuma delas era o `textTheme` principal:
///
/// 1. o 50-30-20 trocava a tipografia de aba do design system por `bodySmall`
///    — mesma família, outro peso e outro tamanho (ver
///    `planning_503020_tabs_test.dart`);
/// 2. o `primaryTextTheme` PERDIA o Fredoka. `ThemeData` aplica o
///    `fontFamily` recebido sobre a tipografia padrão do Material e só depois
///    faz `merge` com o que passamos; como não passávamos `primaryTextTheme`,
///    todos os quinze slots dele saíam em Inter — inclusive `displayLarge`.
///
/// Este arquivo é a rede que impede a terceira vez. Ele percorre os quinze
/// slots, nos dois temas e nos dois `TextTheme` do tema, e cobra a família
/// pelo PAPEL do slot:
///
/// - display, headline e `titleLarge` são de display → Fredoka;
/// - `titleMedium` para baixo é texto em linha → Inter.
///
/// `titleMedium` e `titleSmall` serem Inter é decisão, não descuido: são
/// títulos de LINHA (item de lista, rótulo de campo), e lá o Fredoka
/// arredondado compete com o dado.

/// Os quinze slots, com a família que cada papel exige.
Map<String, ({TextStyle? style, String familia})> _slots(TextTheme t) => {
  'displayLarge': (style: t.displayLarge, familia: AppTypography.display),
  'displayMedium': (style: t.displayMedium, familia: AppTypography.display),
  'displaySmall': (style: t.displaySmall, familia: AppTypography.display),
  'headlineLarge': (style: t.headlineLarge, familia: AppTypography.display),
  'headlineMedium': (style: t.headlineMedium, familia: AppTypography.display),
  'headlineSmall': (style: t.headlineSmall, familia: AppTypography.display),
  'titleLarge': (style: t.titleLarge, familia: AppTypography.display),
  'titleMedium': (style: t.titleMedium, familia: AppTypography.body),
  'titleSmall': (style: t.titleSmall, familia: AppTypography.body),
  'bodyLarge': (style: t.bodyLarge, familia: AppTypography.body),
  'bodyMedium': (style: t.bodyMedium, familia: AppTypography.body),
  'bodySmall': (style: t.bodySmall, familia: AppTypography.body),
  'labelLarge': (style: t.labelLarge, familia: AppTypography.body),
  'labelMedium': (style: t.labelMedium, familia: AppTypography.body),
  'labelSmall': (style: t.labelSmall, familia: AppTypography.body),
};

void main() {
  final temas = {'claro': AppTheme.light, 'escuro': AppTheme.dark};

  for (final tema in temas.entries) {
    group('tipografia do tema ${tema.key}', () {
      final textThemes = {
        'textTheme': tema.value.textTheme,
        'primaryTextTheme': tema.value.primaryTextTheme,
      };

      for (final qual in textThemes.entries) {
        _slots(qual.value).forEach((nome, esperado) {
          test('${qual.key}.$nome é ${esperado.familia}', () {
            expect(
              esperado.style,
              isNotNull,
              reason: 'slot sem estilo cai na fonte padrão da plataforma',
            );
            expect(
              esperado.style!.fontFamily,
              esperado.familia,
              reason:
                  '${qual.key}.$nome perdeu a família e desenha com outra '
                  'fonte',
            );
            expect(
              esperado.style!.fontSize,
              isNotNull,
              reason: 'sem tamanho o slot herda o 14 do Material',
            );
            expect(
              esperado.style!.fontFamilyFallback,
              isNotEmpty,
              reason:
                  'sem pilha de reserva, um asset que não carregue vira '
                  'quadrado vazio',
            );
          });
        });
      }

      test('a tinta do textTheme é a do tema', () {
        final esperada = tema.key == 'claro'
            ? AppColors.inkLight
            : AppColors.inkDark;
        expect(tema.value.textTheme.bodyMedium?.color, esperada);
        expect(tema.value.textTheme.displayLarge?.color, esperada);
      });

      test('a tinta do primaryTextTheme é a de superfície de jogo', () {
        expect(
          tema.value.primaryTextTheme.bodyMedium?.color,
          AppColors.inkInverse,
          reason:
              'primaryTextTheme escreve sobre a cor primária, que é escura '
              'nos dois temas',
        );
      });
    });
  }

  testWidgets('um texto sem estilo herda Inter, não a fonte da plataforma', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('dado')),
      ),
    );

    final estilo = DefaultTextStyle.of(
      tester.element(find.text('dado')),
    ).style;

    expect(estilo.fontFamily, AppTypography.body);
  });
}
