import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';

import 'hud_harness.dart';

/// A faixa do HUD mensal, na tela.
///
/// Três coisas podem dar errado numa faixa de 56 px com quatro ícones, e as
/// três já deram em alguma barra de jogo:
///
/// 1. **não caber**. Quatro ícones, quatro rótulos e uma tela de 400 px são
///    um encaixe apertado, e um `RenderFlex overflowed` é a diferença entre
///    "rodapé" e "tarja amarela e preta";
/// 2. **mudar de altura**. Ela é a última linha da cena: crescer quando os
///    dados chegam reorganiza a Home inteira;
/// 3. **afirmar o que não sabe**. Sem receita prevista, três dos quatro
///    ícones não têm razão nenhuma — e "0,0×" seria uma afirmação.

void main() {
  group('a faixa cabe', () {
    for (final caso in <({String nome, Size tamanho, bool compact})>[
      (nome: 'celular, 400 px', tamanho: Size(400, 800), compact: true),
      (nome: 'desktop, 1300 px', tamanho: Size(1300, 900), compact: false),
    ]) {
      testWidgets('${caso.nome}: quatro ícones, sem estouro', (tester) async {
        await pumpHudFooter(tester, size: caso.tamanho, compact: caso.compact);

        expect(find.byType(HudGlyph), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${caso.nome}: a altura é a reservada', (tester) async {
        await pumpHudFooter(tester, size: caso.tamanho, compact: caso.compact);

        final faixa = tester.getSize(
          find.byKey(const ValueKey('arena-footer-slot')),
        );

        expect(faixa.height, caso.compact ? 56 : 64);
        expect(faixa.width, caso.tamanho.width);
      });
    }

    testWidgets('a altura NÃO muda entre carregando e pronto', (tester) async {
      await pumpHudFooter(
        tester,
        asyncState: const AsyncValue<HudState>.loading(),
      );

      final carregando = tester.getSize(
        find.byKey(const ValueKey('arena-footer-slot')),
      );

      await pumpHudFooter(tester);

      final pronto = tester.getSize(
        find.byKey(const ValueKey('arena-footer-slot')),
      );

      expect(carregando, pronto);
      expect(carregando.height, 56);
    });

    testWidgets('carregando, a faixa fica vazia — sem esqueleto', (
      tester,
    ) async {
      await pumpHudFooter(
        tester,
        asyncState: const AsyncValue<HudState>.loading(),
      );

      expect(find.byType(HudGlyph), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('falhou, a faixa também fica quieta', (tester) async {
      await pumpHudFooter(
        tester,
        asyncState: AsyncValue<HudState>.error('boom', StackTrace.current),
      );

      expect(find.byType(HudGlyph), findsNothing);
      expect(find.textContaining('boom'), findsNothing);
    });
  });

  group('o que cada ícone diz', () {
    testWidgets('o retrato real do cofre do dono', (tester) async {
      await pumpHudFooter(tester);

      // Poção: R$ 263,41 de R$ 18.550,00 — 1,4% de um mês, classe nenhuma.
      expect(find.text('gole'), findsOneWidget);

      // Vila: treze de dezoito aldeões de pé.
      expect(find.text('13/18'), findsOneWidget);

      // Ovo: R$ 20.187,80 ÷ R$ 18.550,00 = 1,1×.
      expect(find.text('1,1×'), findsOneWidget);

      // Gota: R$ 7.623,68 ÷ R$ 18.550,00 = 0,4×.
      expect(find.text('0,4×'), findsOneWidget);
    });

    testWidgets('sem receita prevista, as três razões viram traço', (
      tester,
    ) async {
      await pumpHudFooter(tester, hud: hudTestState(income: null));

      // Três traços: poção, ovo e gota. A vila continua contando, porque o
      // denominador dela é o próprio plano.
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('13/18'), findsOneWidget);
      expect(find.text('gole'), findsNothing);
    });

    testWidgets('a classe sobe com o saldo guardado', (tester) async {
      await pumpHudFooter(
        tester,
        hud: hudTestState(
          investments: const [
            HudBalanceReading(
              accountId: 'inv',
              name: 'Tesouro',
              balance: 37100,
            ),
          ],
        ),
      );

      expect(find.text('hiper'), findsOneWidget);
    });

    testWidgets('cofre sem nada não inventa número', (tester) async {
      await pumpHudFooter(
        tester,
        hud: hudTestState(
          investments: const [],
          debts: const [],
          invoices: const [],
          categories: const [],
          history: const [],
        ),
      );

      // A vila sem aldeão nenhum é um traço; as razões zeradas são "0,0×",
      // que aqui é verdade — há denominador, e o numerador é zero mesmo.
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0,0×'), findsNWidgets(2));
      expect(find.text('gole'), findsOneWidget);
    });

    testWidgets('no modo empresa a vila muda de nome', (tester) async {
      await pumpHudFooter(tester, isBusiness: true);

      final semantics = find.bySemanticsLabel(
        RegExp('Centros de custo: 13/18'),
      );

      expect(semantics, findsOneWidget);
    });
  });

  group('os gestos', () {
    testWidgets('tocar abre a folha com a explicação e os números', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hud-explanation')), findsOneWidget);
      expect(find.text('Cofrinho Disney'), findsOneWidget);
    });

    testWidgets('segurar abre a tela de dados', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      // A vila é o segundo ícone: ela leva ao planejamento.
      await tester.longPress(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      expect(find.text('planejamento'), findsOneWidget);
    });

    for (final caso in <({int indice, String nome, String linha})>[
      (indice: 0, nome: 'poção', linha: 'Cofrinho Disney'),
      (indice: 1, nome: 'vila', linha: 'Manutenção do carro'),
      (indice: 2, nome: 'ovo', linha: 'Cartão Inter'),
      (indice: 3, nome: 'gota', linha: 'Empréstimo Itaú'),
    ]) {
      testWidgets('a folha da ${caso.nome} traz explicação e dados', (
        tester,
      ) async {
        // Cada folha num teste próprio, e não num laço com fechamento entre
        // elas: uma folha aberta por cima da anterior encontraria DOIS
        // ícones de poção na árvore, e o teste passaria a medir a ordem de
        // fechamento em vez do conteúdo.
        await pumpHudFooter(tester, size: const Size(400, 900));

        await tester.tap(find.byType(HudGlyph).at(caso.indice));
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('hud-explanation')), findsOneWidget);
        expect(find.text(caso.linha), findsOneWidget);
      });
    }
  });

  group('o movimento', () {
    testWidgets('sem dívida e sem fatura, nada se mexe', (tester) async {
      await pumpHudFooter(
        tester,
        hud: hudTestState(debts: const [], invoices: const []),
        reduceMotion: false,
      );

      // A gota só pisca com dívida e o ovo só treme a partir de 0,8: sem os
      // dois, a faixa não agenda quadro nenhum. Movimento sem motivo é
      // bateria gasta em pixel que não diz nada.
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('com dívida e com ovo grande, a faixa se mexe', (tester) async {
      await pumpHudFooter(tester, reduceMotion: false);
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.binding.hasScheduledFrame, isTrue);

      // E o movimento precisa PARAR quando o widget sai: um ticker vivo numa
      // faixa desmontada é bateria gasta pelo resto da sessão.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('"reduzir movimento" para tudo', (tester) async {
      await pumpHudFooter(tester, reduceMotion: true);

      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('o tema escuro', () {
    testWidgets('a faixa monta no escuro sem estourar', (tester) async {
      await pumpHudFooter(tester, theme: AppTheme.dark);

      expect(find.byType(HudGlyph), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('o anel', () {
    testWidgets('o anel da vila mede o mês, não a semana', (tester) async {
      await pumpHudFooter(tester);

      final aneis = tester.widgetList<HudRing>(find.byType(HudRing)).toList();

      // Σ realizado ÷ Σ planejado = 14.912,20 / 22.220,00.
      expect(aneis[1].progress, closeTo(0.6711, 0.0001));
    });

    testWidgets('o anel do ovo enche quando a razão passa de um mês', (
      tester,
    ) async {
      await pumpHudFooter(tester);

      final aneis = tester.widgetList<HudRing>(find.byType(HudRing)).toList();

      expect(aneis[2].progress, 1);
    });
  });
}
