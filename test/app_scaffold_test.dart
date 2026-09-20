import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';
import 'package:funances/features/goal/presentation/screen/goals_screen.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/home/presentation/widgets/home/home_bottom_bar_item.dart';

import 'support/home_harness.dart';

/// A6 / M10 — o esqueleto de tela, no comportamento e não na aparência.
///
/// `AppScaffold` existia e não era usado por nenhuma tela: a auditoria mediu
/// 109 de 130 arquivos de tela sem nenhuma decisão de largura, e nenhuma tela
/// principal limitando a largura de leitura — a 1400px o app mostrava linhas
/// de duzentos caracteres.
///
/// Os testes rodam nos TRÊS breakpoints porque a decisão que ele toma é a de
/// escolher entre navegação lateral e inferior, e essa decisão só existe na
/// travessia de um corte para o outro.

/// Uma largura dentro de cada faixa, com o nome da faixa.
const _larguras = <String, double>{'compact': 400, 'medium': 800, 'wide': 1300};

Future<void> _pump(
  WidgetTester tester,
  Widget widget, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: widget));
  await tester.pump();
}

void main() {
  group('AppScaffold — rail ou barra inferior', () {
    _larguras.forEach((nome, width) {
      testWidgets('$nome: uma navegação, nunca as duas', (tester) async {
        await _pump(
          tester,
          AppScaffold(
            body: const Text('conteúdo'),
            rail: const SizedBox(key: ValueKey('rail'), width: 72),
            bottomBar: const SizedBox(key: ValueKey('barra'), height: 60),
          ),
          width: width,
        );

        final temRail = find
            .byKey(const ValueKey('rail'))
            .evaluate()
            .isNotEmpty;
        final temBarra = find
            .byKey(const ValueKey('barra'))
            .evaluate()
            .isNotEmpty;

        expect(
          temRail,
          AppBreakpoints.of(width).usesRail,
          reason: 'o rail é do desktop',
        );
        expect(
          temRail == temBarra,
          isFalse,
          reason:
              'as duas juntas gastariam a tela duas vezes com a mesma coisa',
        );
      });

      testWidgets('$nome: o botão de lançar acompanha a navegação', (
        tester,
      ) async {
        await _pump(
          tester,
          AppScaffold(
            body: const Text('conteúdo'),
            rail: const SizedBox(width: 72),
            bottomBar: const SizedBox(height: 60),
            launchAction: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
          width: width,
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

        expect(
          scaffold.floatingActionButtonLocation,
          AppBreakpoints.of(width).usesRail
              ? FloatingActionButtonLocation.endFloat
              // Entalhado na barra: é o botão central do app.
              : FloatingActionButtonLocation.centerDocked,
        );
      });
    });

    testWidgets('sem rail declarado, a barra vale em qualquer largura', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppScaffold(
          body: Text('conteúdo'),
          bottomBar: SizedBox(key: ValueKey('barra'), height: 60),
        ),
        width: 1300,
      );

      expect(find.byKey(const ValueKey('barra')), findsOneWidget);
    });
  });

  group('AppContentWidth — a largura de leitura', () {
    _larguras.forEach((nome, width) {
      testWidgets('$nome: respeita a largura máxima do breakpoint', (
        tester,
      ) async {
        await _pump(
          tester,
          Scaffold(
            body: AppContentWidth(
              child: Container(key: const ValueKey('conteudo'), height: 100),
            ),
          ),
          width: width,
        );

        final layout = AppBreakpoints.of(width);
        final medido = tester
            .getSize(find.byKey(const ValueKey('conteudo')))
            .width;
        final teto = layout.contentMaxWidth.isFinite
            ? layout.contentMaxWidth
            : width;

        expect(medido, lessThanOrEqualTo(teto));
        expect(
          medido,
          lessThanOrEqualTo(width - AppSpacing.gutter * 2),
          reason: 'o gutter de 16 vale em QUALQUER largura',
        );
      });
    });

    testWidgets('o conteúdo fica centrado quando sobra espaço', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: AppContentWidth(
            child: Container(key: const ValueKey('conteudo'), height: 100),
          ),
        ),
        width: 1300,
      );

      final caixa = tester.getRect(find.byKey(const ValueKey('conteudo')));

      expect(
        caixa.left,
        closeTo(1300 - caixa.right, 1),
        reason: 'a coluna de leitura encostada à esquerda deixa a tela torta',
      );
    });

    testWidgets('reading aperta mais que o padrão', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: AppContentWidth.reading(
            child: Container(key: const ValueKey('conteudo'), height: 100),
          ),
        ),
        width: 1300,
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('conteudo'))).width,
        lessThanOrEqualTo(560),
        reason: 'formulário e texto corrido leem pior que uma tabela',
      );
    });
  });

  /// A6 — a adoção. `AppScaffold` existia e nenhuma tela usava.
  group('as telas principais usam o esqueleto', () {
    _larguras.forEach((nome, width) {
      testWidgets('$nome: a Home escolhe UMA navegação', (tester) async {
        await pumpHome(
          tester,
          const HomeScreen(),
          overrides: homeOverrides(),
          size: Size(width, 900),
        );

        expect(find.byType(AppScaffold), findsWidgets);

        final usaRail = AppBreakpoints.of(width).usesRail;
        expect(
          find.byType(NavigationRail),
          usaRail ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(HomeBottomBarItem),
          usaRail ? findsNothing : findsWidgets,
          reason:
              'rail e barra inferior eram decididos por três `isLargeScreen` '
              'independentes, e nada garantia que os três concordassem',
        );
      });
    });

    testWidgets('Contas usa o esqueleto', (tester) async {
      await pumpHome(
        tester,
        const AccountManagementScreen(),
        overrides: homeOverrides(),
        size: const Size(800, 900),
      );

      expect(find.byType(AppScaffold), findsOneWidget);
    });

    testWidgets('Metas usa o esqueleto', (tester) async {
      await pumpHome(
        tester,
        const GoalsScreen(),
        overrides: homeOverrides(),
        size: const Size(800, 900),
      );

      expect(find.byType(AppScaffold), findsOneWidget);
    });
  });
}
