import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/services/hud_calculator.dart';
import 'package:funances/features/arena/presentation/widgets/arena_heroes_sheet.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';
import 'package:funances/features/finance/presentation/widgets/account_logo.dart';

import 'arena_harness.dart';
import 'hud_harness.dart';

/// A logo do banco e os donos nas listas de conta da Arena.
///
/// O dono: *"Na lista de contas, que define o hp dos heróis, mostre a logo do
/// banco e dos proprietários, como na aba de visão geral. faça o mesmo com os
/// cartões e dívidas e investimentos. isso ajuda o usuário a entender como
/// identificar esses dados facilmente (é o padrão adotado em todo o app)"*.
///
/// O teste afirma duas coisas, e a segunda é a que costuma quebrar:
///
/// 1. as quatro listas usam o [AccountLogo] **da Visão Geral**, com os donos
///    ligados — e não um desenho parecido;
/// 2. uma conta que o app não conhece continua desenhando. As folhas recebem
///    LEITURAS do mês; uma conta apagada depois do fechamento aparece na
///    leitura e não existe mais no mapa, e essa linha não pode virar buraco.

/// As logos visíveis, com a marcação de donos ligada.
Iterable<AccountLogo> _logos(WidgetTester tester) =>
    tester.widgetList<AccountLogo>(find.byType(AccountLogo));

void main() {
  group('as listas das folhas do HUD', () {
    for (final caso in <({int indice, String nome, String conta})>[
      (indice: 0, nome: 'poção', conta: 'Cofrinho Disney'),
      (indice: 2, nome: 'incubados', conta: 'Cartão Inter'),
      (indice: 3, nome: 'veneno', conta: 'Empréstimo Itaú'),
    ]) {
      testWidgets('a folha da ${caso.nome} mostra a logo e os donos', (
        tester,
      ) async {
        await pumpHudFooter(tester, size: const Size(400, 900));

        await openHudSheet(tester, caso.indice);

        expect(find.text(caso.conta), findsOneWidget);

        final logos = _logos(tester);
        expect(logos, isNotEmpty, reason: caso.nome);
        expect(
          logos.every((logo) => logo.showMembers),
          isTrue,
          reason: 'os donos são metade do pedido',
        );
        expect(logos.every((logo) => logo.size == 32), isTrue);
      });
    }

    testWidgets('a vila NÃO ganha logo: categoria não tem banco', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 900));

      await openHudSheet(tester, 1);

      expect(find.text('Manutenção do carro'), findsOneWidget);
      expect(find.byType(AccountLogo), findsNothing);
    });

    testWidgets('conta desconhecida cai no ícone, e a linha continua', (
      tester,
    ) async {
      // A leitura do mês cita uma conta que o mapa não tem — é o que
      // acontece com uma conta apagada depois do fechamento.
      await pumpHudFooter(
        tester,
        size: const Size(400, 900),
        hud: hudTestState(
          debts: const [
            HudBalanceReading(
              accountId: 'conta-que-nao-existe-mais',
              name: 'Conta apagada',
              balance: -1200,
              color: '#EC7000',
            ),
          ],
        ),
      );

      await openHudSheet(tester, 3);

      expect(find.text('Conta apagada'), findsOneWidget);
      expect(find.byType(AccountLogo), findsNothing);
    });

    testWidgets('a 400 px, a folha com logo continua sem estourar', (
      tester,
    ) async {
      await pumpHudFooter(tester, size: const Size(400, 800));

      await openHudSheet(tester, 2);

      expect(tester.takeException(), isNull);
    });
  });

  group('a folha dos heróis', () {
    testWidgets('cada conta da vida traz a logo e os donos', (tester) async {
      await pumpArena(tester, state: arenaTestState());

      await tester.tap(find.byType(ArenaHpBar).first);
      await arenaFrames(tester);

      expect(find.byType(ArenaHeroesSheet), findsOneWidget);
      expect(find.text('Nubank'), findsOneWidget);

      final logos = _logos(tester);
      expect(logos, isNotEmpty);
      expect(logos.every((logo) => logo.showMembers), isTrue);
    });
  });
}
