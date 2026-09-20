import 'package:flutter/painting.dart';

/// A rampa metálica dos emblemas.
///
/// Estes hexadecimais **não** são literais soltos por descuido: são a arte da
/// vitrine de emblemas — as cinco rampas de metal (ouro, prata/platina,
/// bronze, aço) que dão volume às moldurinhas e às moedas, mais a paleta com
/// que cada categoria de badge tinge o ícone.
///
/// Por que vivem no tema e não na feature: um emblema é uma **recompensa**, e
/// recompensa é vocabulário de identidade, não de tela. A vitrine não é o
/// único lugar que mostra emblema — a conquista aparece no toast, no cartão de
/// nível e (um dia) no compartilhamento — e todos precisam do mesmo ouro.
/// Enquanto a rampa morava dentro de `features/workspace/.../badges/`, ela era
/// invisível para quem procurava "as cores do app" e ninguém conseguia
/// responder quantos dourados o Funances tinha.
///
/// O que ela **não** é: papel de cor. Nada aqui responde "qual é a tinta
/// secundária?" — para isso existe [AppPalette] (`context.palette`). Um metal
/// é sempre o mesmo metal nos dois temas: ouro não clareia no escuro.
///
/// Os valores são exatamente os da arte original, deliberadamente. Corrigir
/// cor de emblema é uma decisão de design com dono, e não cabe numa passada de
/// tokenização.
abstract final class AppBadgePalette {
  // ─── Tinta neutra da arte ───────────────────────────────────────────────
  //
  // Branco e preto puros aqui são **luz e sombra**, não texto e fundo: o
  // brilho especular no topo do domo, o realce debossado do ícone bloqueado e
  // a sombra projetada da peça. São sempre usados com alfa.

  /// Brilho especular: realce de vidro, raios de fundo, domo.
  static const Color specular = Color(0xFFFFFFFF);

  /// Sombra projetada da peça e do relevo do ícone.
  static const Color shadow = Color(0xFF000000);

  // ─── Paleta por categoria de badge ──────────────────────────────────────
  //
  // Tinge o ícone dentro da moeda. A escolha dentro de cada lista é
  // determinística pelo id do badge — dá variedade sem manter 67 cores à mão.

  static const List<Color> categoryAdvanced = <Color>[
    Color(0xFF7E57C2),
    Color(0xFF1E88E5),
    Color(0xFF00897B),
    Color(0xFFF9A825),
    Color(0xFFD81B60),
  ];

  static const List<Color> categoryFirstSteps = <Color>[
    Color(0xFF7C4DFF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
  ];

  static const List<Color> categoryConsistency = <Color>[
    Color(0xFFFDD835),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFF0288D1),
  ];

  static const List<Color> categorySavings = <Color>[
    Color(0xFFF57C00),
    Color(0xFF26C6DA),
    Color(0xFFE91E63),
    Color(0xFF43A047),
  ];

  static const List<Color> categoryGoals = <Color>[
    Color(0xFF5C6BC0),
    Color(0xFF8E24AA),
    Color(0xFFE64A19),
    Color(0xFF0097A7),
  ];

  static const List<Color> categoryTeam = <Color>[
    Color(0xFF039BE5),
    Color(0xFF00796B),
    Color(0xFF558B2F),
    Color(0xFF7B1FA2),
  ];

  /// Badge que o app não conhece (catálogo mais novo que a versão instalada).
  static const List<Color> categoryUnknown = <Color>[Color(0xFF78909C)];

  // ─── A moeda (disco interno, `MetallicIcon3D`) ──────────────────────────
  //
  // A regra da arte é o contraste entre metais: moeda de platina dentro de
  // moldura de ouro, moeda de ouro dentro de moldura de prata, moeda de aço
  // dentro de moldura de bronze. Cada rampa vai do especular ao pé de sombra.

