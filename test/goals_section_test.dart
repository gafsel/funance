import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/provider.dart';
import 'package:funances/features/goal/presentation/widgets/goals_section.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F2.5 (QA) — uma meta encerrada não pode aparecer no meio das que ainda
/// estão correndo, e uma meta de redução que estourou o teto não pode ser
/// anunciada como concluída.
const _categoria = CategoryModel(
  id: 'cat1',
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#EF5350',
  type: CategoryType.expense,
);

GoalModel _emAndamento() => GoalModel.saveMoney(
  id: 'g-ativa',
  name: 'Reserva de emergência',
  targetAmount: 1000,
  currentAmount: 250,
  deadline: DateTime(2026, 12, 31),
  accountId: 'acc1',
  startDate: DateTime(2026, 1, 1),
);

GoalModel _estourada() => GoalModel.reduceExpense(
  id: 'g-estourada',
  name: 'Segurar o mercado',
  targetAmount: 1000,
  currentAmount: 1800,
  deadline: DateTime(2026, 12, 31),
  category: _categoria,
  startDate: DateTime(2026, 1, 1),
  outcome: GoalOutcome.failed,
  failedAt: DateTime(2026, 6, 10),
);

/// Prazo vencido ontem e ainda sem desfecho: a janela até o cron das 03:15.
GoalModel _aguardandoApuracao() => GoalModel.reduceExpense(
  id: 'g-aguardando',
  name: 'Teto de dezembro',
  targetAmount: 1000,
  currentAmount: 400,
  deadline: DateTime.now().subtract(const Duration(days: 1)),
  category: _categoria,
  startDate: DateTime(2026, 1, 1),
);

GoalModel _vencedora() => GoalModel.payDebt(
  id: 'g-quitada',
  name: 'Quitar empréstimo',
  targetAmount: 5000,
  currentAmount: 5000,
  deadline: DateTime(2026, 12, 31),
  accountId: 'acc2',
  startDate: DateTime(2026, 1, 1),
  outcome: GoalOutcome.success,
  completedAt: DateTime(2026, 6, 10),
);

