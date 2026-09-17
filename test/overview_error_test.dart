import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/presentation/model/overview_view_model.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F4.5 (QA) — a Visão Geral lia `.value ?? []` do resumo do mês: sem rede, a
/// falha virava lista vazia e a tela AFIRMAVA "nenhum lançamento no período",
/// com o saldo em R$ 0,00. Uma tela pode não saber; não pode inventar.

List<Override> _overrides(Stream<List<OverviewCategorySummary>> Function() stream) => [
  PeriodSummaryViewProviders.monthSummary.overrideWith((ref, monthKey) => stream()),
];

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

void main() {
  testWidgets('resumo em erro mostra o ErrorView, não o estado vazio', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const CategorySummaryView(categoryType: CategoryType.expense),
        _overrides(
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
        _overrides(
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
        _overrides(() => Stream.value(const <OverviewCategorySummary>[])),
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));

    expect(find.byType(ErrorView), findsNothing);
    expect(find.text(l10n.noTransactionsInPeriod), findsOneWidget);
  });
}
