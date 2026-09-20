import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';

/// Contraste dos papéis do TEMA, medido e não conferido contra a constante.
///
/// Um teste que compara `unselectedLabelColor` com `AppColors.ink2Light` só
/// repete o código. Este arquivo pergunta a única coisa que importa para quem
/// lê a tela: **quantos por um?** Assim ele continua valendo quando alguém
/// ajustar um hexadecimal — e reprova na hora se o ajuste piorar.
///
/// Pisos da WCAG 2.1: 4,5:1 para texto normal, 3:1 para texto grande e para
/// elemento gráfico ou de interface essencial.
const double textoNormal = 4.5;
const double grafico = 3;

/// O que cobrar de cada tema: o tema montado e as superfícies sobre as quais
/// o texto dele aparece.
final _temas = <String, ({ThemeData theme, AppPalette palette})>{
  'claro': (theme: AppTheme.light, palette: AppPalette.light),
  'escuro': (theme: AppTheme.dark, palette: AppPalette.dark),
};

void _exige(
  String oque,
  Color tinta,
  Color fundo, {
  double piso = textoNormal,
}) {
  final razao = AppColors.contrastRatio(tinta, fundo);
  expect(
    razao,
    greaterThanOrEqualTo(piso),
    reason: '$oque: ${razao.toStringAsFixed(2)}:1, piso $piso:1',
  );
}

void main() {
  for (final entry in _temas.entries) {
    final tema = entry.value.theme;
    final palette = entry.value.palette;

    group('tema ${entry.key}', () {
      /// A2 — `ink3` é a tinta do que está DESLIGADO. Ela estava sendo usada
      /// em coisas ligadas: a aba fechada (que se clica), o placeholder (que
      /// informa o formato do campo), a borda da caixa vazia e o aro do rádio
      /// (que são a única pista de que existe um controle ali). Em papel
      /// claro `ink3` dá 2,66:1.
      test('A2 — a aba fechada é um destino, não um texto apagado', () {
        _exige(
          'unselectedLabelColor sobre papel',
          tema.tabBarTheme.unselectedLabelColor!,
          palette.paper,
        );
      });

      test('A2 — o placeholder do campo se lê', () {
        _exige(
          'hintStyle sobre o papel do campo',
          tema.inputDecorationTheme.hintStyle!.color!,
          palette.paper2,
        );
      });

      test('A2 — a borda da caixa vazia se enxerga', () {
        _exige(
          'checkbox side sobre papel',
          tema.checkboxTheme.side!.color,
          palette.paper,
          piso: grafico,
        );
      });

      test('A2 — o aro do rádio não marcado se enxerga', () {
        _exige(
          'radio fill não marcado sobre papel',
          tema.radioTheme.fillColor!.resolve(const {})!,
          palette.paper,
          piso: grafico,
        );
      });

      test('A2 — o puxador da folha se enxerga', () {
        _exige(
          'dragHandleColor sobre papel',
          tema.bottomSheetTheme.dragHandleColor!,
          palette.paper,
          piso: grafico,
        );
      });

      /// A3 — as semânticas de TEXTO. No escuro elas devolviam a cor CHEIA,
      /// a mesma que preenche pílula e barra: `danger` dava 2,83:1 sobre
      /// `paperDark`, em 103 lugares.
      for (final semantica in ['sucesso', 'aviso', 'erro']) {
          test('A3 — a tinta de $semantica se lê no papel do tema', () {
          final tinta = switch (semantica) {
            'sucesso' => palette.successText,
            'aviso' => palette.warningText,
            _ => palette.dangerText,
          };

          _exige('$semantica sobre paper', tinta, palette.paper);
          _exige('$semantica sobre paper2', tinta, palette.paper2);
          _exige('$semantica sobre background', tinta, palette.background);
        });
      }

      test('A3 — a tinta de dinheiro segue a mesma regra', () {
        _exige('valor positivo', palette.moneyInk(10), palette.paper);
        _exige('valor negativo', palette.moneyInk(-10), palette.paper);
        _exige('valor zerado', palette.moneyInk(0), palette.paper);
      });

      test('A3 — o teal de texto se lê no papel do tema', () {
        _exige('tealText sobre paper', palette.tealText, palette.paper);
      });

      /// A8 — `error` e `onError` formam um PAR: o Flutter usa a primeira
      /// como tinta sobre o papel e como fundo do botão destrutivo, com a
      /// segunda escrita por cima. O vermelho cheio não servia para nenhum
      /// dos dois no claro — 3,91:1 nos dois sentidos.
      test('A8 — o par error/onError fecha nos dois sentidos', () {
        final scheme = tema.colorScheme;
        _exige('onError sobre error', scheme.onError, scheme.error);
        _exige('error como tinta sobre papel', scheme.error, palette.paper);
        _exige(
          'onErrorContainer sobre errorContainer',
          scheme.onErrorContainer,
          scheme.errorContainer,
        );
      });

      test('A8 — a borda de campo em erro se enxerga', () {
        _exige(
          'errorBorder sobre o papel do campo',
          tema.inputDecorationTheme.errorBorder!.borderSide.color,
          palette.paper2,
          piso: grafico,
        );
      });

      test('A8 — o texto de erro do campo se lê', () {
        _exige(
          'errorStyle sobre o papel do campo',
          tema.inputDecorationTheme.errorStyle!.color!,
          palette.paper2,
        );
      });

      test('a aba aberta continua mais forte que a fechada', () {
        final aberta = AppColors.contrastRatio(
          tema.tabBarTheme.labelColor!,
          palette.paper,
        );
        final fechada = AppColors.contrastRatio(
          tema.tabBarTheme.unselectedLabelColor!,
          palette.paper,
        );
        expect(
          aberta,
          greaterThan(fechada),
          reason: 'subir a fechada não pode empatar a hierarquia',
        );
      });
    });
  }

  /// A superfície de jogo é escura nos DOIS temas, e quem escreve sobre ela
  /// entra em `AppTheme.onGame` — que é a paleta escura. Portanto é a paleta
  /// escura, e não a do tema corrente, que precisa se ler sobre `surfaceDeep`
  /// e suas irmãs.
  group('superfície de jogo', () {
    const superficies = {
      'surfaceDeep': AppColors.surfaceDeep,
      'surfaceDefault': AppColors.surfaceDefault,
    };

    superficies.forEach((nome, fundo) {
      test('A3 — as três semânticas se leem sobre $nome', () {
        _exige('sucesso sobre $nome', AppPalette.dark.successText, fundo);
        _exige('aviso sobre $nome', AppPalette.dark.warningText, fundo);
        _exige('erro sobre $nome', AppPalette.dark.dangerText, fundo);
      });

      test('a tinta e a tinta secundária se leem sobre $nome', () {
        _exige('onGame sobre $nome', AppPalette.dark.onGame, fundo);
        _exige('onGame2 sobre $nome', AppPalette.dark.onGame2, fundo);
      });
    });
  });
}
