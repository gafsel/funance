import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/screens/arena_screen.dart';

/// A Arena precisa ser ALCANÇÁVEL, e por exatamente uma porta.
///
/// Os dois fatos que este teste guarda são de arquivo, não de widget, e é de
/// propósito: nenhum teste deste app constrói o `routerProvider` (ele puxa
/// auth, workspace e convites, e cada um deles puxa o Firebase). A varredura
/// de fonte é a mesma técnica de `design_hygiene_test` e `l10n_hygiene_test`
/// — e é o que impede a POC de existir só no código, sem porta de entrada.
///
/// O que MUDOU nesta etapa: a porta saiu da `AppBar` e do rail. A Arena não é
/// mais um destino ao lado da Home — ela **é** o topo da Home, e o ícone de
/// escudo ao lado do nível apontava para uma tela que já estava logo abaixo.
/// A rota continua existindo, com a porta dentro do próprio bloco.
void main() {
  final router = File('lib/core/router/app_router.dart').readAsStringSync();
  final home = File(
    'lib/features/home/presentation/screens/home_screen.dart',
  ).readAsStringSync();
  final journey = File(
    'lib/features/home/presentation/widgets/journey_tab.dart',
  ).readAsStringSync();
  final block = File(
    'lib/features/arena/presentation/widgets/arena_home_block.dart',
  ).readAsStringSync();

  test('a rota /arena está registrada no router do app', () {
    expect(arenaRoutePath, '/arena');
    expect(
      router,
      contains('path: arenaRoutePath'),
      reason: 'a rota usa a constante, não uma string solta que pode divergir',
    );
    expect(router, contains('const ArenaScreen()'));
  });

  test('a Arena é o PRIMEIRO bloco da Home', () {
    expect(journey, contains('ArenaHomeBlock()'));

    final arena = journey.indexOf('ArenaHomeBlock()');
    final missoes = journey.indexOf('WeeklyMissionsView(');
    expect(arena, greaterThan(-1));
    expect(
      arena,
      lessThan(missoes),
      reason: 'a Arena abre a Home; as missões vêm depois',
    );
  });

  test(
    'o cabeçalho "quanto sobra" e a faixa de vencimentos saíram da Home',
    () {
      expect(
        journey,
        isNot(contains('JourneyHeader()')),
        reason: 'o número virou a linha "livre" do detalhe das contas',
      );
      expect(
        journey,
        isNot(contains('DueSoonStrip()')),
        reason: 'a lista virou o "próximo golpe" do detalhe do monstro',
      );
    },
  );

  test('a porta para a tela cheia mora no bloco, e não na AppBar', () {
    expect(
      "'/arena'".allMatches(home).length,
      0,
      reason:
          'a AppBar e o rail não apontam mais para a Arena: ela está na tela, '
          'logo abaixo deles',
    );
    expect(
      home,
      isNot(contains('Icons.shield_outlined')),
      reason: 'o ícone de escudo foi embora junto com a porta',
    );
    expect(
      block,
      contains('context.push(arenaRoutePath)'),
      reason:
          'empilhar, e não `go`: quem abre a Arena inteira precisa voltar '
          'para a Home com o botão de voltar',
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
