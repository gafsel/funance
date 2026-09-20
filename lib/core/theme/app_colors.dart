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

  /// A calha vazia das barras de vida: o que sobra quando a vida sai.
  ///
  /// Mais escura que [surfaceDeep] de propósito. Ela é o "sem vida", e
  /// precisa ler como buraco — não como uma segunda cor de superfície.
  ///
  /// Ela sozinha NÃO se separa do fundo profundo (1,38:1), e isso é uma
  /// escolha, não um descuido: quem delimita a barra é a moldura
  /// ([gameFrame]). A conta que obriga a isso está em
  /// `test/arena/arena_contrast_test.dart` — com o violeta do monstro, não
  /// existe calha que se separe do fundo E deixe o preenchimento aparecer.
  static const Color gameTrough = Color(0xFF05171D);

  /// A moldura das barras de vida.
  ///
  /// É ela que diz ONDE a barra está, e por isso ela existe: uma barra quase
  /// vazia sem moldura lia igual a "não há barra nenhuma aqui". É também a
  /// solução que todo jogo de luta usa — o quadro claro em volta do HP.
  static const Color gameFrame = Color(0xFFB7CDD3);

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

  // Cada semântica tem TRÊS tokens: a cor cheia (fundo de pílula, barra,
  // ícone grande), a tinta de texto sobre papel CLARO e a tinta de texto
  // sobre papel ESCURO. Faltava a terceira: no tema escuro o app escrevia
  // com a cor cheia, e a cor cheia foi escolhida para preencher, não para
  // ler. `danger` sobre `paperDark` dava 2,83:1 em 103 lugares — o vermelho
  // que avisa que algo deu errado era o texto menos legível do app.

  static const Color success = Color(0xFF3FB950);

  /// Verde legível sobre papel claro.
  static const Color successInk = Color(0xFF1B6B32);

  /// Verde legível sobre papel escuro.
  ///
  /// "Papel escuro" são SEIS superfícies, e a mais clara delas é a que manda:
  /// `surfaceRaised`, o cartão dentro de um bloco de jogo — onde o
  /// `AppTheme.onGame` coloca o `paper2`. Contra ela a cor cheia dava 4,36:1
  /// e o primeiro ajuste, 4,29:1: os dois passavam no papel liso e reprovavam
  /// justamente onde a tinta mais aparece. Esta dá 4,57:1 na pior superfície
  /// e 6,13:1 no papel.
  static const Color successInkDark = Color(0xFF56DA64);

  static const Color warning = Color(0xFFFF8A3D);

  /// Laranja legível sobre papel claro.
  static const Color warningInk = Color(0xFF8A4B00);

  /// Laranja legível sobre papel escuro.
  ///
  /// Dois pisos o derrubaram, um por rodada. A cor cheia passava no papel
  /// liso (4,73:1) e caía para 4,07:1 na PÍLULA — o próprio laranja a 12%
  /// sobre o papel. O ajuste seguinte resolveu a pílula e reprovou em
  /// `surfaceRaised` (4,12:1), a mais clara das seis superfícies escuras.
  /// Este tom mantém o matiz (24°) e dá 4,56:1 na pior superfície, 4,96:1 na
  /// pílula e 6,11:1 no papel.
  static const Color warningInkDark = Color(0xFFFFAE78);

  /// Erro **e** destrutivo: um token só. Antes eram quatro vermelhos
  /// concorrentes (e um roxo no `ColorScheme.error`).
  static const Color danger = Color(0xFFE5484D);

  /// Vermelho legível sobre papel claro.
  static const Color dangerInk = Color(0xFF7A1418);

  /// Vermelho legível sobre papel escuro.
  ///
  /// A cor cheia dava 2,83:1, o pior contraste de texto do app e justamente
  /// no aviso de erro. O primeiro ajuste subiu o papel liso e parou em 4,08:1
  /// contra `surfaceRaised`, a mais clara das seis superfícies escuras. Este
  /// tom mantém o matiz (358°, vermelho e não laranja) e dá 4,57:1 na pior
  /// superfície e 6,12:1 no papel.
  static const Color dangerInkDark = Color(0xFFFFAAAC);

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

  // --- Tinta sobre uma cor arbitrária ---

  /// A tinta legível sobre [background]: [inkInverse] ou [inkLight], a que
  /// tiver MAIS contraste.
  ///
  /// Cinco lugares do app decidiam isso com `computeLuminance() < 0.5`, e os
  /// cinco erravam do mesmo jeito. O corte em 0.5 responde "esta cor é
  /// escura?", que não é a pergunta: a pergunta é "qual das minhas duas
  /// tintas se enxerga melhor aqui?". As duas coincidem quando as tintas são
  /// preto e branco puros; as nossas não são — a tinta escura é um
  /// azul-petróleo (#0A2329) e a clara é quase branca —, e a assimetria entre
  /// elas desloca o ponto de virada bem abaixo de 0.5.
  ///
  /// O estrago era concreto e cobria justamente as cores mais usadas: os três
  /// pools do 50/30/20 têm luminância abaixo de 0.5, então **todos** recebiam
  /// tinta clara. O pool30, um âmbar, ficava em 2.06:1 — abaixo de qualquer
  /// piso de acessibilidade — quando com a tinta escura daria 7.58:1. Idem
  /// para `success`, `warning` e `danger`, que aparecem em pílula e em chip
  /// de cabeçalho.
  ///
  /// Por razão de contraste (WCAG 2.1), não por luminância:
  /// `(claro + 0.05) / (escuro + 0.05)`.
  static Color inkOn(Color background) =>
      contrastRatio(background, inkInverse) >=
          contrastRatio(background, inkLight)
      ? inkInverse
      : inkLight;

  /// Razão de contraste entre duas cores, de 1 (iguais) a 21 (preto/branco).
  ///
  /// Público porque legibilidade é uma propriedade que se AFIRMA: um teste
  /// que diz "esta tinta tem pelo menos 4.5:1 sobre este fundo" continua
  /// valendo quando alguém ajustar o hexadecimal, enquanto um teste que
  /// compara com a cor esperada só repete a constante.
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
