import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';
import 'package:funances/features/home/presentation/widgets/home/workspace_selector.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';

import '../arena/arena_harness.dart';
import '../arena/hud_harness.dart';
import '../support/home_harness.dart';
import '../support/journey_fakes.dart';
import 'golden_support.dart';

/// A Home, que agora É a Arena — celular e desktop.
///
/// **Sem par claro/escuro.** Esta aba não tem tema: a cena tem PALETA
/// PRÓPRIA. O fundo é `surfaceDeep` nos dois modos, a tinta do HUD é
/// `inkInverse`/`inkInverse2` nos dois, os sprites são pixel art com as cores
/// do Kenney, e o véu é a mesma chapa de `surfaceDeep`. O QA comparou os
/// PNGs: os pares `_escuro` diferiam em 26 pixels do total — o cursor do
/// carregamento de um deles —, ou seja, eram cópias caras de manter e de
/// revisar.
///
/// Onde o tema AINDA muda alguma coisa é nas FOLHAS que a cena abre — contas,
/// compromissos, missões, Bússola —, e essas têm os goldens delas
/// (`arena_sheets_golden_test`, `hud_sheets_golden_test`), nos dois temas.
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
  bool reduceMotion = false,
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
        reduceMotion: reduceMotion,
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
    // A tela BAIXA, que é onde o QA achou a coluna de ícones por cima do
    // mago. Aqui ela prova o contrário: a faixa de ícones fica no véu do
    // topo, e os bonecos continuam inteiros embaixo dela.
    (
      nome: 'home_arena_celular_baixo',
      tamanho: const Size(400, 544),
      tema: Brightness.light,
    ),
    (
      nome: 'home_arena_desktop',
      tamanho: const Size(1300, 900),
      tema: Brightness.light,
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

  /// A barra dos HERÓIS vazia: o caixa chegou a zero no meio da semana.
  ///
  /// É o estado que o alarme existe para mostrar, e ele não é o do rombo —
  /// no rombo a barra está CHEIA e coberta de hachura densa. Aqui não há o
  /// que hachurar: a vida acabou, e uma barra vazia parada é indistinguível
  /// de uma barra que ninguém desenhou.
  ///
  /// A captura é com "reduzir movimento" LIGADO, e isso é sobre o PNG e não
  /// sobre o produto: o pulso é um ciclo por segundo, e fotografá-lo em
  /// movimento daria uma opacidade diferente a cada execução. Com o pulso
  /// parado sobra o que ele tem de dizer quando o usuário pediu menos
  /// movimento — calha vermelha cheia e contorno mais grosso.
  ArenaState semCaixa() => arenaTestState(
    initialBalance: 5200,
    currentBalance: 0,
    day: ArenaDay.friday,
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

  /// A morte AO VIVO, depois de tudo assentar.
  ///
  /// O golden do estado parado já existia e mostrava o cadáver certo; o
  /// defeito que o QA achou só aparece no CAMINHO — o susto branco entrava
  /// por cima do cinza e, ao terminar, deixava o filtro dele no lugar. Esta
  /// captura é a do caminho.
  testWidgets('golden — o monstro morre na tela', (tester) async {
    await loadAppFonts();

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final fonte = StateProvider<ArenaState>((ref) => arenaTestState());

    await tester.runAsync(() async {
      await tester.pumpWidget(
        homeApp(
          const ArenaTab(),
          overrides: [
            ...homeOverrides(
              missions: homeTypicalMissions(),
              pendingAutomatic: homeTypicalPending(),
              lastInsight: homeTypicalInsight(),
              health: const FinancialHealth(
                score: 72,
                tier: FreedomTier.guardiao,
              ),
            ),
            ArenaViewProviders.state.overrideWith(
              (ref) => AsyncValue<ArenaState>.data(ref.watch(fonte)),
            ),
            ArenaViewProviders.isBusiness.overrideWith((ref) => false),
            HudViewProviders.state.overrideWith(
              (ref) => AsyncValue<HudState>.data(hudTestState()),
            ),
          ],
        ),
      );

      for (var i = 0; i < 14; i++) {
        await tester.pump(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    });

    // A semana fecha com a cena na frente.
    tester.element(find.byType(ArenaTab));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ArenaTab)),
    );
    container.read(fonte.notifier).state = arenaTestState(
      currentBalance: 4820,
      commitments: [arenaTestCommitment(paid: true)],
    );

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    await expectLater(
      find.byType(ArenaTab),
      matchesGoldenFile('images/home_arena_morte_ao_vivo.png'),
    );
  });

  /// O TOPO da Home: o seletor de cofre na AppBar.
  ///
  /// Faltava captura do cabeçalho, e é onde mora a correção que o dono
  /// pediu: *"o título do workspace no app bar ficou pressionado por causa
  /// do tipo do workspace"*. A 360 px, com um nome de cofre longo, o PNG
  /// mostra quem ficou com o espaço — o nome inteiro, e o tipo como figura.
  testWidgets('golden — home_topo', (tester) async {
    await loadAppFonts();

    tester.view.physicalSize = const Size(360, 120);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cofre = WorkspaceModel(
      id: 'w1',
      // Um nome LONGO de propósito: com a palavra "Pessoal" dividindo a
      // linha, é ele que aparecia cortado.
      name: 'Casa da Praia do Norte',
      type: WorkspaceType.personal,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      homeApp(
        const SizedBox.shrink(),
        overrides: [
          ...homeOverrides(),
          WorkspaceViewProviders.workspace.overrideWith(
            (ref) => TestWorkspaceNotifier(
              WorkspaceState(
                currentWorkspace: cofre,
                availableWorkspaces: [cofre],
                initialLoadDone: true,
              ),
            ),
          ),
        ],
        topo: const WorkspaceSelector(isNavigationRail: false),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppBar),
      matchesGoldenFile('images/home_topo.png'),
    );
  });

  for (final caso
      in <({String nome, ArenaState Function() estado, bool parado})>[
        (nome: 'home_arena_derrotado', estado: derrotado, parado: false),
        (nome: 'home_arena_rombo', estado: oRombo, parado: false),
        (nome: 'home_arena_monstro_30', estado: quaseVencida, parado: false),
        (nome: 'home_arena_sem_caixa', estado: semCaixa, parado: true),
      ]) {
    testWidgets('golden — ${caso.nome}', (tester) async {
      await _pump(
        tester,
        size: const Size(400, 800),
        brightness: Brightness.light,
        state: caso.estado(),
        reduceMotion: caso.parado,
      );

      await expectLater(
        find.byType(ArenaTab),
        matchesGoldenFile('images/${caso.nome}.png'),
      );
    });
  }
}
