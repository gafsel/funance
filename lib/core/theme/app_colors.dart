import 'package:flutter/material.dart';

/// Paleta bruta da identidade "Cofre Dourado com superfícies de papel".
///
/// Aqui só moram constantes: são os hexadecimais aprovados, sem nenhuma
/// decisão de tema. Quem precisa de "a cor do texto secundário **agora**"
/// não usa esta classe — usa [AppPalette] via `context.palette`, que resolve
/// o papel para o brilho corrente. `AppColors` existe para dois casos:
/// alimentar a construção dos temas e nomear cores que são iguais nos dois
/// modos (ouro, teal, semânticas, pools).
///
/// A linguagem da identidade: **onde está escuro, você joga; onde está claro,
/// você lê.** As superfícies `surfaceDeep/Default/Raised` são as do jogo e não
/// mudam entre claro e escuro — um bloco de Jornada é escuro nos dois temas.
/// As superfícies de papel (`paper*`) são as de dados e mudam, porque leitura
/// densa precisa acompanhar a preferência do sistema.
abstract final class AppColors {
  // --- Superfícies de jogo (constantes nos dois temas) ---

  /// Fundo profundo: a base do cofre. Heróis, onboarding, cabeçalhos de
  /// detalhe, blocos de Jornada.
  static const Color surfaceDeep = Color(0xFF0E3440);

  /// Superfície padrão sobre o fundo profundo.
  static const Color surfaceDefault = Color(0xFF12414F);

  /// Superfície elevada: cartões dentro de um bloco escuro.
  static const Color surfaceRaised = Color(0xFF1B5566);

  /// Texto e ícones sobre superfície de jogo.
  static const Color inkInverse = Color(0xFFF7FAFB);

  /// Texto secundário sobre superfície de jogo.
  static const Color inkInverse2 = Color(0xFFB7CDD3);

  // --- Superfícies de papel (dados) — variante clara ---

  /// Fundo do app no tema claro.
  static const Color backgroundLight = Color(0xFFF2F6F7);

  /// Papel branco: cartões, listas, tabelas, formulários.
  static const Color paperLight = Color(0xFFFFFFFF);

  /// Papel creme: faixas alternadas, blocos agrupados, estados vazios.
  static const Color paper2Light = Color(0xFFFBF7EF);

  static const Color inkLight = Color(0xFF0A2329);
  static const Color ink2Light = Color(0xFF4F6B73);
  static const Color ink3Light = Color(0xFF8AA3AA);
  static const Color lineLight = Color(0xFFD6E1E4);

  // --- Superfícies de papel (dados) — variante escura ---

  /// Fundo do app no tema escuro.
  static const Color backgroundDark = Color(0xFF0B2A34);

  /// Papel no escuro. Continua sendo "papel" porque é a superfície plana de
  /// leitura: o que separa jogo de dado no tema escuro é o ouro e o
  /// gradiente, não o brilho.
  static const Color paperDark = Color(0xFF12414F);
  static const Color paper2Dark = Color(0xFF163F4A);

  static const Color inkDark = Color(0xFFF7FAFB);
  static const Color ink2Dark = Color(0xFFB7CDD3);
  static const Color ink3Dark = Color(0xFF8AA3AA);
  static const Color lineDark = Color(0xFF24525F);

  // --- Acentos (iguais nos dois temas) ---

  /// Ouro: ação primária e recompensa. É o único acento que celebra.
  static const Color gold = Color(0xFFF5C518);

  /// Texto sobre ouro.
  static const Color goldInk = Color(0xFF3A2E00);

  /// Ouro envelhecido, para traço, ícone e aro de moeda sobre papel claro.
  /// Não serve como cor de texto pequeno — para isso existe [goldInk].
  static const Color goldDeep = Color(0xFFD4A017);

  /// Teal: ação secundária, links, progresso final.
  static const Color teal = Color(0xFF2DD4C4);

  /// Teal escuro, legível sobre papel claro.
  static const Color tealInk = Color(0xFF0F6E7E);

  /// Violeta: bônus e especiais. Nunca erro.
  static const Color violet = Color(0xFF8E5BD9);

  // --- Semânticas ---

  static const Color success = Color(0xFF3FB950);
  static const Color successInk = Color(0xFF1B6B32);
  static const Color warning = Color(0xFFFF8A3D);
  static const Color warningInk = Color(0xFF8A4B00);

  /// Erro **e** destrutivo: um token só. Antes eram quatro vermelhos
  /// concorrentes (e um roxo no `ColorScheme.error`).
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerInk = Color(0xFF7A1418);

  // --- Pools do 50/30/20 ---

  /// 50% — essenciais.
  static const Color pool50 = Color(0xFF3D93A8);

  /// 30% — conforto.
  static const Color pool30 = Color(0xFFE8A33D);

  /// 20% — futuro.
  static const Color pool20 = Color(0xFF5FB36A);

  // --- Progresso ---

  static const Color progressStart = Color(0xFF86E07A);
  static const Color progressEnd = Color(0xFF2DD4C4);

  /// Nenhuma superfície.
  ///
  /// É um token e não um `Colors.transparent` solto porque "transparente" é
  /// uma decisão de composição — folha sobre o conteúdo, `surfaceTint`
  /// desligado, notch da barra — e não a ausência de decisão.
  static const Color transparent = Color(0x00000000);

  // --- Seleção de cor de categoria ---

  /// Paleta oferecida ao usuário para colorir categorias e contas. É a única
  /// lista de cores "decorativas" do app; tudo que é papel semântico está
  /// acima.
  static const List<Color> selectionColors = [
    surfaceDeep,
    tealInk,
    gold,
    teal,
    progressStart,
    warning,
    violet,
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFFFFEB3B),
    Color(0xFFFF9800),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];
}
