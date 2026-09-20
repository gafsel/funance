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

  test('a Home tem UMA entrada para a Arena, e ela empilha a rota', () {
    expect(
      "'/arena'".allMatches(home).length,
      1,
      reason:
          'o endereço aparece UMA vez. A porta é montada por `_arenaEntry` e '
          'usada duas — na AppBar do compacto e no rail do largo —, porque a '
          'Home não tem AppBar no desktop e sem isso o macOS e a web não '
          'teriam como chegar à Arena',
    );
    expect(
      'Icons.shield_outlined'.allMatches(home).length,
      1,
      reason: 'um ícone, definido num lugar só',
    );
    expect(
      home,
      contains("context.push('/arena')"),
      reason:
          'empilhar, e não `go`: quem entra na Arena precisa voltar para a '
          'Home com o botão de voltar',
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
