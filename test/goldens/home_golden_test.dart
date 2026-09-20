import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';

import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';

import '../arena/arena_harness.dart';
import '../arena/hud_harness.dart';
import '../support/home_harness.dart';
import 'golden_support.dart';

/// A Home, que agora É a Arena — claro e escuro, celular e desktop.
///
/// O que está na tela tem teste de estrutura (`home_arena_test`) e a altura
/// tem teste de medida (`home_height_test`). O que nenhum dos dois vê é a
/// TINTA: duas barras que se opõem só funcionam se o teal dos heróis e o
/// violeta do monstro se separarem nos dois temas; a coluna de ícones da
/// lateral só funciona se ela ler sobre a areia do chão e sobre o tijolo da
/// parede; e o monstro morto só lê como morto se o cinza dele se separar do
/// cenário. É disso que estes PNGs são a rede.
///
/// O estado da Arena é FIXO (`arenaTestState`): o golden não pode depender do
/// dia em que roda, e a cena do Flame depende de um relógio de verdade para
/// decodificar a folha de sprites — daí o `runAsync`.

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Brightness brightness,
  ArenaState? state,
}) async {
  await loadAppFonts();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      homeApp(
        const ArenaTab(),
        brightness: brightness,
        overrides: [
          ...homeOverrides(
            missions: homeTypicalMissions(),
            installments: homeTypicalInstallments(),
            goals: homeTypicalGoals(),
            categories: homeTypicalCategories,
            summary: homeTypicalSummary(),
            pendingAutomatic: homeTypicalPending(),
            lastInsight: homeTypicalInsight(),
            // O índice publicado: sem ele o ícone da bússola sai apagado, e
            // o estado normal da cena é justamente o de ter pontuação.
            health: const FinancialHealth(
              score: 72,
              tier: FreedomTier.guardiao,
            ),
          ),
          ArenaViewProviders.state.overrideWith(
            (ref) => AsyncValue<ArenaState>.data(state ?? arenaTestState()),
          ),
          ArenaViewProviders.isBusiness.overrideWith((ref) => false),
          // O rodapé MENSAL, com os números do cofre real. Ele entra no
          // golden porque a faixa deixou de ser reservada e vazia: os quatro
          // ícones são agora a última linha da cena, e é aqui que se prova
          // que eles cabem em 400 px e continuam legíveis no escuro.
          HudViewProviders.state.overrideWith(
            (ref) => AsyncValue<HudState>.data(hudTestState()),
          ),
        ],
      ),
    );

    // A folha de sprites é decodificada pelo `decodeImageFromList`, que
    // depende do relógio de verdade: sem estes quadros reais a cena aparece
    // vazia no PNG.
    for (var i = 0; i < 14; i++) {
      await tester.pump(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  });

  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

void main() {
  final casos = <({String nome, Size tamanho, Brightness tema})>[
    (
      nome: 'home_arena_celular',
      tamanho: const Size(400, 800),
      tema: Brightness.light,
    ),
    (
      nome: 'home_arena_celular_escuro',
      tamanho: const Size(400, 800),
      tema: Brightness.dark,
    ),
    (
      nome: 'home_arena_desktop',
      tamanho: const Size(1300, 900),
      tema: Brightness.light,
    ),
    (
      nome: 'home_arena_desktop_escuro',
      tamanho: const Size(1300, 900),
      tema: Brightness.dark,
    ),
  ];

  for (final caso in casos) {
    testWidgets('golden — ${caso.nome}', (tester) async {
      await _pump(tester, size: caso.tamanho, brightness: caso.tema);

      await expectLater(
        find.byType(ArenaTab),
        matchesGoldenFile('images/${caso.nome}.png'),
      );
    });
  }

  /// A semana quase vencida: o monstro com ~30% do HP.
  ///
  /// É o único estado em que a barra do MONSTRO mostra calha — cheia ou
  /// vazia, ela não prova nada sobre a moldura e sobre a cor do vazio. E é a
  /// barra espelhada: o bico do chanfro e o dano-fantasma correm para o outro
  /// lado, e nenhum dos dois tinha captura até agora.
  ///
  /// R$ 640 de R$ 2.140 — 29,9%.
  ArenaState quaseVencida() => arenaTestState(
    commitments: [
      arenaTestCommitment(
        id: 'cartao',
        description: 'Fatura do cartão',
        amount: 640,
        dayOffset: -9,
        overdue: true,
      ),
      arenaTestCommitment(paid: true),
      arenaTestCommitment(
        id: 'internet',
        description: 'Internet',
        amount: 180,
        dayOffset: 2,
        paid: true,
      ),
      arenaTestCommitment(
        id: 'academia',
        description: 'Academia',
        amount: 120,
        dayOffset: -1,
        paid: true,
      ),
    ],
  );

  /// O RETRATO REAL do cofre do dono, lido da base em 2026-09-20 (domingo):
  /// R\$ 3.115,02 em caixa contra R\$ 12.122,33 de compromisso, sendo
  /// R\$ 8.310,55 já vencidos. A barra dos heróis está CHEIA — a semana acabou
  /// de começar e nada saiu — e é exatamente por isso que esta captura
  /// existe: sem o selo do rombo e sem a hachura densa, ela mostra uma
  /// situação tranquila.
  ArenaState oRombo() => arenaTestState(
    initialBalance: 3115.02,
    currentBalance: 3115.02,
    day: ArenaDay.sunday,
    commitments: [
      arenaTestCommitment(
        id: 'fatura',
        description: 'Fatura [Bárbara] Cartão Nubank',
        amount: 8300.55,
        dayOffset: -3,
        overdue: true,
      ),
      arenaTestCommitment(
        id: 'c6',
        description: 'Seguranca Conta C6',
        amount: 10,
        dayOffset: -4,
        overdue: true,
      ),
      arenaTestCommitment(
        id: 'emprestimo',
        description: 'Pagamento de empréstimo itaú',
        amount: 3811.78,
        dayOffset: 2,
      ),
    ],
  );

  /// A semana VENCIDA: o monstro no chão.
  ///
  /// Decisão 2 do dono. Até aqui o bicho encolhia e sumia, e a captura da
  /// semana ganha mostrava uma arena vazia. Este PNG é o que prova as três
  /// coisas que dizem "morto" sem arte nova: o corpo tombado, o cinza por
  /// luminância (que funciona inclusive sobre o demônio vermelho) e o X. Mais
  /// a barra do monstro zerada e o selo "Derrotado" no lugar de sempre.
  ArenaState derrotado() => arenaTestState(
    currentBalance: 4820,
    commitments: [
      arenaTestCommitment(paid: true),
      arenaTestCommitment(
        id: 'luz',
        description: 'Luz',
        amount: 180,
        dayOffset: 2,
        paid: true,
      ),
    ],
  );

  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — o monstro morto$sufixo', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 800),
        brightness: tema,
        state: derrotado(),
      );

      await expectLater(
        find.byType(ArenaTab),
        matchesGoldenFile('images/home_arena_derrotado$sufixo.png'),
      );
    });

    testWidgets('golden — o rombo real$sufixo', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 800),
        brightness: tema,
        state: oRombo(),
      );

      await expectLater(
        find.byType(ArenaTab),
        matchesGoldenFile('images/home_arena_rombo$sufixo.png'),
      );
    });

    testWidgets('golden — monstro a 30% de vida$sufixo', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 800),
        brightness: tema,
        state: quaseVencida(),
      );

      await expectLater(
        find.byType(ArenaTab),
        matchesGoldenFile('images/home_arena_monstro_30$sufixo.png'),
      );
    });
  }
}
