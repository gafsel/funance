import 'package:flutter/widgets.dart';

/// Escala de espaçamento de 4pt.
///
/// O app já praticava 4/8/12/16/24/32 — só não tinha nome, e por isso convivia
/// com `all(16)` e `all(16.0)` como se fossem coisas diferentes. Aqui a escala
/// ganha nome e mais dois degraus para respiro de seção.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;

  /// Margem lateral padrão de qualquer tela. Vale em todas as larguras: o que
  /// muda com a viewport é a largura máxima do conteúdo, não o gutter.
  static const double gutter = md;

  // --- Atalhos de `EdgeInsets` para os casos mais repetidos ---

  static const EdgeInsets allXxs = EdgeInsets.all(xxs);
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets hMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets hLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets vXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets vSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets vMd = EdgeInsets.symmetric(vertical: md);

  /// Respiro interno de um tile de lista.
  static const EdgeInsets tile = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Respiro interno de um cartão.
  static const EdgeInsets card = EdgeInsets.all(md);

  // --- Atalhos de `SizedBox` (os 282 `SizedBox(height:` do app) ---

  static const SizedBox gapXxs = SizedBox(height: xxs, width: xxs);
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);

  /// Altura reservada no fim de um scroll para o conteúdo não morrer embaixo
  /// da bottom bar com o botão de lançar.
  static const double bottomBarSafeArea = 96;
}
