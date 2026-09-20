import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';

import '../arena/hud_harness.dart';
import 'golden_support.dart';

/// As quatro folhas do HUD mensal — claro e escuro.
///
/// Elas concentram três decisões que são PINTURA e por isso não quebram teste
/// nenhum quando somem:
///
/// 1. o ícone do cabeçalho, que repete o da faixa no MESMO estado — anel,
///    tinta e, no ovo, o estágio da casca. É o que liga o toque ao que ele
///    abriu;
/// 2. a barra de HP de cada aldeão, que mostra a queda sem precisar da
///    palavra "morto": quem estourou fica com a calha inteira à mostra;
/// 3. o ícone de informação no canto do cabeçalho, que é por onde a mini
///    explicação passou a entrar. Ela saiu do corpo da folha — era ela que
///    empurrava os dados para baixo da dobra —, e o que estas oito capturas
///    provam é justamente o que sobrou: o que importa, sem rolar.
///
/// A folha da GOTA também é a única captura do estado sem receita prevista —
/// o aviso âmbar que substitui a classe quando o servidor ainda não sabe
/// quanto o usuário ganha.

Future<void> _pump(
  WidgetTester tester, {
  required Brightness brightness,
  required int indice,
  HudState? hud,
  Size size = const Size(400, 900),
  bool compact = true,
  bool introSeen = true,
}) async {
  await loadAppFonts();

  await pumpHudFooter(
    tester,
    hud: hud,
    size: size,
    compact: compact,
    introSeen: introSeen,
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
  );

  await openHudSheet(tester, indice);
}

/// A FAIXA inteira, nos dois tamanhos.
///
/// Ela faltava, e é onde mora metade das decisões deste pacote: as quatro
/// silhuetas a 30 px (o ovo e a gota nasceram sendo a MESMA figura em duas
/// cores), a casca verde do ovo contra o anel vermelho, e — do tablet para
/// cima — o NOME sob cada figura.
///
/// A captura é do tamanho exato da faixa: o golden é do rodapé, e não de uma
/// tela com um rodapé no pé dela.
void main() {
  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — hud_faixa$sufixo', (tester) async {
      await loadAppFonts();

      await pumpHudFooter(
        tester,
        size: const Size(400, 56),
        background: AppColors.surfaceDeep,
        theme: tema == Brightness.dark ? AppTheme.dark : AppTheme.light,
      );

      await expectLater(
        find.byKey(const ValueKey('arena-footer-slot')),
        matchesGoldenFile('images/hud_faixa$sufixo.png'),
      );
    });

    testWidgets('golden — hud_faixa_desktop$sufixo', (tester) async {
      await loadAppFonts();

      await pumpHudFooter(
        tester,
        size: const Size(1000, 64),
        compact: false,
        background: AppColors.surfaceDeep,
        theme: tema == Brightness.dark ? AppTheme.dark : AppTheme.light,
      );

      await expectLater(
        find.byKey(const ValueKey('arena-footer-slot')),
        matchesGoldenFile('images/hud_faixa_desktop$sufixo.png'),
      );
    });
  }

  final folhas = <({String nome, int indice, String chave})>[
    (nome: 'hud_pocao', indice: 0, chave: 'hud-sheet-potion'),
    (nome: 'hud_vila', indice: 1, chave: 'hud-sheet-village'),
    (nome: 'hud_ovo', indice: 2, chave: 'hud-sheet-egg'),
    (nome: 'hud_gota', indice: 3, chave: 'hud-sheet-drop'),
  ];

  for (final folha in folhas) {
    for (final tema in Brightness.values) {
      final sufixo = tema == Brightness.dark ? '_escuro' : '';

      testWidgets('golden — ${folha.nome}$sufixo', (tester) async {
        await _pump(tester, brightness: tema, indice: folha.indice);

        await expectLater(
          find.byKey(ValueKey(folha.chave)),
          matchesGoldenFile('images/${folha.nome}$sufixo.png'),
        );
      });
    }
  }

  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — hud_sem_receita$sufixo', (tester) async {
      await _pump(
        tester,
        brightness: tema,
        indice: 3,
        hud: hudTestState(income: null),
      );

      await expectLater(
        find.byKey(const ValueKey('hud-sheet-drop')),
        matchesGoldenFile('images/hud_sem_receita$sufixo.png'),
      );
    });
  }

  /// O painel de explicação, aberto sozinho na PRIMEIRA abertura da folha.
  ///
  /// Uma captura basta: o painel é o mesmo nas quatro folhas — muda o texto,
  /// não o desenho —, e o que ela guarda é a hierarquia das três frases (a
  /// do jogo em tinta principal, as outras duas em secundária), o título
  /// "Como funciona" com o mesmo ícone do botão que o abre, e o "Entendi"
  /// ancorado no pé, fora do que rola.
  testWidgets('golden — hud_explicacao', (tester) async {
    await _pump(tester, brightness: Brightness.light, indice: 0,
        introSeen: false);

    await expectLater(
      find.byKey(const ValueKey('hud-explanation')),
      matchesGoldenFile('images/hud_explicacao.png'),
    );
  });
}
