import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Os papéis de cor já resolvidos para o brilho corrente.
///
/// [AppColors] guarda hexadecimais; esta extensão guarda *decisões*. Um widget
/// nunca pergunta "qual é o cinza claro?", pergunta "qual é a tinta
/// secundária?" — e a resposta muda entre claro e escuro sem que ele saiba.
///
/// Uso: `context.palette.ink2`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.paper,
    required this.paper2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
  });

  /// Tema claro: papel branco sobre fundo levemente azulado.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: AppColors.backgroundLight,
    paper: AppColors.paperLight,
    paper2: AppColors.paper2Light,
    ink: AppColors.inkLight,
    ink2: AppColors.ink2Light,
    ink3: AppColors.ink3Light,
    line: AppColors.lineLight,
  );

  /// Tema escuro: o papel continua sendo a superfície plana de leitura, só que
  /// em turquesa. O que separa "jogo" de "dado" aqui é o ouro e o gradiente,
  /// não o brilho — no escuro não existe claro para contrastar.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: AppColors.backgroundDark,
    paper: AppColors.paperDark,
    paper2: AppColors.paper2Dark,
    ink: AppColors.inkDark,
    ink2: AppColors.ink2Dark,
    ink3: AppColors.ink3Dark,
    line: AppColors.lineDark,
  );

  final Brightness brightness;

  /// Fundo da tela.
  final Color background;

  /// Papel principal: cartão, lista, tabela, formulário.
  final Color paper;

  /// Papel secundário: faixa alternada, bloco agrupado, estado vazio.
  final Color paper2;

  /// Tinta principal.
  final Color ink;

  /// Tinta secundária: subtítulo, legenda, valor de apoio.
  final Color ink2;

  /// Tinta terciária: placeholder, ícone desligado, texto desabilitado.
  final Color ink3;

  /// Divisor e contorno de 1px.
  final Color line;

  bool get isDark => brightness == Brightness.dark;

  /// Tinta legível sobre uma superfície de jogo (escura), em qualquer tema.
  Color get onGame => AppColors.inkInverse;

  /// Tinta secundária sobre uma superfície de jogo.
  Color get onGame2 => AppColors.inkInverse2;

  /// Teal utilizável como *texto* na superfície corrente. O teal vivo só é
  /// legível sobre escuro; no claro ele precisa do parente escuro.
  Color get tealText => isDark ? AppColors.teal : AppColors.tealInk;

  /// Verde, laranja e vermelho já ajustados para virar TEXTO sobre a
  /// superfície corrente.
  ///
  /// No escuro estes getters devolviam a cor CHEIA — a mesma que preenche
  /// pílula, barra e ícone grande. Cor de preenchimento não é cor de texto:
  /// `danger` sobre `paperDark` dá 2,83:1, e era assim que os 103 avisos de
  /// erro do app apareciam no tema escuro. Agora cada semântica tem a sua
  /// tinta escura, medida sobre `paper` e sobre `surfaceDeep`.
  Color get successText =>
      isDark ? AppColors.successInkDark : AppColors.successInk;
  Color get warningText =>
      isDark ? AppColors.warningInkDark : AppColors.warningInk;
  Color get dangerText =>
      isDark ? AppColors.dangerInkDark : AppColors.dangerInk;

  /// Tinta de RECOMPENSA na superfície corrente: XP, nível, missão, badge.
  ///
  /// O ouro vivo (`gold`) é cor de PREENCHIMENTO — botão, aro, barra cheia —
  /// e só se lê sobre escuro: sobre papel claro ele dá 1,52:1. Quem precisa
  /// escrever "é jogo" numa tela de papel usa esta tinta, que vale 13,37:1
  /// no claro e 6,80:1 no escuro.
  ///
  /// Sobre uma superfície de jogo o ouro vivo continua certo — ali a regra é
  /// `palette.onGame`, não esta.
  Color get rewardText => isDark ? AppColors.gold : AppColors.goldInk;

  /// Cor de um valor monetário pelo sinal. Zero é neutro de propósito: um
  /// saldo zerado não é uma boa nem uma má notícia.
  Color moneyInk(num value) {
    if (value > 0) return successText;
    if (value < 0) return dangerText;
    return ink2;
  }

  /// Cor do pool do 50/30/20 pelo índice (0 = 50%, 1 = 30%, 2 = 20%).
  static const List<Color> pools = <Color>[
    AppColors.pool50,
    AppColors.pool30,
    AppColors.pool20,
  ];

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? paper,
    Color? paper2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
  }) => AppPalette(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    paper: paper ?? this.paper,
    paper2: paper2 ?? this.paper2,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    line: line ?? this.line,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Os papéis de cor do tema corrente.
  ///
  /// Cai no tema claro se a extensão não estiver registrada — o que só
  /// acontece num teste que monta um `ThemeData` cru.
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}
