import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/analytics/analytics_service.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/features/finance/domain/models/category_planning_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/finance_repository.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/domain/services/category_planning_service.dart';
import 'package:funances/features/finance/domain/services/period_summary_service.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:funances/features/finance/presentation/model/finance_view_models.dart';
import 'package:funances/features/finance/presentation/controllers/transaction_form_submit_flow.dart';
import 'package:funances/features/finance/presentation/widgets/unplanned_nudge_sheet.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_analytics.dart';

/// F3.2 — gastar fora do plano é o momento em que o planejamento faz mais
/// sentido, e era exatamente quando o app não dizia nada.
class _FakeFinanceRepository implements IFinanceRepository {
  _FakeFinanceRepository({this.plannings = const []});

  final List<CategoryPlanningModel> plannings;

  @override
  Future<List<CategoryPlanningModel>> getCategoryPlannings(
    String workspaceId, {
    String? startMonth,
    String? endMonth,
  }) async => plannings;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'Método não esperado neste teste: ${invocation.memberName}',
  );
}

class _FakeSummaryRepository implements IPeriodSummaryRepository {
  _FakeSummaryRepository(this.byMonth);

  /// `YYYY-MM` -> valor realizado da categoria `mercado` naquele mês.
  final Map<String, double> byMonth;

  @override
  Stream<PeriodSummaryModel?> watchMonth(
    String workspaceId,
    int year,
    int month,
  ) {
    final key = '$year-${month.toString().padLeft(2, '0')}';
    final actual = byMonth[key];
    if (actual == null) return Stream.value(null);

    return Stream.value(
      PeriodSummaryModel.month(
        year: year,
        month: month,
        categories: {
          'mercado': PeriodSummaryCategoryModel(actualAmount: actual),
        },
        lastUpdate: DateTime(year, month, 28),
      ),
    );
  }

  @override
  Stream<PeriodSummaryModel?> watchWeek(
    String workspaceId,
    int year,
    int week,
  ) => Stream.value(null);
}

class _FakeStore implements IUnplannedNudgeStore {
  final Set<String> shown = {};

  @override
  Future<bool> wasShownToday(
    String workspaceId,
    String categoryId,
    DateTime today,
  ) async => shown.contains('$workspaceId/$categoryId/${today.day}');

  @override
  Future<void> markShown(
    String workspaceId,
    String categoryId,
    DateTime today,
  ) async {
    shown.add('$workspaceId/$categoryId/${today.day}');
  }
}

final _mercado = CategoryModel(
  id: 'mercado',
  name: 'Mercado',
  icon: 'shopping_cart',
  color: '#333333',
);

UnplannedNudgeService _service({
  List<CategoryPlanningModel> plannings = const [],
  Map<String, double> summaries = const {},
  IUnplannedNudgeStore? store,
}) {
  return UnplannedNudgeService(
    workspaceId: 'w1',
    planningService: CategoryPlanningService(
      workspaceId: 'w1',
      repository: _FakeFinanceRepository(plannings: plannings),
    ),
    summaryService: PeriodSummaryService(
      workspaceId: 'w1',
      repository: _FakeSummaryRepository(summaries),
    ),
    store: store ?? _FakeStore(),
  );
}

CategoryPlanningModel _planning(CategoryModel category, double amount) {
  return CategoryPlanningModel(
    id: 'p-${category.id}',
    category: category,
    amount: amount,
    startMonth: '2026-09',
    endMonth: CategoryPlanningService.openEndMonth,
  );
}

final _today = DateTime(2026, 9, 16);

Future<UnplannedNudge?> _evaluate(
  UnplannedNudgeService service, {
  CategoryModel? category,
  OrderType type = OrderType.expense,
  InstallmentStatus status = InstallmentStatus.paid,
  bool isNewOrder = true,
  bool matchedPending = false,
  double amount = 87.5,
}) {
  return service.evaluate(
    category: category ?? _mercado,
    type: type,
    status: status,
    isNewOrder: isNewOrder,
    matchedPending: matchedPending,
    amount: amount,
    dueDate: _today,
    today: _today,
    accountId: 'conta-1',
  );
}

const _locale = Locale('pt', 'BR');

