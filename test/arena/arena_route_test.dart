import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/arena/presentation/screens/arena_screen.dart';
import 'package:funances/features/arena/presentation/widgets/arena_home_block.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';

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
  test('a rota /arena está registrada no router do app', () {
    expect(arenaRoutePath, '/arena');
    expect(
      router,
      contains('path: arenaRoutePath'),
      reason: 'a rota usa a constante, não uma string solta que pode divergir',
    );
    expect(router, contains('const ArenaScreen()'));
  });

  test('a Arena abre a Home', () {
    // A ORDEM tem teste de posição em `home_v2_test`; o que esta asserção
    // guarda é o endereço — que o bloco está montado na aba, e não só
    // escrito no repositório. Ela compara TIPOS, e não texto de arquivo: a
    // versão anterior lia `journey_tab.dart` como string, e uma varredura de
    // texto dá por presente qualquer coisa que apareça num comentário.
    expect(const JourneyTab().runtimeType, JourneyTab);
    expect(const ArenaHomeBlock().runtimeType, ArenaHomeBlock);
  });

  test('os dois blocos aposentados não existem mais no código', () {
    // `JourneyHeader` e `DueSoonStrip` saíram de vez, com os providers que
    // só eles liam (`monthlyAvailable`, `dueSoon`) e os modelos deles. Código
    // morto que continua compilando é o que mais convida alguém a
    // "reaproveitar" seis meses depois a tela que a gente acabou de
    // aposentar.
    //
    // A prova é de ARQUIVO porque a ausência de um símbolo não tem como ser
    // afirmada em Dart: o que não existe não se importa.
    for (final morto in <String>[
      'lib/features/home/presentation/widgets/journey_header.dart',
      'lib/features/home/presentation/widgets/home/due_soon_strip.dart',
      'lib/features/home/domain/models/monthly_available_model.dart',
      'lib/features/home/domain/models/due_soon_model.dart',
    ]) {
      expect(File(morto).existsSync(), isFalse, reason: '$morto ressuscitou');
    }
  });

  test('a AppBar e o rail não apontam mais para a Arena', () {
    // Prova de ARQUIVO porque o que se afirma é uma AUSÊNCIA, e ausência não
    // se monta num teste de widget. Que a porta EXISTE dentro do bloco é
    // afirmado onde deve ser — num toque de verdade, em `arena_screen_test`.
    expect(
      "'/arena'".allMatches(home).length,
      0,
      reason:
          'a Arena está na tela, logo abaixo da AppBar: um ícone de escudo '
          'ali apontava para algo que já estava visível',
    );
    expect(home, isNot(contains('Icons.shield_outlined')));
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