Widget _app(
  List<GoalModel> goals, {
  bool highlightOnly = false,
  bool showTitle = true,
}) {
  return ProviderScope(
    overrides: [
      GoalViewProvider.goalsStream.overrideWith((ref) => Stream.value(goals)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: GoalsSection(
            highlightOnly: highlightOnly,
            showTitle: showTitle,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));
  });

  testWidgets('metas encerradas ganham uma seção só delas', (tester) async {
    await tester.pumpWidget(_app([_emAndamento(), _estourada(), _vencedora()]));
    await tester.pump();

    expect(find.text(l10n.journeyClosedGoalsTitle), findsOneWidget);
    expect(find.text('Reserva de emergência'), findsOneWidget);
    expect(find.text('Segurar o mercado'), findsOneWidget);
    expect(find.text('Quitar empréstimo'), findsOneWidget);
  });

  testWidgets('sem metas encerradas, a seção nem aparece', (tester) async {
    await tester.pumpWidget(_app([_emAndamento()]));
    await tester.pump();

    expect(find.text(l10n.journeyClosedGoalsTitle), findsNothing);
  });

  testWidgets('meta de redução estourada é anunciada como limite estourado', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_estourada()]));
    await tester.pump();

    expect(find.text(l10n.goalLimitBlownAt('10/06/2026')), findsOneWidget);
    // O texto de conquista não pode estar em lugar nenhum da tela.
    expect(find.text(l10n.goalCompletedAt('10/06/2026')), findsNothing);
    expect(find.byIcon(Icons.report_gmailerrorred), findsOneWidget);
  });

  testWidgets('meta de acúmulo concluída é anunciada como conclusão', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_vencedora()]));
    await tester.pump();

    expect(find.text(l10n.goalCompletedAt('10/06/2026')), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('meta com prazo vencido e sem desfecho vai para as encerradas', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_emAndamento(), _aguardandoApuracao()]));
    await tester.pump();

    expect(find.text(l10n.journeyClosedGoalsTitle), findsOneWidget);
    expect(find.text(l10n.goalAwaitingOutcome), findsOneWidget);
    // Não pode ser anunciada nem como conquista nem como fracasso: ninguém
    // apurou ainda.
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byIcon(Icons.report_gmailerrorred), findsNothing);
  });

  testWidgets('sozinha, a meta aguardando apuração não fica entre as ativas', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_aguardandoApuracao()]));
    await tester.pump();

    // A seção das encerradas existe mesmo sem nenhuma meta desfechada: a meta
    // vencida já não está mais correndo.
    expect(find.text(l10n.journeyClosedGoalsTitle), findsOneWidget);
    expect(find.text('Teto de dezembro'), findsOneWidget);
  });

  testWidgets('meta em andamento não mostra rótulo de desfecho', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_emAndamento()]));
    await tester.pump();

    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byIcon(Icons.report_gmailerrorred), findsNothing);
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
    expect(find.text(l10n.goalAwaitingOutcome), findsNothing);
  });

  /// `/goals` era inalcançável em dois dos três cenários da Home.
  ///
  /// O atalho só aparecia com MAIS DE UMA meta corrente: uma meta correndo e
  /// quatro encerradas não mostrava porta nenhuma, e só encerradas dizia
  /// "você não tem metas" — o que é falso e esconde a tela inteira.
  group('destaque da Home — a porta para /goals', () {
    testWidgets('uma corrente e quatro encerradas: o atalho aparece', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app([
          _emAndamento(),
          _estourada(),
          _vencedora(),
          _aguardandoApuracao(),
        ], highlightOnly: true),
      );
      await tester.pump();

      expect(find.text('Reserva de emergência'), findsOneWidget);
      expect(
        find.text(l10n.journeySeeAllGoals(4)),
        findsOneWidget,
        reason:
            'o contador é do que a tela /goals LISTA, não do que corre — com '
            '`running.length` o atalho sumia e o número mentia',
      );
    });

    testWidgets('só encerradas: diz a verdade e abre as encerradas', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app([_estourada(), _vencedora()], highlightOnly: true),
      );
      await tester.pump();

      expect(find.text(l10n.journeyNoRunningGoals), findsOneWidget);
      expect(find.text(l10n.journeySeeClosedGoals(2)), findsOneWidget);
      expect(
        find.text(l10n.goalEmptyMessage),
        findsNothing,
        reason: '"você não tem metas" é falso quando existem duas encerradas',
      );
    });

    testWidgets('nenhuma meta: aí sim o estado vazio de verdade', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const [], highlightOnly: true));
      await tester.pump();

      expect(find.text(l10n.goalEmptyMessage), findsOneWidget);
    });

    testWidgets('B5 — mais de uma corrente: destaca a de prazo mais curto', (
      tester,
    ) async {
      final maisLonga = GoalModel.saveMoney(
        id: 'g-longa',
        name: 'Trocar de carro',
        targetAmount: 60000,
        currentAmount: 1000,
        deadline: DateTime(2030, 12, 31),
        accountId: 'acc1',
        startDate: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        _app([maisLonga, _emAndamento()], highlightOnly: true),
      );
      await tester.pump();

      expect(
        find.text('Reserva de emergência'),
        findsOneWidget,
        reason:
            'a meta com 90% já está resolvida; a que vence primeiro é a que '
            'ainda depende de uma decisão desta semana',
      );
      expect(find.text('Trocar de carro'), findsNothing);
      expect(find.text(l10n.journeySeeAllGoals(2)), findsOneWidget);
    });

    testWidgets('uma meta só: nada de atalho para uma lista de um item', (
      tester,
    ) async {
      await tester.pumpWidget(_app([_emAndamento()], highlightOnly: true));
      await tester.pump();

      expect(find.text('Reserva de emergência'), findsOneWidget);
      expect(find.textContaining('Ver as'), findsNothing);
    });
  });

  testWidgets('na tela /goals o título não vem em dobro', (tester) async {
    await tester.pumpWidget(_app([_emAndamento()], showTitle: false));
    await tester.pump();

    expect(
      find.text(l10n.goalsTitle),
      findsNothing,
      reason: 'quem titula é quem contém: a AppBar da tela já diz "Metas"',
    );
  });

  /// A2 — a tela e a seção usavam a FRASE de convite do onboarding, "Trace
  /// suas primeiras metas", como título de uma tela de quem já tem quatro.
  /// Título é substantivo. A chave antiga foi removida: ela não tinha outro
  /// chamador, e o onboarding tem a própria.
  test('A2 — o título de metas é a palavra, não o convite', () {
    expect(l10n.goalsTitle, 'Metas');
    expect(l10n.goalsTitle, isNot(contains('primeiras')));
  });

  testWidgets('A2 — e é ele que a seção escreve', (tester) async {
    await tester.pumpWidget(_app([_emAndamento()]));
    await tester.pump();

    expect(find.text('Metas'), findsOneWidget);
    expect(find.textContaining('primeiras'), findsNothing);
  });
}