void main() {
  group('UnplannedNudgeService', () {
    test('gasto novo, realizado e sem limite abre o convite', () async {
      final nudge = await _evaluate(_service());

      expect(nudge, isNotNull);
      expect(nudge!.category.id, 'mercado');
      expect(nudge.amount, 87.5);
      expect(nudge.accountId, 'conta-1');
    });

    test('categoria com limite vigente no mês não recebe convite', () async {
      final nudge = await _evaluate(
        _service(plannings: [_planning(_mercado, 600)]),
      );

      expect(nudge, isNull);
    });

    test('agendamento não é gasto fora do plano', () async {
      final nudge = await _evaluate(
        _service(),
        status: InstallmentStatus.pending,
      );

      expect(nudge, isNull);
    });

    test('receita e transferência ficam de fora', () async {
      expect(await _evaluate(_service(), type: OrderType.income), isNull);
      expect(await _evaluate(_service(), type: OrderType.transfer), isNull);
    });

    test('lançamento que casou com um pendente já estava previsto', () async {
      expect(await _evaluate(_service(), matchedPending: true), isNull);
    });

    test('edição de lançamento existente não abre convite', () async {
      expect(await _evaluate(_service(), isNewOrder: false), isNull);
    });

    test('uma vez por categoria por dia', () async {
      final store = _FakeStore();
      final service = _service(store: store);

      final first = await _evaluate(service);
      expect(first, isNotNull);

      await service.markShown(_mercado.id, _today);

      expect(await _evaluate(service), isNull);
    });

    test(
      'falha ao ler o planejamento cala o convite em vez de arriscar um '
      'palpite',
      () async {
        final service = UnplannedNudgeService(
          workspaceId: 'w1',
          planningService: CategoryPlanningService(
            workspaceId: 'w1',
            // `noSuchMethod` lança: é a leitura de planejamento falhando.
            repository: _ExplodingFinanceRepository(),
          ),
          summaryService: PeriodSummaryService(
            workspaceId: 'w1',
            repository: _FakeSummaryRepository(const {}),
          ),
          store: _FakeStore(),
        );

        expect(await _evaluate(service), isNull);
      },
    );
  });

  group('sugestão de limite', () {
    test('média dos últimos três meses, arredondada para cima em R\$ 10', () async {
      // 300 + 420 + 390 = 1110 / 3 = 370 → já é múltiplo de 10.
      final nudge = await _evaluate(
        _service(
          summaries: {'2026-08': 300, '2026-07': 420, '2026-06': 390},
        ),
      );

      expect(nudge!.suggestedLimit, 370);
    });

    test('arredonda para cima, nunca para baixo', () async {
      // 487,31 de média vira 490: um limite quebrado não é uma decisão que
      // alguém toma.
      final nudge = await _evaluate(
        _service(summaries: {'2026-08': 487.31}),
      );

      expect(nudge!.suggestedLimit, 490);
    });

    test('a média é sobre os meses que existem, não sobre três fixos', () async {
      // Quem usa o app há um mês teria a sugestão dividida por três e um
      // limite que já nasce estourado.
      final nudge = await _evaluate(_service(summaries: {'2026-08': 600}));

      expect(nudge!.suggestedLimit, 600);
    });

    test('sem histórico não há sugestão', () async {
      final nudge = await _evaluate(_service());

      expect(nudge!.suggestedLimit, isNull);
    });

    test('o mês corrente não entra na média', () async {
      final nudge = await _evaluate(
        _service(summaries: {'2026-09': 9000, '2026-08': 200}),
      );

      expect(nudge!.suggestedLimit, 200);
    });
  });

  group('evaluateUnplannedNudge (estado do formulário)', () {
    test('lê o estado do formulário antes do save', () async {
      final state = TransactionFormState.creation(
        type: OrderType.expense,
        status: InstallmentStatus.paid,
        category: _mercado,
        amount: 120,
        date: _today,
        accountIdSource: 'conta-1',
      );

      final nudge = await evaluateUnplannedNudge(_service(), state, _today);

      expect(nudge, isNotNull);
      expect(nudge!.amount, 120);
      expect(nudge.dueDate, _today);
    });

    test('formulário de agendamento não dispara o convite', () async {
      final state = TransactionFormState.creation(
        type: OrderType.expense,
        status: InstallmentStatus.pending,
        category: _mercado,
        amount: 120,
        date: _today,
      );

      expect(
        await evaluateUnplannedNudge(_service(), state, _today),
        isNull,
      );
    });
  });

  group('UnplannedNudgeSheet', () {
    Future<void> pumpSheet(
      WidgetTester tester, {
      double? suggestedLimit,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [_locale],
          locale: _locale,
          home: Scaffold(
            body: UnplannedNudgeSheet(
              nudge: _nudge(suggestedLimit: suggestedLimit),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('oferece as três saídas', (tester) async {
      await pumpSheet(tester, suggestedLimit: 370);

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(find.text(l10n.unplannedNudgeRecurring), findsOneWidget);
      expect(find.text(l10n.unplannedNudgeLimit('Mercado')), findsOneWidget);
      expect(find.text(l10n.unplannedNudgeDismiss), findsOneWidget);
      expect(
        find.text(
          l10n.unplannedNudgeLimitDesc(370.0.asCurrency(locale: 'pt_BR')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sem histórico, o limite abre sem sugerir um número', (
      tester,
    ) async {
      await pumpSheet(tester);

      final l10n = await AppLocalizations.delegate.load(_locale);

      expect(
        find.text(l10n.unplannedNudgeLimitDescNoHistory),
        findsOneWidget,
      );
    });
  });

  group('UnplannedNudgeSheet.show', () {
    testWidgets('"Definir limite" registra a ação e abre o planejamento', (
      tester,
    ) async {
      final host = await _pumpHost(tester, suggestedLimit: 370);

      await tester.tap(find.byKey(const ValueKey('nudge-limit')));
      await tester.pumpAndSettle();

      expect(
        host.analytics.find(AnalyticsEvents.unplannedNudgeShown),
        isNotNull,
      );
      final event = host.analytics.find(
        AnalyticsEvents.unplannedNudgeConverted,
      );
      expect(event!.params, {'action': UnplannedNudgeAction.limit});

      expect(host.visited.last, startsWith('/planning'));
      expect(host.visited.last, contains('categoryId=mercado'));
      expect(host.visited.last, contains('suggested=370'));
      expect(host.shown, isTrue);
    });

    testWidgets('"Transformar em recorrência" abre o formulário recorrente', (
      tester,
    ) async {
      final host = await _pumpHost(tester);

      await tester.tap(find.byKey(const ValueKey('nudge-recurring')));
      await tester.pumpAndSettle();

      final event = host.analytics.find(
        AnalyticsEvents.unplannedNudgeConverted,
      );
      expect(event!.params, {'action': UnplannedNudgeAction.recurring});

      expect(host.visited.last, startsWith('/transactions/form'));
      expect(host.visited.last, contains('installmentType=recurring'));
      expect(host.visited.last, contains('status=pending'));
    });

    testWidgets('"Só desta vez" registra a recusa e não navega', (
      tester,
    ) async {
      final host = await _pumpHost(tester);

      await tester.tap(find.byKey(const ValueKey('nudge-dismiss')));
      await tester.pumpAndSettle();

      final event = host.analytics.find(
        AnalyticsEvents.unplannedNudgeConverted,
      );
      expect(event!.params, {'action': UnplannedNudgeAction.dismissed});
      // Nada de valor monetário nem nome de categoria no analytics.
      expect(event.params.values.join(), isNot(contains('87')));
      expect(event.params.values.join(), isNot(contains('Mercado')));

      expect(host.visited, isEmpty);
    });

    testWidgets(
      'fechar pelo scrim conta como recusa — era a única resposta que o '
      'funil não via',
      (tester) async {
        final host = await _pumpHost(tester);

        // Toque bem no topo da tela: fora do sheet, no scrim.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        expect(find.byType(UnplannedNudgeSheet), findsNothing);

        final event = host.analytics.find(
          AnalyticsEvents.unplannedNudgeConverted,
        );
        expect(event, isNotNull);
        expect(event!.params, {'action': UnplannedNudgeAction.dismissed});
      },
    );

    testWidgets('arrastar o sheet para baixo também conta como recusa', (
      tester,
    ) async {
      final host = await _pumpHost(tester);

      await tester.drag(
        find.byType(UnplannedNudgeSheet),
        const Offset(0, 600),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UnplannedNudgeSheet), findsNothing);

      final event = host.analytics.find(
        AnalyticsEvents.unplannedNudgeConverted,
      );
      expect(event!.params, {'action': UnplannedNudgeAction.dismissed});
    });

    testWidgets('contexto desmontado: não exibe, e nada é marcado', (
      tester,
    ) async {
      final analytics = FakeAnalyticsService();

      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Troca a árvore: o contexto capturado morre com ela.
      await tester.pumpWidget(const Placeholder());
      expect(captured.mounted, isFalse);

      final shown = await UnplannedNudgeSheet.show(
        captured,
        nudge: _nudge(),
        analytics: analytics,
      );

      expect(shown, isFalse, reason: 'sem sheet, sem marca de "já convidei"');
      // E sem topo de funil para uma resposta que nunca foi pedida.
      expect(analytics.events, isEmpty);
    });
  });
}

/// A tela que abre o convite, com um roteador de verdade: é ele que prova que
/// as rotas do sheet existem e chegam com os parâmetros certos.
class _Host {
  _Host(this.analytics);

  final FakeAnalyticsService analytics;
  final List<String> visited = [];
  bool shown = false;
}

UnplannedNudge _nudge({double? suggestedLimit}) => UnplannedNudge(
  category: _mercado,
  amount: 87.5,
  dueDate: _today,
  accountId: 'conta-1',
  suggestedLimit: suggestedLimit,
);

Future<_Host> _pumpHost(WidgetTester tester, {double? suggestedLimit}) async {
  final host = _Host(FakeAnalyticsService());

  Widget stub(GoRouterState state) {
    host.visited.add(state.uri.toString());
    return const Scaffold(body: Text('destino'));
  }

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                host.shown = await UnplannedNudgeSheet.show(
                  context,
                  nudge: _nudge(suggestedLimit: suggestedLimit),
                  analytics: host.analytics,
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      GoRoute(path: '/planning', builder: (context, state) => stub(state)),
      GoRoute(
        path: '/transactions/form',
        builder: (context, state) => stub(state),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [_locale],
      locale: _locale,
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();

  expect(find.byType(UnplannedNudgeSheet), findsOneWidget);

  return host;
}

class _ExplodingFinanceRepository implements IFinanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('leitura indisponível');
}
