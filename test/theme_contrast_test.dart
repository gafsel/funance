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
}