  /// Moeda de platina do emblema avançado.
  static const List<Color> coinPlatinum = <Color>[
    Color(0xFFFFFFFF), // brilho especular
    Color(0xFFF1F5F9), // prata platinada
    Color(0xFF94A3B8), // prata fosca
    Color(0xFF475569), // sombra de aço
  ];

  /// Moeda de ouro do emblema simples de 75 XP ou mais.
  static const List<Color> coinGold = <Color>[
    Color(0xFFFFFDF0), // realce de ouro
    Color(0xFFFBBF24), // corpo de ouro
    Color(0xFFCA8A04), // ouro médio
    Color(0xFF713F12), // sombra de ouro escuro
  ];

  /// Moeda de aço do emblema simples comum.
  static const List<Color> coinSteel = <Color>[
    Color(0xFFFFFFFF), // branco especular
    Color(0xFFECEFF1), // prata
    Color(0xFF90A4AE), // aço médio
    Color(0xFF37474F), // sombra de aço escuro
  ];

  /// Aro da moeda, pelo metal da moldura que a emoldura.
  static const Color coinRimGold = Color(0xFFFFD54F);
  static const Color coinRimSilver = Color(0xFFCBD5E1);
  static const Color coinRimBronze = Color(0xFFC2410C);

  /// Ícone de um emblema **bloqueado**: ardósia escura, para se destacar sobre
  /// a moeda dessaturada. Não é tinta de texto — é o gravado em relevo.
  static const List<Color> lockedIcon = <Color>[
    Color(0xFF475569), // slate 600
    Color(0xFF0F172A), // slate 900
  ];

  // ─── A moldura (`BadgeShapePainter`) ────────────────────────────────────

  /// Aura em volta da peça desbloqueada, pelo metal.
  static const Color auraGold = Color(0xFFFFA000);
  static const Color auraSilver = Color(0xFFB0BEC5);
  static const Color auraBronze = Color(0xFFD84315);

  /// Preenchimento da moldura de ouro (emblema avançado).
  static const List<Color> frameGold = <Color>[
    Color(0xFFFFFDE7), // realce especular
    Color(0xFFFFD54F), // corpo dourado
    Color(0xFFFF8F00), // âmbar profundo
    Color(0xFFD97706), // sombra dourada
  ];

  /// Preenchimento da moldura de prata.
  static const List<Color> frameSilver = <Color>[
    Color(0xFFFFFFFF), // branco especular
    Color(0xFFECEFF1), // prata clara
    Color(0xFF90A4AE), // aço médio
    Color(0xFF475569), // cinza de sombra
  ];

  /// Preenchimento da moldura de bronze.
  static const List<Color> frameBronze = <Color>[
    Color(0xFFFFEDD5), // clarão de cobre
    Color(0xFFEA580C), // corpo de cobre
    Color(0xFF9A3412), // bronze médio
    Color(0xFF451A03), // marrom de sombra
  ];

  /// Anel concêntrico interno da moldura de ouro. Prata e bronze usam
  /// [specular].
  static const Color innerRingGold = Color(0xFFFFE082);

  /// Chanfro externo da moldura de ouro.
  static const List<Color> bevelGold = <Color>[
    Color(0xFFFFF9C4), // reflexo de ouro branco
    Color(0xFFFFD54F), // aro dourado
    Color(0xFFFF8F00), // borda âmbar
    Color(0xFFE65100), // sombra de ouro escuro
  ];

  /// Chanfro externo da moldura de prata.
  static const List<Color> bevelSilver = <Color>[
    Color(0xFFFFFFFF), // reflexo puro
    Color(0xFFCFD8DC), // aço acinzentado
    Color(0xFF78909C), // aresta de prata
    Color(0xFF37474F), // cinza de sombra
  ];

  /// Chanfro externo da moldura de bronze.
  static const List<Color> bevelBronze = <Color>[
    Color(0xFFFFE0B2), // clarão de bronze
    Color(0xFFD84315), // borda de cobre
    Color(0xFF5D4037), // aresta marrom
    Color(0xFF2D1510), // sombra de bronze
  ];
}
