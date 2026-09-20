import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/observability/crash_reporter.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/widgets/app_progress_bar.dart';
import 'package:funances/core/widgets/app_ring.dart';
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

    testWidgets('quieta na TELA, mas nunca no relatório', (tester) async {
      // O silêncio era total: a falha não chegava a lugar nenhum, e uma
      // faixa vazia em produção era indistinguível de uma faixa carregando.
      // Quem não pode ver o erro é o usuário — há uma luta acontecendo logo
      // acima; quem precisa vê-lo é o Crashlytics.
      final relatados = <({Object erro, String? razao})>[];
      CrashReporter.onRecord = (erro, _, razao) =>
          relatados.add((erro: erro, razao: razao));
      addTearDown(() => CrashReporter.onRecord = null);

      await pumpHudFooter(
        tester,
        asyncState: AsyncValue<HudState>.error('boom', StackTrace.current),
      );

      expect(relatados, hasLength(1));
      expect(relatados.single.erro, 'boom');
      expect(relatados.single.razao, contains('HUD mensal'));
    });

    testWidgets('o MESMO erro não é relatado a cada quadro', (tester) async {
      // `build` roda muitas vezes com a mesma falha — a cena acima anima — e
      // o relatório não pode receber a mesma exceção quarenta vezes por
      // segundo.
      final relatados = <Object>[];
      CrashReporter.onRecord = (erro, _, _) => relatados.add(erro);
      addTearDown(() => CrashReporter.onRecord = null);

      final falha = AsyncValue<HudState>.error('boom', StackTrace.current);

      await pumpHudFooter(tester, asyncState: falha);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(relatados, hasLength(1));
    });
  });

  group('o que cada ícone diz', () {
    testWidgets('o retrato real do cofre do dono', (tester) async {
      await pumpHudFooter(tester);

      // Poção: R$ 263,41 de R$ 18.550,00 — 1,4% de um mês. Sem classe
      // (o "gole" saiu), a faixa mostra a RAZÃO no lugar da palavra.
      expect(find.text('< 0,1×'), findsOneWidget);

      // Vila: NOVE de dezesseis aldeões de pé, igual ao dry-run do
      // servidor. Dezesseis e não dezoito porque as duas categorias
      // `virtual_*` do cofre são de SISTEMA e não são aldeãs.
      expect(find.text('9/16'), findsOneWidget);

      // Incubados: R$ 20.187,80 ÷ R$ 18.550,00 = 1,1×.
      expect(find.text('1,1×'), findsOneWidget);

      // Veneno: R$ 7.623,68 ÷ R$ 18.550,00 = 0,4×.
      expect(find.text('0,4×'), findsOneWidget);
    });

    testWidgets('sem receita prevista, as três razões viram traço', (
      tester,
    ) async {
      await pumpHudFooter(tester, hud: hudTestState(income: null));

      // Três traços: poção, incubados e veneno. A vila continua contando,
      // porque o
      // denominador dela é o próprio plano.
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('9/16'), findsOneWidget);
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
      // São TRÊS: a poção sem classe mostra a razão como as outras duas.
      expect(find.text('0,0×'), findsNWidgets(3));
    });

    testWidgets('no modo empresa a vila CONTINUA sendo a Vila', (tester) async {
      // O nome do ícone é o do JOGO, e o jogo é o mesmo nos dois workspaces.
      // Chamá-lo de "Centros de custo" na empresa tirava dela a única
      // metáfora que a faixa tem; quem troca de vocabulário é o texto
      // financeiro da mini explicação.
      await pumpHudFooter(tester, isBusiness: true, size: const Size(900, 800));

      expect(
        find.bySemanticsLabel(RegExp('^Vila: 9 de 16 aldeões vivos')),
        findsOneWidget,
      );
      expect(find.text('Centros de custo'), findsNothing);
      expect(find.text('Vila'), findsOneWidget);
    });

    testWidgets('e a FOLHA da vila também se chama Vila na empresa', (
      tester,
    ) async {
      await pumpHudFooter(tester, isBusiness: true, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Vila'), findsOneWidget);

      // "Centro de custo" sobrevive onde ele é a coisa CERTA de dizer: o
      // texto financeiro da mini explicação, que fala do plano real da
      // empresa e não do jogo.
      expect(find.textContaining('limite por centro de custo'), findsOneWidget);
      expect(find.textContaining('Cada centro de custo'), findsOneWidget);
    });

    testWidgets('a poção pequena não vira zero: "< 0,1×"', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).first);
      await tester.pumpAndSettle();

      // R$ 263,41 sobre R$ 18.550,00 — a razão não pode negar um saldo que
      // existe, e quem a carrega na folha é o CHIP: abaixo do primeiro
      // décimo a linha "< 0,1× da receita…" era o mesmo número dito de
      // novo, logo abaixo do chip.
      expect(find.text('< 0,1 mês de pé'), findsOneWidget);
      // Dentro da FOLHA: a faixa atrás dela continua mostrando "< 0,1×", e
      // é lá que a razão vive.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('hud-sheet-potion')),
          matching: find.textContaining('< 0,1×'),
        ),
        findsNothing,
      );

      // A receita continua dita por extenso, na nota logo abaixo.
      expect(find.textContaining('R\$\u{00A0}18.550,00'), findsWidgets);
    });
  });

  group('a classe é só da poção', () {
    testWidgets('a folha do ovo mostra a razão, e nenhuma classe', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      // Sem classe nenhuma na frente: dar nome de classe a R$ 20.187,80 em
      // faturas era elogiar o usuário pelo tamanho da dívida.
      expect(
        find.text('1,1× da receita prevista do mês (R\$\u{00A0}18.550,00)'),
        findsOneWidget,
      );
    });

    testWidgets('a folha da gota também', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(3));
      await tester.pumpAndSettle();

      expect(
        find.text('0,4× da receita prevista do mês (R\$\u{00A0}18.550,00)'),
        findsOneWidget,
      );
    });

    testWidgets('a folha da poção mantém a classe, porque ela é dela', (
      tester,
    ) async {
      // Meio mês de receita guardado: R$ 9.275,00 de R$ 18.550,00.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(
          investments: const [
            HudBalanceReading(accountId: 'inv', name: 'Tesouro', balance: 9275),
          ],
        ),
      );

      await tester.tap(find.byType(HudGlyph).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('semi · '), findsOneWidget);
      expect(find.text('0,5 mês de pé'), findsOneWidget);
    });

    testWidgets('abaixo de meio mês não há classe nenhuma na folha', (
      tester,
    ) async {
      // O "gole" saiu a pedido do dono: uma palavra de classe sobre
      // R$ 263,41 é um diploma para quem ainda não guardou nada.
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).first);
      await tester.pumpAndSettle();

      expect(find.textContaining(' · '), findsNothing);
      expect(find.text('< 0,1 mês de pé'), findsOneWidget);
      // E a razão não se repete embaixo do chip, dentro da folha.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('hud-sheet-potion')),
          matching: find.textContaining('< 0,1×'),
        ),
        findsNothing,
      );
    });
  });

  group('a fatura vencida', () {
    testWidgets('a Nubank de 17/09 diz que venceu, e vem primeiro', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      expect(find.text('Venceu há 3 dias'), findsOneWidget);

      // E ela é a primeira linha da folha: a posição é metade do aviso.
      final linhas = tester
          .widgetList<Text>(find.textContaining('Cartão'))
          .map((t) => t.data)
          .toList();

      expect(linhas.first, 'Cartão Nubank VgIy');
    });
  });

  group('a semântica carrega o julgamento', () {
    testWidgets('as quatro leituras dizem o que a cor diz', (tester) async {
      await pumpHudFooter(tester);

      // Sem isto, quem usa leitor de tela recebia o número e perdia o
      // veredito — que é justamente o que a faixa entrega sem texto.
      expect(
        find.bySemanticsLabel(
          RegExp('^Poção: R\\\$\u{00A0}263,41, < 0,1 mês de pé[.]'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          // O cofre real: as despesas couberam (R\$ 17.334,73 de
          // R\$ 18.170,00) e o envelope de investimento fechou com "Taxas de
          // Juros" (R\$ 431,54 de R\$ 50,00) — vila VIVA, como no dry-run do
          // servidor.
          RegExp('^Vila: 9 de 16 aldeões vivos, vila viva'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^Incubados: 1,1× da receita, faturas acima da receita, perigo',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('^Veneno: 0,4× da receita, veneno ativo, dívida em aberto'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem receita prevista, a semântica diz isso — e o valor', (
      tester,
    ) async {
      await pumpHudFooter(tester, hud: hudTestState(income: null));

      expect(
        find.bySemanticsLabel(
          RegExp(
            '^Incubados: R\\\$\u{00A0}20[.]187,80, receita prevista ainda não '
            'calculada',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cofre vazio: vila sem vila, veneno sem dívida', (
      tester,
    ) async {
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

      expect(
        find.bySemanticsLabel(RegExp('^Vila: 0 de 0 aldeões vivos, sem vila')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('sem veneno, nenhuma dívida')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('poção vazia')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('nenhum monstro incubado')),
        findsOneWidget,
      );
    });
  });

  group('os nomes sob as figuras', () {
    testWidgets('no celular não há nome: o número é quem disputa o espaço', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 800));

      expect(find.text('Poção'), findsNothing);
      expect(find.text('Vila'), findsNothing);
      expect(find.text('Incubados'), findsNothing);
      expect(find.text('Veneno'), findsNothing);
    });

    for (final largura in <double>[600, 900, 1300]) {
      testWidgets('a ${largura.toInt()} px os quatro se apresentam', (
        tester,
      ) async {
        await pumpHudFooter(
          tester,
          size: Size(largura, 800),
          compact: largura < 900,
        );

        expect(find.text('Poção'), findsOneWidget);
        expect(find.text('Vila'), findsOneWidget);
        expect(find.text('Incubados'), findsOneWidget);
        expect(find.text('Veneno'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('os nomes que o dono deu', () {
    testWidgets('a faixa diz "Incubados"; a folha, "Monstros incubados"', (
      tester,
    ) async {
      // O ovo é o único com DOIS rótulos, e a diferença é de LARGURA. Sob uma
      // figura de 30 px no rodapé cabe a palavra curta; quem abriu a folha
      // tem espaço para o nome inteiro do que está chocando ali.
      await pumpHudFooter(tester, size: const Size(900, 900), compact: false);

      expect(find.text('Incubados'), findsOneWidget);
      expect(find.text('Monstros incubados'), findsNothing);

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      expect(find.text('Monstros incubados'), findsOneWidget);
    });

    testWidgets('as três frases do veneno apontam para a independência', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(3));
      await tester.pumpAndSettle();

      expect(find.text('Veneno'), findsOneWidget);
      expect(
        find.textContaining('os juros corroem seu capital'),
        findsOneWidget,
      );
      expect(
        find.textContaining('primeiro passo da independência financeira'),
        findsOneWidget,
      );
    });

    testWidgets('a poção termina no fim da batalha', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(0));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('capital que trabalha por você'),
        findsOneWidget,
      );
      expect(
        find.textContaining('isso é independência financeira'),
        findsOneWidget,
      );
    });
  });

  group('a folha dos incubados mostra o limite de cada cartão', () {
    testWidgets('a barra de uso aparece por cartão, como na Visão Geral', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hud-limit-nubank2')), findsOneWidget);
      expect(find.byKey(const ValueKey('hud-limit-itau')), findsOneWidget);

      // Os limites e os saldos são os REAIS de 20/09/2026.
      // Itaú: R$ 3.114,33 de R$ 8.000 = 39%.
      expect(find.text('39% do limite usado'), findsOneWidget);
      // Nubank VgIy: R$ 4.854,39 de R$ 21.000 = 23%.
      expect(find.text('23% do limite usado'), findsOneWidget);
    });

    testWidgets('cartão sem limite cadastrado diz isso, e não 0%', (
      tester,
    ) async {
      // O defeito que esta asserção impede: `limit` nasce ZERO quando o
      // usuário não o preenche, e uma barra sobre zero desenha 0% — "seu
      // cartão está inteiro livre" — justamente onde o app não sabe de nada.
      //
      // O cartão é SINTÉTICO e declarado como tal: nenhum dos seis cartões
      // reais do dono está sem limite, e fingir que o C6 estava foi como
      // este número inventado chegou ao README.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(invoices: [hudInvoiceSemLimite()]),
      );

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('hud-limit-unknown-sintetico-sem-limite')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('hud-limit-sintetico-sem-limite')),
        findsNothing,
      );
      expect(find.text('0% do limite usado'), findsNothing);
      expect(find.text('Limite não informado neste cartão.'), findsOneWidget);
    });

    testWidgets('o que falta para o teto sai do mesmo saldo da Visão Geral', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      // Itaú: R$ 3.114,33 usados de R$ 8.000 deixam R$ 4.885,67. A conta é
      // do app e não campo do banco — se ela sair errada, o usuário decide
      // uma compra por um número inventado.
      expect(find.textContaining('4.885,67 até o limite'), findsOneWidget);
    });

    testWidgets('cartão estourado diz o tamanho do furo, e não "100%"', (
      tester,
    ) async {
      // O par "100% · R$ 0,00 até o limite" está aritmeticamente certo e
      // mente por omissão: quem furou o teto não está "no talo", está
      // devendo mais do que o banco autorizou — e só o tamanho do furo se
      // pode agir.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(invoices: [hudInvoiceEstourado()]),
      );

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      // R$ 9.812,00 de R$ 9.000 = 109%, e R$ 812,00 acima do teto.
      expect(find.text('109% do limite usado'), findsOneWidget);
      expect(find.textContaining('812,00 acima do limite'), findsOneWidget);
      expect(find.textContaining('até o limite'), findsNothing);

      // A barra prende em 100% — um retângulo não cresce além do trilho — e
      // vira tinta de perigo.
      final barra = tester.widget<AppProgressBar>(
        find.descendant(
          of: find.byKey(const ValueKey('hud-limit-sintetico-estourado')),
          matching: find.byType(AppProgressBar),
        ),
      );
      expect(barra.value, 1.0);
      expect(barra.color, AppColors.danger);
    });

    testWidgets('a semântica da barra diz de QUAL cartão ela é', (
      tester,
    ) async {
      // São seis barras seguidas na mesma folha: sem o nome, quem ouve a
      // tela recebia seis vezes "Limite do cartão" com seis porcentagens.
      final handle = tester.ensureSemantics();
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(2));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Limite do Cartão Itaú'), findsOneWidget);

      handle.dispose();
    });
  });

  group('a folha da vila é uma grade, e não uma lista', () {
    testWidgets('os grupos se apresentam com a contagem', (tester) async {
      // Tela alta de propósito: a folha rola, e os títulos não cabem juntos
      // em 900 px com dezesseis tiles entre eles.
      await pumpHudFooter(tester, size: const Size(400, 1600));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // Nove de dezesseis de pé no cofre do dono, sete caídos — e NENHUM em
      // risco: a única categoria de investimento do mês ("Taxas de Juros")
      // já passou do alvo. Grupo vazio não desenha nem o título.
      expect(find.text('Vivos (9)'), findsOneWidget);
      expect(find.text('Caídos (7)'), findsOneWidget);
      expect(find.textContaining('Em risco ('), findsNothing);
    });

    testWidgets('o nome de uma palavra só cabe numa linha no tile', (
      tester,
    ) async {
      // B12: "Supermercado" não cabe em 84 px, e o Flutter só quebra DENTRO
      // de uma palavra quando ela sozinha estoura a linha — o tile mostrava
      // "Supermerca/do", duas metades que parecem palavras e não são. Nome
      // de uma palavra fica em UMA linha, com reticências se precisar; o de
      // duas ou mais pode usar duas.
      await pumpHudFooter(tester, size: const Size(400, 1600));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      final uma = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('hud-villager-cat-Supermercado')),
          matching: find.text('Supermercado'),
        ),
      );
      expect(uma.maxLines, 1);

      final duas = tester.widget<Text>(
        find.descendant(
          of: find.byKey(
            const ValueKey('hud-villager-cat-Manutenção do carro'),
          ),
          matching: find.text('Manutenção do carro'),
        ),
      );
      expect(duas.maxLines, 2);
    });

    testWidgets('a folha mostra os DOIS envelopes, um em cada linha', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 1600));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // Sem a segunda linha, o usuário lia "despesas dentro do plano" ao
      // lado de "a vila não está de pé" e concluía que o app errou a conta.
      expect(
        find.text('Despesas: R\$\u{00A0}17.334,73 de R\$\u{00A0}18.170,00'),
        findsOneWidget,
      );
      expect(
        find.text('Investimentos: R\$\u{00A0}431,54 de R\$\u{00A0}50,00'),
        findsOneWidget,
      );

      // Os dois fecharam: a vila está de pé.
      expect(
        find.text('A vila está de pé: a soma cabe no plano.'),
        findsOneWidget,
      );
    });

    testWidgets('sem meta de aporte, a linha de investimento não aparece', (
      tester,
    ) async {
      // Vila sem envelope de investimento não tem o que mostrar ali, e uma
      // linha "R\$ 0,00 de R\$ 0,00" é ruído.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(
          categories: [
            for (final nome in ['Mercado', 'Lazer', 'Saúde'])
              HudCategoryReading(
                categoryId: 'cat-$nome',
                name: nome,
                icon: 'shopping_cart',
                color: '#FF5722',
                isExpense: true,
                isSystem: false,
                planned: 1000,
                actual: 400,
              ),
          ],
        ),
      );

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      expect(find.textContaining('Despesas: '), findsOneWidget);
      expect(find.textContaining('Investimentos: '), findsNothing);
      expect(
        find.text('A vila está de pé: a soma cabe no plano.'),
        findsOneWidget,
      );
    });

    testWidgets('o aldeão de investimento enche o anel em âmbar', (
      tester,
    ) async {
      // O cofre do dono não tem nenhum aldeão em risco neste mês — a única
      // categoria de investimento dele ("Taxas de Juros") já passou do alvo
      // —, então o caso vem de um plano montado aqui: meta de R$ 200 e nada
      // aportado.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(categories: _planoComAporteFaltando()),
      );

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // O anel ENCHE conforme o aporte entra, em vez de esvaziar como o da
      // despesa — um anel que esvaziasse a cada aporte diria que guardar
      // dinheiro é perder alguma coisa.
      final investimentos = tester.widget<AppRing>(
        find.descendant(
          of: find.byKey(const ValueKey('hud-villager-cat-Investimentos')),
          matching: find.byType(AppRing),
        ),
      );

      expect(investimentos.value, 0);
      expect(investimentos.color, AppColors.warning);

      // E ele está no grupo dos EM RISCO, não no dos caídos: o mês não
      // acabou, e ainda dá tempo de aportar.
      final emRisco = find.byKey(const ValueKey('hud-village-at-risk'));
      expect(
        find.descendant(
          of: emRisco,
          matching: find.byKey(
            const ValueKey('hud-villager-cat-Investimentos'),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a semântica do aldeão em risco diz o que falta aportar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(categories: _planoComAporteFaltando()),
      );

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // Quem não vê o anel âmbar precisa ouvir a regra invertida, e ela só
      // existe se o rótulo disser a META e o que falta para ela.
      expect(
        find.bySemanticsLabel(
          // Sem âncora no começo: o grupo de UM tile só funde o título
          // dele com o do aldeão num nó só ("Em risco (1)\nInvestimentos:
          // …"), e é assim que o leitor de tela vai ler mesmo.
          RegExp(
            'Investimentos: .+ de .+ investidos — faltam .+ '
            'para o aldeão ficar de pé',
          ),
        ),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('o aldeão caído tem o anel CHEIO de vermelho', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // Vazio, o caído lia como um aldeão que ainda não tinha carregado: a
      // calha inteira à mostra é a ausência de anel, não a presença de uma
      // notícia ruim.
      final caido = tester.widget<AppRing>(
        find.descendant(
          of: find.byKey(
            const ValueKey('hud-villager-cat-Manutenção do carro'),
          ),
          matching: find.byType(AppRing),
        ),
      );

      expect(caido.value, 1);
      expect(caido.color, AppColors.danger);
    });

    testWidgets('os vivos vêm por proximidade da morte', (tester) async {
      await pumpHudFooter(tester, size: const Size(400, 1600));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      final vivos = tester
          .widgetList<AppRing>(
            find.descendant(
              of: find.byKey(const ValueKey('hud-village-alive')),
              matching: find.byType(AppRing),
            ),
          )
          .map((ring) => ring.value)
          .toList();

      // Fração de HP CRESCENTE: quem está mais perto de cair aparece antes.
      // Folga em reais não é risco — "Investimentos", com R$ 200 de
      // orçamento e nada gasto, não pode subir acima de "Cuidados pessoais",
      // que já queimou 78% de R$ 1.500.
      expect(vivos, isNotEmpty);
      expect(vivos, orderedEquals(<double>[...vivos]..sort()));
      expect(vivos.first, lessThan(vivos.last));
    });

    testWidgets('o valor do aldeão é compacto, e a semântica é exata', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // "Manutenção do carro": R$ 350 de orçamento contra R$ 1.462,85 —
      // R$ 1.112,85 além do plano. Sob um anel de 44 px cabe "R$ 1,1 mil";
      // quem ouve a tela recebe o número inteiro.
      expect(
        find.bySemanticsLabel(
          RegExp('^Manutenção do carro: R.*1[.]112,85 além do orçamento'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('o mês fechado aparece por extenso, não como chave', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('ago/2026'), 200);

      expect(find.text('ago/2026'), findsOneWidget);
      expect(find.text('2026-08'), findsNothing);
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

  group('as quatro folhas cabem', () {
    for (final caso in <({String nome, Size tamanho, bool compact})>[
      (nome: 'celular, 400 px', tamanho: Size(400, 900), compact: true),
      (nome: 'desktop, 1300 px', tamanho: Size(1300, 900), compact: false),
    ]) {
      for (final tema in Brightness.values) {
        testWidgets('${caso.nome}, tema ${tema.name}', (tester) async {
          for (var indice = 0; indice < 4; indice++) {
            await pumpHudFooter(
              tester,
              size: caso.tamanho,
              compact: caso.compact,
              theme: tema == Brightness.dark ? AppTheme.dark : AppTheme.light,
            );

            await tester.tap(find.byType(HudGlyph).at(indice));
            await tester.pumpAndSettle();

            // A grade da vila é a que corre mais risco: dezoito tiles num
            // `Wrap` dentro de um `ListView` dentro de uma folha modal.
            expect(
              tester.takeException(),
              isNull,
              reason: 'a folha $indice estourou em ${caso.nome}',
            );
          }
        });
      }
    }

    testWidgets('a folha da vila respeita "reduzir movimento"', (tester) async {
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        reduceMotion: true,
      );

      await tester.tap(find.byType(HudGlyph).at(1));
      await tester.pumpAndSettle();

      // Dezoito anéis de aldeão são dezoito `CustomPaint` parados. Se algum
      // deles tivesse ficado com um `Ticker` vivo — que é o que o
      // `CircularProgressIndicator` da Party faz mesmo com `value` fixo — a
      // folha pediria quadro para sempre.
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

      // Σ realizado ÷ Σ planejado das DESPESAS = 17.334,73 / 18.170,00. Os
      // R$ 50 de meta de "Taxas de Juros" ficam fora: aporte não é gasto, e
      // somá-lo faria guardar dinheiro apertar a vila.
      expect(aneis[1].progress, closeTo(0.9540, 0.0001));
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

/// Um plano com o envelope de investimento ABERTO: três despesas dentro do
/// limite e uma meta de aporte de R$ 200 sem nenhum aporte.
///
/// Ele existe porque o cofre do dono não tem aldeão em risco neste mês, e o
/// estado precisa de teste mesmo assim — fingir que o retrato real o tem foi
/// o defeito que o QA pegou nos limites dos cartões.
List<HudCategoryReading> _planoComAporteFaltando() => [
  for (final nome in ['Mercado', 'Lazer', 'Saúde'])
    HudCategoryReading(
      categoryId: 'cat-$nome',
      name: nome,
      icon: 'shopping_cart',
      color: '#FF5722',
      isExpense: true,
      isSystem: false,
      planned: 1000,
      actual: 400,
    ),
  const HudCategoryReading(
    categoryId: 'cat-Investimentos',
    name: 'Investimentos',
    icon: 'savings',
    color: '#4CAF50',
    isExpense: true,
    isSystem: false,
    planned: 200,
    actual: 0,
    isInvestment: true,
  ),
];
