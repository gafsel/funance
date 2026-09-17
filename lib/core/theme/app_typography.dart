import 'package:flutter/material.dart';

/// Tipografia do Funances: Fredoka no display, Inter no texto.
///
/// As duas fontes são empacotadas em `assets/fonts/` e declaradas no
/// `pubspec.yaml`. Nada é buscado na rede em tempo de execução — o app precisa
/// abrir offline e o macOS em sandbox não pede fonte a ninguém.
///
/// A escala existe porque antes não existia nenhuma: o `textTheme` do tema
/// antigo não definia **um único `fontSize`**, e por isso o app tinha 179
/// `TextStyle(` inline e 29 `titleMedium.copyWith(bold)` — cem por cento dos
/// `copyWith` de `titleMedium` adicionavam negrito, o que quer dizer que o
/// token é que estava errado. Aqui `titleMedium` já nasce semibold.
abstract final class AppTypography {
  /// Família de display: títulos, números grandes, patentes, nível.
  static const String display = 'Fredoka';

  /// Família de texto: tudo que se lê em linha.
  static const String body = 'Inter';

  /// Pilha de reserva. Se por algum motivo o asset não carregar, o app cai em
  /// algo sensato em vez de num quadrado vazio.
  static const List<String> displayFallback = <String>[
    'Inter',
    'SF Pro Rounded',
    'Roboto',
  ];

  static const List<String> bodyFallback = <String>[
    'SF Pro Text',
    'Roboto',
    'Helvetica Neue',
  ];

  /// Algarismos de largura fixa. Obrigatório em extrato, fatura, tabela e
  /// qualquer coluna de valores: sem isso os números dançam quando mudam.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static TextStyle _display(double size, double height, FontWeight weight) =>
      TextStyle(
        fontFamily: display,
        fontFamilyFallback: displayFallback,
        fontSize: size,
        height: height / size,
        fontWeight: weight,
        letterSpacing: size >= 32 ? -0.5 : -0.2,
      );

  static TextStyle _body(
    double size,
    double height,
    FontWeight weight, {
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: body,
    fontFamilyFallback: bodyFallback,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );

  /// A escala aprovada: 40 / 32 / 24 / 20 / 16 / 14 / 12 / 11.
  ///
  /// Os degraus intermediários que o Material exige (`displaySmall`,
  /// `headlineLarge`, `titleSmall`, `labelLarge`, `labelMedium`) reaproveitam
  /// os mesmos tamanhos — não há um nono tamanho escondido.
  static TextTheme textTheme(Color ink) => TextTheme(
    displayLarge: _display(40, 44, FontWeight.w700),
    displayMedium: _display(32, 38, FontWeight.w700),
    displaySmall: _display(24, 30, FontWeight.w600),
    headlineLarge: _display(32, 38, FontWeight.w600),
    headlineMedium: _display(24, 30, FontWeight.w600),
    headlineSmall: _display(24, 30, FontWeight.w600),
    titleLarge: _display(20, 26, FontWeight.w600),
    titleMedium: _body(16, 22, FontWeight.w600),
    titleSmall: _body(14, 20, FontWeight.w600),
    bodyLarge: _body(16, 24, FontWeight.w400),
    bodyMedium: _body(14, 20, FontWeight.w400),
    bodySmall: _body(12, 16, FontWeight.w400),
    labelLarge: _body(14, 20, FontWeight.w600, letterSpacing: 0.1),
    labelMedium: _body(12, 16, FontWeight.w600, letterSpacing: 0.2),
    labelSmall: _body(11, 14, FontWeight.w600, letterSpacing: 0.4),
  ).apply(bodyColor: ink, displayColor: ink);

  /// Corpo de 14, para quando o `textTheme` não estiver disponível (um
  /// `ThemeData` cru montado num teste, por exemplo).
  static TextStyle body14(Color ink) =>
      _body(14, 20, FontWeight.w400).copyWith(color: ink);

  /// Número grande de destaque — saldo do mês, valor da meta, total da fatura.
  static TextStyle hero(Color ink) => _display(
    32,
    38,
    FontWeight.w700,
  ).copyWith(color: ink, fontFeatures: tabular);

  // --- Marcação de texto corrido ---
  //
  // São tokens de tipografia de verdade, e não estilo solto: "negrito",
  // "itálico" e "código" são papéis do texto, não decisões de tela. Ficam
  // aqui para que o renderizador de Markdown do coaching não precise
  // declará-los inline — e para que trocar a fonte monoespaçada um dia seja
  // uma linha, não uma caçada.

  /// Negrito.
  static const TextStyle strong = TextStyle(fontWeight: FontWeight.w700);

  /// Itálico.
  static const TextStyle emphasis = TextStyle(fontStyle: FontStyle.italic);

  /// Negrito e itálico.
  static const TextStyle strongEmphasis = TextStyle(
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
  );

  /// Trecho de código.
  static const TextStyle code = TextStyle(fontFamily: 'monospace');

  /// Contador de nível, XP e patente: display, compacto, tabular.
  static TextStyle counter(Color ink) => _display(
    20,
    26,
    FontWeight.w700,
  ).copyWith(color: ink, fontFeatures: tabular);
}

extension TabularText on TextStyle {
  /// Liga algarismos tabulares neste estilo.
  ///
  /// `theme.textTheme.bodyMedium!.tabularFigures` é a forma curta de dizer
  /// "isto é uma coluna de dinheiro".
  TextStyle get tabularFigures => copyWith(fontFeatures: AppTypography.tabular);
}
