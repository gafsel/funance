import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/features/home/presentation/widgets/arena_tab.dart';

/// A Arena precisa ser ALCANÇÁVEL, e agora ela é a própria abertura do app.
///
/// Os fatos que este teste guarda são de arquivo, não de widget, e é de
/// propósito: nenhum teste deste app constrói o `routerProvider` (ele puxa
/// auth, workspace e convites, e cada um deles puxa o Firebase). A varredura
/// de fonte é a mesma técnica de `design_hygiene_test` e `l10n_hygiene_test`.
///
/// O que MUDOU nesta etapa (decisão 1 do dono): a Arena deixou de ser um
/// bloco no topo da Home e virou a primeira aba inteira. Com isso morreram a
/// tela `/arena` — não há mais o que "abrir em tela cheia", porque a tela
/// cheia é a própria aba — e o cartão que a embrulhava. O ENDEREÇO continua
/// respondendo: ele já circulou em link e notificação, e um deep link que
/// passa a dar 404 é a pior forma de aposentar uma rota.
void main() {
  final router = File('lib/core/router/app_router.dart').readAsStringSync();
  final home = File(
    'lib/features/home/presentation/screens/home_screen.dart',
  ).readAsStringSync();

  test('/arena continua registrada — e redireciona para a Home', () {
    expect(arenaRoutePath, '/arena');
    expect(
      router,
      contains('path: arenaRoutePath'),
      reason: 'a rota usa a constante, não uma string solta que pode divergir',
    );
    expect(
      router,
      contains("GoRoute(path: arenaRoutePath, redirect: (context, state) => '/')"),
      reason:
          'a Arena não tem mais tela própria: o endereço antigo leva para '
          'onde ela está agora, que é a abertura do app',
    );
  });

  test('a primeira aba da Home é a Arena', () {
    // Comparação de TIPOS, e não varredura de texto: um comentário que cite
    // `ArenaTab` daria a aba por montada.
    expect(const ArenaTab().runtimeType, ArenaTab);
    expect(
      home,
      contains('ArenaTab()'),
      reason: 'a aba está montada na tela, e não só escrita no repositório',
    );
    expect(
      home.indexOf('ArenaTab()'),
      lessThan(home.indexOf('OverviewTab()')),
      reason: 'ela é a PRIMEIRA — é por ela que o app abre',
    );
  });

  test('a aba não rola: a cena preenche', () {
    final aba = File(
      'lib/features/home/presentation/widgets/arena_tab.dart',
    ).readAsStringSync();

    expect(
      aba,
      isNot(contains('SingleChildScrollView')),
      reason:
          'a decisão do dono é que não há mais nada para expandir nem para '
          'rolar nesta aba: a cena toma o que sobra entre o placar e o rodapé',
    );
    expect(
      home,
      contains('extendBody: false'),
      reason:
          'com o corpo estendido por baixo da barra inferior, os quatro '
          'ícones do rodapé mensal ficavam escondidos atrás dela',
    );
  });

  test('o que a decisão aposentou não existe mais no código', () {
    // A prova é de ARQUIVO porque a ausência de um símbolo não tem como ser
    // afirmada em Dart: o que não existe não se importa. Código morto que
    // continua compilando é o que mais convida alguém a "reaproveitar" seis
    // meses depois a tela que a gente acabou de aposentar.
    for (final morto in <String>[
      // a Home rolável, com sete blocos empilhados
      'lib/features/home/presentation/widgets/journey_tab.dart',
      // o cartão com título e botão de expandir
      'lib/features/arena/presentation/widgets/arena_home_block.dart',
      // a tela cheia, que virou a própria aba
      'lib/features/arena/presentation/screens/arena_screen.dart',
      // a Party da Visão Geral (decisão 9)
      'lib/features/home/presentation/widgets/team_status_view.dart',
      // e os dois blocos que a Arena já tinha aposentado antes
      'lib/features/home/presentation/widgets/journey_header.dart',
      'lib/features/home/presentation/widgets/home/due_soon_strip.dart',
      'lib/features/home/domain/models/monthly_available_model.dart',
      'lib/features/home/domain/models/due_soon_model.dart',
    ]) {
      expect(File(morto).existsSync(), isFalse, reason: '$morto ressuscitou');
    }
  });

  test('o anel da Party sobreviveu, genérico, em core/widgets', () {
    // Decisão 9, segunda metade: *"NÃO apague o widget de anel circular se
    // for reutilizável"* — a vila do HUD mensal vai montar uma grade no mesmo
    // formato, e a alternativa seria ela nascer com um segundo desenho do
    // mesmo anel.
    expect(
      File('lib/core/widgets/progress_ring_icon.dart').existsSync(),
      isTrue,
    );
  });

  test('a folha de sprites e a licença estão no pacote', () {
    expect(File('assets/arena/kenney_tiny_dungeon.png').existsSync(), isTrue);
    expect(File('assets/arena/LICENSE.md').existsSync(), isTrue);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/arena/'),
      reason: 'sem a pasta declarada, a cena abre preta no aparelho',
    );
  });
}
