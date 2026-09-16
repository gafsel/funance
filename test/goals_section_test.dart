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

Widget _app(List<GoalModel> goals) {
  return ProviderScope(
    overrides: [
      GoalViewProvider.goalsStream.overrideWith((ref) => Stream.value(goals)),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      locale: Locale('pt', 'BR'),
      home: Scaffold(
        body: SingleChildScrollView(child: GoalsSection()),
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

  testWidgets('meta em andamento não mostra rótulo de desfecho', (
    tester,
  ) async {
    await tester.pumpWidget(_app([_emAndamento()]));
    await tester.pump();

    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byIcon(Icons.report_gmailerrorred), findsNothing);
  });
}
