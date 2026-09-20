import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';

import '../arena/arena_harness.dart';
import '../support/home_harness.dart';
import 'golden_support.dart';

/// A Home com a Arena no topo — claro e escuro, celular e desktop.
///
/// A ordem dos blocos tem teste de posição (`home_v2_test`) e a altura tem
/// teste de medida (`home_height_test`). O que nenhum dos dois vê é a TINTA:
/// duas barras que se opõem só funcionam se o teal dos heróis e o violeta do
/// monstro se separarem nos dois temas, e se o placar continuar legível sobre
/// o azul profundo do bloco. É disso que estes quatro PNGs são a rede.
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
        const JourneyTab(),
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
          ),
          ArenaViewProviders.state.overrideWith(
            (ref) => AsyncValue<ArenaState>.data(state ?? arenaTestState()),
          ),
          ArenaViewProviders.isBusiness.overrideWith((ref) => false),
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
        find.byType(JourneyTab),
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

  for (final tema in Brightness.values) {
    final sufixo = tema == Brightness.dark ? '_escuro' : '';

    testWidgets('golden — o rombo real$sufixo', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 800),
        brightness: tema,
        state: oRombo(),
      );

      await expectLater(
        find.byType(JourneyTab),
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
        find.byType(JourneyTab),
        matchesGoldenFile('images/home_arena_monstro_30$sufixo.png'),
      );
    });
  }
}
