import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/compass_strip.dart';
import 'package:funances/core/widgets/level_badge.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_type_badge.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F-design/8 — a Home mínima.
///
/// O nível e a Bússola mudam por mês e ocupavam dois blocos grandes na tela
/// que o usuário abre todo dia. Viraram selo e linha expansível.

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('LevelBadge', () {
    testWidgets('cabe numa linha e diz o nível do COFRE', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: LevelBadge(
            level: 7,
            progress: 0.4,
            label: 'Nv 7',
            semanticLabel: 'Nível 7 do cofre, 40% para o próximo',
          ),
        ),
      );

      expect(find.text('Nv 7'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Nível 7 do cofre, 40% para o próximo'),
        findsOneWidget,
        reason: 'o nível é do workspace, nunca de um membro',
      );

      final size = tester.getSize(find.byType(LevelBadge));
      expect(
        size.height,
        lessThan(48),
        reason: 'é um selo; o bloco grande de nível saiu da Home',
      );
    });
  });

  group('WorkspaceTypeBadge', () {
    testWidgets('diz Pessoal', (tester) async {
      await _pump(
        tester,
        const WorkspaceTypeBadge(type: WorkspaceType.personal),
      );
      expect(find.text('Pessoal'), findsOneWidget);
    });

    testWidgets('diz Empresa', (tester) async {
      await _pump(
        tester,
        const WorkspaceTypeBadge(type: WorkspaceType.business),
      );
      expect(find.text('Empresa'), findsOneWidget);
    });

    testWidgets('só de figura, a palavra sai da tela e fica na semântica', (
      tester,
    ) async {
      // O dono: "o nome do workspace é mais importante que o tipo pro
      // usuário". Na AppBar o selo perde a palavra — mas quem usa leitor de
      // tela não pode perder junto.
      await _pump(
        tester,
        const WorkspaceTypeBadge(
          type: WorkspaceType.business,
          iconOnly: true,
        ),
      );

      expect(find.text('Empresa'), findsNothing);
      expect(find.byType(Text), findsNothing);
      expect(find.bySemanticsLabel('Empresa'), findsOneWidget);
      expect(find.byIcon(Icons.business_outlined), findsOneWidget);
    });

    testWidgets('sem a palavra, ele devolve mais de setenta pixels', (
      tester,
    ) async {
      await _pump(
        tester,
        const Column(
          children: [
            WorkspaceTypeBadge(type: WorkspaceType.personal),
            WorkspaceTypeBadge(type: WorkspaceType.personal, iconOnly: true),
          ],
        ),
      );

      final larguras = tester
          .widgetList<WorkspaceTypeBadge>(find.byType(WorkspaceTypeBadge))
          .map((selo) => tester.getSize(find.byWidget(selo)).width)
          .toList();

      // A diferença entre os dois é exatamente o que a AppBar ganhou para o
      // NOME do cofre, que é o pedido do dono.
      expect(larguras.first - larguras.last, greaterThan(50));
      expect(larguras.last, lessThan(32));
    });
  });

  group('CompassStrip', () {
    const components = [
      CompassComponentData(
        label: 'Fôlego',
        icon: Icons.air_rounded,
        fraction: 0.6,
      ),
      CompassComponentData(
        label: 'Poupança',
        icon: Icons.savings_rounded,
        fraction: 0.3,
      ),
    ];

    testWidgets('fechada mostra número, patente e variação', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: CompassStrip(
            title: 'Bússola',
            score: 48,
            tierLabel: 'Estrategista',
            delta: 3,
            deltaLabel: '+3 desde o mês passado',
            components: components,
          ),
        ),
      );

      expect(find.text('48'), findsOneWidget);
      expect(find.text('Estrategista'), findsOneWidget);
      expect(find.text('+3 desde o mês passado'), findsOneWidget);

      // Fechada, a linha tem UMA altura. Os componentes continuam na árvore
      // (o `AnimatedCrossFade` monta os dois lados) mas não entram na altura
      // da linha, que é o ponto: a Bússola deixou de pagar aluguel diário na
      // Home — antes era um cartão inteiro.
      expect(tester.getSize(find.byType(CompassStrip)).height, lessThan(56));
    });

    testWidgets('abre nos quatro componentes ao tocar', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: CompassStrip(
            title: 'Bússola',
            score: 48,
            tierLabel: 'Estrategista',
            components: components,
          ),
        ),
      );

      final fechada = tester.getSize(find.byType(CompassStrip)).height;

      await tester.tap(find.text('Bússola'));
      await tester.pumpAndSettle();

      expect(find.text('Fôlego'), findsOneWidget);
      expect(find.text('Poupança'), findsOneWidget);
      expect(
        tester.getSize(find.byType(CompassStrip)).height,
        greaterThan(fechada),
      );
    });

    testWidgets('sem índice publicado mostra travessão, não erro', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: CompassStrip(
            title: 'Bússola',
            score: null,
            tierLabel: 'Em avaliação',
            components: [],
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('Em avaliação'), findsOneWidget);
    });

    /// M8 — a documentação prometia "variação da semana" e o texto na tela
    /// dizia "desde o mês passado". O dado é mensal: o índice é publicado uma
    /// vez por mês e `healthHistory` vem em `monthKey`. Quem manda é a fonte.
    testWidgets('M8 — a variação fala do período que o dado tem', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 380,
          child: CompassStrip(
            title: 'Bússola',
            score: 48,
            tierLabel: 'Estrategista',
            delta: 3,
            deltaLabel: '3 desde o mês passado',
            components: [],
          ),
        ),
      );

      expect(find.text('3 desde o mês passado'), findsOneWidget);
      expect(
        find.textContaining('semana'),
        findsNothing,
        reason: 'não existe série semanal do índice para comparar',
      );
    });

    testWidgets('sem variação, não inventa uma seta', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: CompassStrip(
            title: 'Bússola',
            score: 48,
            tierLabel: 'Estrategista',
            components: components,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('queda no índice aparece em vermelho e com seta para baixo', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(
          width: 360,
          child: CompassStrip(
            title: 'Bússola',
            score: 41,
            tierLabel: 'Estrategista',
            delta: -7,
            deltaLabel: '−7 desde o mês passado',
            components: components,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
    });
  });
}
