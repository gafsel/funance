import 'package:flutter/widgets.dart';

/// As três larguras do app.
///
/// Antes eram oito valores literais (500, 600, 700, 800, 900, 1200) espalhados
/// por vinte arquivos, com operadores que não concordavam entre si — e a faixa
/// de 801 a 900px, onde a Home já pagava o `NavigationRail` mas o conteúdo
/// ainda não reorganizava, era a pior tela do app. Agora há um corte só.
enum AppLayout {
  /// Celular e janelas estreitas. Coluna única, bottom bar.
  compact,

  /// Tablet e janela média. Duas colunas onde fizer sentido, ainda bottom bar.
  medium,

  /// Desktop. `NavigationRail`, conteúdo com largura máxima de leitura.
  wide;

  bool get isCompact => this == AppLayout.compact;
  bool get isMedium => this == AppLayout.medium;
  bool get isWide => this == AppLayout.wide;

  /// `true` quando a navegação é lateral (rail) em vez de inferior.
  bool get usesRail => this == AppLayout.wide;

  /// Largura máxima de um bloco de conteúdo. Acima disso o texto vira linha de
  /// duzentos caracteres e ninguém lê.
  double get contentMaxWidth => switch (this) {
    AppLayout.compact => double.infinity,
    AppLayout.medium => 720,
    AppLayout.wide => 1040,
  };

  /// Largura máxima de um formulário ou de uma coluna de leitura.
  double get readingMaxWidth => switch (this) {
    AppLayout.compact => double.infinity,
    AppLayout.medium => 560,
    AppLayout.wide => 560,
  };

  /// Número de colunas sugerido para grades de cartões.
  int get columns => switch (this) {
    AppLayout.compact => 1,
    AppLayout.medium => 2,
    AppLayout.wide => 3,
  };
}

abstract final class AppBreakpoints {
  /// Abaixo daqui é [AppLayout.compact].
  static const double medium = 600;

  /// A partir daqui é [AppLayout.wide].
  static const double wide = 1000;

  /// Resolve o layout a partir de uma largura em pixels lógicos.
  static AppLayout of(double width) {
    if (width >= wide) return AppLayout.wide;
    if (width >= medium) return AppLayout.medium;
    return AppLayout.compact;
  }
}

extension AppLayoutContext on BuildContext {
  /// O layout da **janela**.
  ///
  /// Cuidado: isto lê o `MediaQuery`, ou seja, a janela inteira. Para decidir
  /// o layout de um painel que divide a tela com um `NavigationRail`, use um
  /// `LayoutBuilder` e [AppBreakpoints.of] com a largura real das constraints
  /// — foi exatamente o erro que fazia uma janela de 1000px renderizar uma
  /// tabela num painel de 800.
  AppLayout get layout => AppBreakpoints.of(MediaQuery.sizeOf(this).width);
}

extension AppLayoutConstraints on BoxConstraints {
  /// O layout do **painel**, medido pelas constraints recebidas.
  AppLayout get layout => AppBreakpoints.of(maxWidth);
}
