import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/repositories/category_repository.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F4.5 (QA) — a Visão Geral lia `.value ?? []` do resumo do mês: sem rede, a
/// falha virava lista vazia e a tela AFIRMAVA "nenhum lançamento no período",
/// com o saldo em R$ 0,00. Uma tela pode não saber; não pode inventar.
///
/// E o "tentar de novo" precisa invalidar a FONTE. `monthSummary` deriva de
/// `CategoryViewProviders.allStream`, um StreamProvider SEM autoDispose: o
/// `AsyncError` dele fica cacheado, e invalidar só o resumo fazia o botão
/// reler o mesmo erro do pai — botão que gira e não faz nada.

/// Repositório de categorias que conta leituras e decide, a cada leitura, se
/// responde ou falha.
class _FakeCategoryRepository implements ICategoryRepository {
  _FakeCategoryRepository({required this.falha});

  bool falha;
  int leituras = 0;

  @override
  Stream<List<CategoryModel>> getCategories(String workspaceId) {
    leituras++;
    if (falha) {
      return Stream<List<CategoryModel>>.error(
        Exception('sem rede'),
        StackTrace.current,
      );
    }
    return Stream.value(const <CategoryModel>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no teste');
}

/// O mês existe e está vazio: o que este teste exercita é a falha das
/// CATEGORIAS, não a do resumo.
class _FakePeriodSummaryRepository implements IPeriodSummaryRepository {
  @override
  Stream<PeriodSummaryModel?> watchMonth(String w, int year, int month) =>
      Stream.value(null);

  @override
  Stream<PeriodSummaryModel?> watchWeek(String w, int year, int week) =>
      Stream.value(null);
}

Widget _app(Widget child, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

List<Override> _comResumo(Stream<List<OverviewCategorySummary>> Function() s) =>
    [PeriodSummaryViewProviders.monthSummary.overrideWith((ref, key) => s())];

void main() {
  testWidgets('resumo em erro mostra o ErrorView, não o estado vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const CategorySummaryView(categoryType: CategoryType.expense),
        _comResumo(
          () => Stream<List<OverviewCategorySummary>>.error(
            Exception('sem rede'),
            StackTrace.current,
          ),
        ),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(l10n.noTransactionsInPeriod), findsNothing);
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('saldo em erro não mostra R\$ 0,00', (tester) async {
    await tester.pumpWidget(
      _app(
        const BalanceSummaryView(),
        _comResumo(
          () => Stream<List<OverviewCategorySummary>>.error(
            Exception('sem rede'),
            StackTrace.current,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.textContaining('0,00'), findsNothing);
  });

  testWidgets('mês realmente vazio continua dizendo que está vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const CategorySummaryView(categoryType: CategoryType.expense),
        _comResumo(() => Stream.value(const <OverviewCategorySummary>[])),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(l10n.noTransactionsInPeriod), findsOneWidget);
  });

  testWidgets(
    'tentar de novo relê a FONTE (categorias) e a tela sai do erro',
    (tester) async {
      final repositorio = _FakeCategoryRepository(falha: true);

      await tester.pumpWidget(
        _app(
          const CategorySummaryView(categoryType: CategoryType.expense),
          [
            CategoryDomainProviders.repository.overrideWithValue(repositorio),
            PeriodSummaryDomainProviders.repository.overrideWithValue(
              _FakePeriodSummaryRepository(),
            ),
            WorkspaceViewProviders.currentWorkspaceId.overrideWithValue('w1'),
          ],
        ),
      );
      // O erro chega pelo stream: precisa de um quadro a mais que o estado
      // síncrono de carregamento.
      await tester.pump();
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

      // O erro nasce nas CATEGORIAS e chega à tela pelo resumo do mês.
      expect(find.byType(ErrorView), findsOneWidget);
      expect(repositorio.leituras, 1);

      // A rede volta. Sem tocar em nada, a tela continua no erro: o
      // `AsyncError` do provider sem autoDispose está cacheado.
      repositorio.falha = false;
      await tester.pump();
      expect(find.byType(ErrorView), findsOneWidget);

      await tester.tap(find.text(l10n.retry));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // A fonte foi relida — era isso que o botão não fazia — e a tela saiu do
      // erro.
      expect(repositorio.leituras, 2);
      expect(find.byType(ErrorView), findsNothing);
      expect(find.text(l10n.noTransactionsInPeriod), findsOneWidget);
    },
  );
}
