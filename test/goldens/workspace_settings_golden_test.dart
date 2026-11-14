// As imagens de referência foram gravadas no macOS. No Linux do CI o texto
// renderiza diferente (1,7% a 2,5% dos pixels), então o CI roda com
// `--exclude-tags golden`; localmente estes testes continuam valendo.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/journey_fakes.dart';
import 'golden_support.dart';

/// A tela de configurações, nos dois tamanhos e nos dois temas.
///
/// Ela não tinha golden nenhum, e é onde mora o item 12 do dono: aparência e
/// som no TOPO, o recorte do topo respeitado e o item de tema vestindo o
/// mesmo tile do resto do menu. Nenhuma dessas três coisas quebra um teste
/// quando some — são ordem, margem e estilo, que é exatamente o que um golden
/// guarda e uma asserção não.
///
/// O recorte de 47 px entra de propósito: é o caso da tela como ABA, sem
/// `AppBar` para empurrar o conteúdo, que era onde o cabeçalho nascia debaixo
/// do relógio do sistema.
const double _notch = 47;

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Brightness brightness,
}) async {
  SharedPreferences.setMockInitialValues({});
  await setGoldenSurface(tester, size);

  await tester.pumpWidget(
    goldenApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(top: _notch)),
          child: const Material(child: WorkspaceSettingsScreen()),
        ),
      ),
      brightness: brightness,
      overrides: [
        ...goldenOverrides(),
        WorkspaceViewProviders.workspace.overrideWith(
          (ref) => TestWorkspaceNotifier(workspaceStateFor()),
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final caso in <({String nome, Size tamanho})>[
    (nome: 'configuracoes', tamanho: Size(400, 900)),
    (nome: 'configuracoes_desktop', tamanho: Size(1300, 900)),
  ]) {
    for (final tema in Brightness.values) {
      final sufixo = tema == Brightness.dark ? '_escuro' : '';

      testWidgets('golden — ${caso.nome}$sufixo', (tester) async {
        await _pump(tester, size: caso.tamanho, brightness: tema);

        await expectLater(
          find.byType(WorkspaceSettingsScreen),
          matchesGoldenFile('images/${caso.nome}$sufixo.png'),
        );
      });
    }
  }
}
