import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/monthly_available_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/freedom_compass.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'support/journey_fakes.dart';

/// F3.1 — a Jornada abria em missões e gráficos e não respondia "quanto posso
/// gastar até o fim do mês". O número (e a Bússola logo abaixo) são a resposta.
CategoryModel _category(
  String id, {
  CategoryType type = CategoryType.expense,
  bool isSystem = false,
}) {
  return CategoryModel(
    id: id,
    name: id,
    icon: 'category',
    color: '#333333',
    type: type,
    isSystem: isSystem,
  );
}

OverviewCategorySummary _summary(
  CategoryModel category, {
  double general = 0,
  double specific = 0,
  double actual = 0,
}) {
  return OverviewCategorySummary(
    category: category,
    generalPlannedAmount: general,
    specificPlannedAmount: specific,
    actualAmount: actual,
  );
}

InstallmentModel _pending(double amount, {CategoryModel? category}) {
  return InstallmentModel(
    id: 'i-$amount',
    orderId: 'o-$amount',
    amount: amount,
    description: 'Agendado',
    dueDate: DateTime(2026, 9, 25, 12),
    status: InstallmentStatus.pending,
    type: OrderType.expense,
    installmentType: InstallmentType.single,
    category: category,
  );
}

const _locale = Locale('pt', 'BR');

Widget _app(List<Override> overrides, Widget child) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [_locale],
      locale: _locale,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

List<Override> _compassOverrides(FakeJourneyRepository repository) => [
  WorkspaceViewProviders.workspace.overrideWith(
    (ref) => TestWorkspaceNotifier(workspaceStateFor()),
  ),
  JourneyDomainProviders.repository.overrideWithValue(repository),
];

const _health = FinancialHealth(
  score: 62,
  tier: FreedomTier.estrategista,
  monthKey: '2026-08',
  components: [
    FreedomComponentScore(
      component: FreedomComponent.folego,
      score: 40,
      months: 2.5,
    ),
    FreedomComponentScore(
      component: FreedomComponent.poupanca,
      score: 70,
      rate: 0.18,
    ),
    FreedomComponentScore(
      component: FreedomComponent.disciplina,
      score: 80,
      within: 8,
      total: 10,
    ),
    FreedomComponentScore(
      component: FreedomComponent.alivio,
      score: 55,
      delta: -320.0,
    ),
  ],
);

