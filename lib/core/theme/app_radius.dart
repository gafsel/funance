import 'package:flutter/widgets.dart';

/// Raios de borda: quatro papéis, quatro valores, mais a pílula.
///
/// O app tinha onze valores (2, 4, 6, 8, 10, 12, 16, 20, 24, 25, 30) para
/// quatro papéis reais. A regra agora é por papel, não por gosto:
///
/// * [xs] — traço fino: barra de progresso, sublinhado, faixa de 4px.
/// * [sm] — controle: campo de texto, chip retangular, thumbnail.
/// * [md] — botão e tile.
/// * [lg] — cartão, folha e diálogo.
/// * [pill] — qualquer coisa que seja uma pílula ou um círculo.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));

  /// Topo arredondado de uma bottom sheet.
  static const BorderRadius brSheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}
