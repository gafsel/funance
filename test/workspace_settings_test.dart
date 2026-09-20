import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/theme/theme_mode_provider.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/appearance_section.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/journey_fakes.dart';

/// A tela de configurações depois do pedido do dono (2026-09-20, item 12):
/// "leve as configs de aparência e som pro topo e tome cuidado com o
/// safearea. use uma estilização que combine com o menu... hoje essas duas
/// configs estão muito diferentes do restante".
///
/// As três afirmações que este arquivo guarda:
///
/// 1. **a ordem** — aparência e som vêm ANTES de perfil, geral, dados e time,
///    nas duas montagens (lista no celular, grade no desktop);
/// 2. **o recorte do topo** — como ABA a tela não tem `AppBar` para empurrar
///    o conteúdo, e o primeiro cabeçalho nascia debaixo do relógio do
///    sistema. O recorte vai como padding da LISTA, para o conteúdo rolar por
///    baixo dele em vez de bater numa parede;
/// 3. **o tile** — o item de tema virou um `ListTile` com ícone na mesma
///    coluna dos outros, e o seletor se alinha ao título dele.

/// A altura do recanto de um celular com notch.
const double _notch = 47;

Widget _app({Brightness brightness = Brightness.light, double topPadding = 0}) {
  return ProviderScope(
    overrides: [
      WorkspaceViewProviders.workspace.overrideWith(
        (ref) => TestWorkspaceNotifier(workspaceStateFor()),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: EdgeInsets.only(top: topPadding)),
          // Sem `Scaffold` e sem `AppBar`: é assim que a Home monta a tela
          // como ABA, e é o caso em que o recorte do topo não tem quem o
          // resolva.
          child: const Material(child: WorkspaceSettingsScreen()),
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(400, 900),
  Brightness brightness = Brightness.light,
  double topPadding = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(brightness: brightness, topPadding: topPadding));
  await tester.pumpAndSettle();
}

/// A posição vertical do primeiro widget que casa com [finder].
double _topo(WidgetTester tester, Finder finder) =>
    tester.getTopLeft(finder.first).dy;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('aparência e som no topo', () {
    testWidgets('celular: antes de perfil, dados e time', (tester) async {
      await _pump(tester);

      // Não basta "estar na tela": a seção estava no fim e ninguém a achava.
      // O que se afirma aqui é a ORDEM.
      expect(
        _topo(tester, find.text('APARÊNCIA')),
        lessThan(_topo(tester, find.text('PERFIL'))),
      );
      expect(
        _topo(tester, find.text('APARÊNCIA')),
        lessThan(_topo(tester, find.text('DADOS'))),
      );
    });

    testWidgets('desktop: antes da grade de cartões', (tester) async {
      await _pump(tester, size: const Size(1300, 900));

      expect(
        _topo(tester, find.byType(AppearanceSection)),
        lessThan(_topo(tester, find.byType(GridView))),
      );
    });
  });

  group('o recorte do topo', () {
    testWidgets('como aba, o conteúdo começa abaixo do notch', (tester) async {
      await _pump(tester, topPadding: _notch);

      // O primeiro cabeçalho nascia em cima do relógio do sistema. Ele tem de
      // começar abaixo do recorte — e o `SectionHeader.label` já traz um
      // respiro próprio, então a conta é ">=" e não "==".
      expect(
        _topo(tester, find.text('APARÊNCIA')),
        greaterThanOrEqualTo(_notch),
      );
    });

    testWidgets('sem recorte, nada de espaço morto no topo', (tester) async {
      await _pump(tester);

      // A outra metade: a tela aberta por ROTA tem `AppBar`, o `Scaffold` já
      // consumiu o recanto e `paddingOf` devolve zero. Somar o recorte duas
      // vezes deixaria uma faixa vazia no topo.
      expect(_topo(tester, find.text('APARÊNCIA')), lessThan(_notch));
    });
  });

  group('o mesmo tile do resto do menu', () {
    testWidgets('o tema tem ícone na mesma coluna dos outros itens', (
      tester,
    ) async {
      await _pump(tester);

      // Era um bloco solto: título em `titleMedium`, sem ícone, numa margem
      // própria, ao lado de uma lista inteira de `ListTile`.
      final tema = find.ancestor(
        of: find.text('Tema'),
        matching: find.byType(ListTile),
      );
      expect(tema, findsOneWidget);

      final iconeTema = tester.getTopLeft(
        find.descendant(
          of: tema,
          matching: find.byIcon(Icons.brightness_6_outlined),
        ),
      );
      final iconePerfil = tester.getTopLeft(find.byIcon(Icons.person_outline));

      expect(iconeTema.dx, iconePerfil.dx);
    });

    testWidgets('o seletor de tema se alinha ao título do item', (
      tester,
    ) async {
      await _pump(tester);

      final seletor = tester.getTopLeft(
        find.byType(SegmentedButton<ThemeMode>),
      );

      expect(seletor.dx, AppearanceSection.tileTextInset);
    });
  });

  group('cabe nos dois tamanhos e nos dois temas', () {
    for (final tamanho in <Size>[Size(400, 900), Size(1300, 900)]) {
      for (final tema in Brightness.values) {
        testWidgets('${tamanho.width.toInt()} px, tema ${tema.name}', (
          tester,
        ) async {
          await _pump(
            tester,
            size: tamanho,
            brightness: tema,
            topPadding: _notch,
          );

          // O seletor de três segmentos com ícone e rótulo é o controle mais
          // largo da tela, e ele passou a viver recuado em 72 px. Se ele não
          // couber, o `SegmentedButton` estoura em vez de encolher.
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