void main() {
  group('MonthlyAvailable', () {
    test('disponível = renda prevista − realizado − pendentes', () {
      final available = MonthlyAvailable.from(
        summaries: [
          // Receita: vale o MAIOR entre o limite geral e o específico.
          _summary(
            _category('salario', type: CategoryType.income),
            general: 5000,
            specific: 5200,
            actual: 5200,
          ),
          _summary(_category('mercado'), general: 1200, actual: 900),
          _summary(_category('lazer'), general: 300, actual: 120),
        ],
        pendingInstallments: [_pending(450)],
      );

      expect(available.expectedIncome, 5200);
      expect(available.realizedExpenses, 1020);
      expect(available.pendingExpenses, 450);
      expect(available.plannedExpenses, 1500);
      expect(available.available, 5200 - 1020 - 450);
    });

    test('categorias de sistema ficam de fora dos dois lados', () {
      final available = MonthlyAvailable.from(
        summaries: [
          _summary(
            _category('saldo_inicial', type: CategoryType.income, isSystem: true),
            general: 9000,
            actual: 9000,
          ),
          _summary(
            _category('saldo_inicial_despesa', isSystem: true),
            general: 800,
            actual: 800,
          ),
          _summary(
            _category('salario', type: CategoryType.income),
            general: 4000,
          ),
          _summary(_category('mercado'), general: 1000, actual: 700),
        ],
        pendingInstallments: [
          _pending(100, category: _category('sistema', isSystem: true)),
          _pending(200, category: _category('mercado')),
        ],
      );

      expect(available.expectedIncome, 4000);
      expect(available.realizedExpenses, 700);
      expect(available.pendingExpenses, 200);
      expect(available.available, 3100);
    });

    test('sem expectativa de receita não há disponível para mostrar', () {
      final available = MonthlyAvailable.from(
        summaries: [_summary(_category('mercado'), general: 1000, actual: 700)],
        pendingInstallments: const [],
      );

      expect(available.hasIncomeExpectation, isFalse);
    });
  });

  group('JourneyHeader', () {
    testWidgets('mostra o número e a linha realizado/previsto', (tester) async {
      const available = MonthlyAvailable(
        expectedIncome: 5000,
        realizedExpenses: 1200,
        pendingExpenses: 800,
        plannedExpenses: 3000,
      );

      await tester.pumpWidget(
        _app([
          JourneyViewProviders.monthlyAvailable.overrideWith(
            (ref) => Stream.value(available),
          ),
        ], const JourneyHeader()),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);
      const localeName = 'pt_BR';

      expect(
        find.text(3000.0.asCurrency(locale: localeName)),
        findsOneWidget,
        reason: '5000 − 1200 − 800',
      );
      expect(
        find.text(
          l10n.journeyAvailableSpent(
            1200.0.asCurrency(locale: localeName),
            3000.0.asCurrency(locale: localeName),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          l10n.journeyAvailablePending(
            800.0.asCurrency(locale: localeName),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tocar leva à Visão Geral', (tester) async {
      const available = MonthlyAvailable(
        expectedIncome: 5000,
        realizedExpenses: 0,
        pendingExpenses: 0,
        plannedExpenses: 0,
      );

      final container = ProviderContainer(
        overrides: [
          JourneyViewProviders.monthlyAvailable.overrideWith(
            (ref) => Stream.value(available),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [_locale],
            locale: _locale,
            home: Scaffold(body: JourneyHeader()),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(HomeViewProviders.selectedTab), 0);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(container.read(HomeViewProviders.selectedTab), 1);

      // O `todayProvider` agenda o timer da virada da meia-noite; ele morre
      // com o container, e o container precisa morrer antes do fim do teste
      // (o `addTearDown` roda depois da checagem de timers pendentes).
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });

    testWidgets('sem expectativa de receita, convida a defini-la', (
      tester,
    ) async {
      const available = MonthlyAvailable(
        expectedIncome: 0,
        realizedExpenses: 400,
        pendingExpenses: 0,
        plannedExpenses: 0,
      );

      await tester.pumpWidget(
        _app([
          JourneyViewProviders.monthlyAvailable.overrideWith(
            (ref) => Stream.value(available),
          ),
        ], const JourneyHeader()),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.journeyAvailableNoIncome), findsOneWidget);
      expect(
        find.byKey(const ValueKey('journey-set-income')),
        findsOneWidget,
      );
      // E nunca um "disponível" que é só o negativo das despesas.
      expect(find.textContaining('-'), findsNothing);
    });

    testWidgets('enquanto carrega, mostra carregamento e não um zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app([
          JourneyViewProviders.monthlyAvailable.overrideWith(
            (ref) => const Stream<MonthlyAvailable>.empty(),
          ),
        ], const JourneyHeader()),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('FreedomCompassCard', () {
    testWidgets('mostra score, patente e os quatro componentes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(FakeJourneyRepository(health: _health)),
          const FreedomCompassCard(),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassTitle), findsOneWidget);
      expect(find.text(l10n.compassTierEstrategista), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.text(l10n.compassFolego), findsOneWidget);
      expect(find.text(l10n.compassPoupanca), findsOneWidget);
      expect(find.text(l10n.compassDisciplina), findsOneWidget);
      expect(find.text(l10n.compassAlivio), findsOneWidget);
    });

    testWidgets('sem índice publicado, diz que a bússola está calibrando', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(FakeJourneyRepository()),
          const FreedomCompassCard(),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassCalibratingTitle), findsOneWidget);
      expect(find.text(l10n.compassCalibratingMessage), findsOneWidget);
    });

    testWidgets('tocar abre o sheet com explicações e histórico', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(
            FakeJourneyRepository(
              health: _health,
              history: const [
                FinancialHealthPoint(monthKey: '2026-08', score: 62),
                FinancialHealthPoint(monthKey: '2026-07', score: 55),
                FinancialHealthPoint(monthKey: '2026-06', score: 48),
              ],
            ),
          ),
          const FreedomCompassCard(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassFolegoDesc), findsOneWidget);
      expect(find.text(l10n.compassDisciplinaDetail(8, 10)), findsOneWidget);
      expect(find.text(l10n.compassHistoryTitle), findsOneWidget);
      // Do mais antigo para o mais recente: a linha anda com o tempo.
      expect(find.text(l10n.compassHistoryRange('48', '62')), findsOneWidget);
    });

    testWidgets('com menos de dois meses, o histórico explica a ausência', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(
            FakeJourneyRepository(
              health: _health,
              history: const [
                FinancialHealthPoint(monthKey: '2026-08', score: 62),
              ],
            ),
          ),
          const FreedomCompassCard(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassHistoryEmpty), findsOneWidget);
    });
  });
}
