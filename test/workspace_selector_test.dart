import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/home/presentation/widgets/home/workspace_selector.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_type_badge.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'support/journey_fakes.dart';

/// O seletor de cofre da AppBar.
///
/// O dono, olhando o topo da Home: *"o título do workspace no app bar ficou
/// pressionado por causa do tipo do workspace… talvez seja melhor manter
/// apenas a logo do tipo e não o nome do tipo… o nome do workspace é mais
/// importante que o tipo pro usuário"*.
///
/// A conta é de espaço: numa barra de 360 px, a palavra "Pessoal" dentro de
/// uma pílula custava perto de setenta pixels, e quem pagava por eles era o
/// nome do cofre — que aparecia cortado em "Casa da Praia…" onde cabia
/// inteiro.

WorkspaceState _estado(String nome, [WorkspaceType tipo = WorkspaceType.personal]) {
  final workspace = WorkspaceModel(
    id: 'w1',
    name: nome,
    type: tipo,
    createdAt: DateTime(2026, 1, 1),
  );

  return WorkspaceState(
    currentWorkspace: workspace,
    availableWorkspaces: [workspace],
    initialLoadDone: true,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required String nome,
  double largura = 360,
  WorkspaceType tipo = WorkspaceType.personal,
}) async {
  tester.view.physicalSize = Size(largura, 200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        WorkspaceViewProviders.workspace.overrideWith(
          (ref) => TestWorkspaceNotifier(_estado(nome, tipo)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('pt'),
        home: Scaffold(
          appBar: AppBar(
            title: const WorkspaceSelector(isNavigationRail: false),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o selo do tipo não tem texto — só a figura', (tester) async {
    await _pump(tester, nome: 'Casa');

    expect(find.byType(WorkspaceTypeBadge), findsOneWidget);
    expect(find.text('Pessoal'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(WorkspaceTypeBadge),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    // A palavra continua existindo para quem não vê a figura. A busca é por
    // PEDAÇO do rótulo: dentro do botão do seletor, o nó de semântica é um
    // só — "Casa" e "Pessoal" chegam juntos ao leitor de tela, que é
    // exatamente como o par deve ser lido.
    expect(find.bySemanticsLabel(RegExp('Pessoal')), findsOneWidget);
  });

  testWidgets('a empresa também: figura, e a palavra na semântica', (
    tester,
  ) async {
    await _pump(tester, nome: 'Benav', tipo: WorkspaceType.business);

    expect(find.text('Empresa'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Empresa')), findsOneWidget);
  });

  testWidgets('a 360 px o nome fica com a barra quase inteira', (
    tester,
  ) async {
    const nome = 'Casa da Praia do Norte';

    await _pump(tester, nome: nome);

    final caixa = tester.getSize(find.text(nome));

    // A medida é em PIXELS, e não em caracteres: a fonte do teste desenha
    // todo glifo com a largura do corpo (16 px em `titleMedium`), e contar
    // letras aqui mediria a fonte do teste, não o layout. O que o layout
    // promete é a LARGURA — 272 dos 360 px da barra, contra os ~165 que
    // sobravam quando a palavra "Pessoal" dividia a linha.
    expect(caixa.width, greaterThanOrEqualTo(260));
    expect(tester.takeException(), isNull);
  });

  testWidgets('o nome fica com o espaço que era do selo', (tester) async {
    await _pump(tester, nome: 'Casa');

    final selo = tester.getSize(find.byType(WorkspaceTypeBadge)).width;

    // O selo com a palavra passava dos 70 px; sem ela, ele é um botão
    // redondo. Tudo o que ele devolveu foi para o nome.
    expect(selo, lessThan(32));
  });
}
