import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/time/clock.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/repositories/account_repository.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/services/finance_service.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/monthly_available_model.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';
import 'package:funances/features/home/presentation/widgets/journey_header.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
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

InstallmentModel _pending(
  double amount, {
  CategoryModel? category,
  DateTime? dueDate,
}) {
  return InstallmentModel(
    id: 'i-$amount',
    orderId: 'o-$amount',
    amount: amount,
    description: 'Agendado',
    dueDate: dueDate ?? DateTime(2026, 9, 25, 12),
    status: InstallmentStatus.pending,
    type: OrderType.expense,
    installmentType: InstallmentType.single,
    category: category,
  );
}

/// Aplica o mesmo filtro da consulta do Firestore (`referenceDate` entre
/// `startDate` e `endDate`), para o teste provar a JANELA e não só o somatório.
class _WindowedFinanceRepository implements IFinanceRepository {
  _WindowedFinanceRepository(this.installments);

  final List<InstallmentModel> installments;

  ({DateTime? start, DateTime? end})? lastWindow;

  @override
  Stream<List<InstallmentModel>> watchInstallments(
    String workspaceId, {
    int? limit,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    OrderType? type,
    InstallmentStatus? status,
  }) {
    lastWindow = (start: startDate, end: endDate);

    return Stream.value(
      installments
          .where((i) => type == null || i.type == type)
          .where((i) => status == null || i.status == status)
          .where(
            (i) => startDate == null || !i.referenceDate.isBefore(startDate),
          )
          .where((i) => endDate == null || !i.referenceDate.isAfter(endDate))
          .toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnusedRepository implements IAccountRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _UnusedCategoryRepository implements ICategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
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

    test('a janela das pendentes é o mês de hoje, do dia 1 ao último', () {
      final window = MonthlyAvailable.pendingWindow(DateTime(2026, 2, 16));

      expect(window.start, DateTime(2026, 2, 1));
      // Fevereiro de 2026 tem 28 dias, e o fim do dia entra porque
      // `referenceDate` é normalizado às 12:00.
      expect(window.end, DateTime(2026, 2, 28, 23, 59, 59));
    });

    test('a janela de dezembro termina no próprio ano', () {
      final window = MonthlyAvailable.pendingWindow(DateTime(2026, 12, 5));

      expect(window.start, DateTime(2026, 12, 1));
      expect(window.end, DateTime(2026, 12, 31, 23, 59, 59));
    });

    test('sem expectativa de receita não há disponível para mostrar', () {
      final available = MonthlyAvailable.from(
        summaries: [_summary(_category('mercado'), general: 1000, actual: 700)],
        pendingInstallments: const [],
      );

      expect(available.hasIncomeExpectation, isFalse);
    });
  });

  group('monthlyAvailable (consulta das pendentes)', () {
    test('só as pendentes do mês corrente entram no disponível', () async {
      final repository = _WindowedFinanceRepository([
        // No mês: entra.
        _pending(450, dueDate: DateTime(2026, 9, 25, 12)),
        // No mês seguinte: fica de fora, mesmo sendo uma despesa pendente.
        _pending(9999, dueDate: DateTime(2026, 10, 3, 12)),
      ]);

      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 9, 16, 10)),
          PeriodSummaryViewProviders.monthSummary.overrideWith(
            (ref, monthKey) => Stream.value([
              _summary(
                _category('salario', type: CategoryType.income),
                general: 5000,
              ),
              _summary(_category('mercado'), general: 1000, actual: 700),
            ]),
          ),
          FinanceDomainProviders.service.overrideWithValue(
            FinanceService(
              workspaceId: 'w1',
              repository: repository,
              accountRepository: _UnusedRepository(),
              categoryRepository: _UnusedCategoryRepository(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // O provider é autoDispose: sem alguém escutando, ele é descartado
      // antes de emitir.
      container.listen(JourneyViewProviders.monthlyAvailable, (_, _) {});

      final available = await container.read(
        JourneyViewProviders.monthlyAvailable.future,
      );

      expect(available.pendingExpenses, 450);
      expect(available.available, 5000 - 700 - 450);

      // E a janela pedida ao repositório é a do mês, não uma aberta.
      expect(repository.lastWindow?.start, DateTime(2026, 9, 1));
      expect(repository.lastWindow?.end, DateTime(2026, 9, 30, 23, 59, 59));
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

  /// B1 — o que sobrou da Bússola em CARTÃO.
  ///
  /// `FreedomCompassCard`, `CompassContent` e `CompassShell` morreram quando
  /// a Home v2 trocou o cartão pela linha: ninguém os montava, e o único
  /// lugar que ainda os citava era este grupo de testes — que assim provava a
  /// existência do próprio teste. A FOLHA, que a linha abre, continua viva, e
  /// é ela que estes casos passam a montar direto.
  group('FreedomCompassSheet', () {
    testWidgets('explica cada componente e mostra o histórico', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(
            FakeJourneyRepository(
              health: _health,
              history: const [
                FinancialHealthPoint(monthKey: '2026-09', score: 62),
                FinancialHealthPoint(monthKey: '2026-08', score: 55),
              ],
            ),
          ),
          const FreedomCompassSheet(health: _health),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassTitle), findsOneWidget);
      expect(find.text(l10n.compassFolegoDesc), findsOneWidget);
      expect(find.text(l10n.compassDisciplinaDetail(8, 10)), findsOneWidget);
      expect(find.text(l10n.compassHistoryTitle), findsOneWidget);
    });

    testWidgets('com menos de dois meses, o histórico explica a ausência', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _compassOverrides(FakeJourneyRepository(health: _health)),
          const FreedomCompassSheet(health: _health),
        ),
      );
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.compassHistoryEmpty), findsOneWidget);
    });
  });
}
