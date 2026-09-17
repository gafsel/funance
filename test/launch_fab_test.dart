import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/features/finance/presentation/widgets/launch_fab.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F-design/7 — o botão de lançar.
///
/// "Lançar" é a ação que o app existe para receber, e ela era a mais difícil
/// de achar: sumia fora das quatro abas da Home, e cada tela que tinha um FAB
/// o pintava por conta própria — duas em dourado, uma com a cor do tema. A
/// decisão fechada é que ele é UM componente, com a cor vinda do
/// `floatingActionButtonTheme`, e que ele fica no centro da barra inferior
/// nas telas principais.
///
/// Estes testes prendem o componente. Quem monta o FAB em cada tela é o
/// `Scaffold` dela — Home (as quatro abas, inclusive Histórico) e Contas;
/// Metas é seção da aba Jornada e herda o FAB da Home.

Widget _app({Widget? fab, Widget? bottomBar, ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('pt'),
  home: Scaffold(
    body: const SizedBox.expand(),
    floatingActionButton: fab,
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    bottomNavigationBar:
        bottomBar ?? const SizedBox(height: 64, child: Text('barra')),
  ),
);

void main() {
  group('LaunchFab', () {
    testWidgets('abre a folha de lançamento, não navega direto', (
      tester,
    ) async {
      await tester.pumpWidget(_app(fab: const LaunchFab()));
      await tester.pump();

      expect(find.byType(TransactionActionSheet), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.byType(TransactionActionSheet),
        findsOneWidget,
        reason:
            'o "+" pergunta O QUE lançar antes de abrir formulário nenhum — '
            'despesa, receita e transferência são três telas diferentes',
      );
    });

    testWidgets('a cor vem do tema, não da tela', (tester) async {
      await tester.pumpWidget(_app(fab: const LaunchFab()));
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );

      expect(
        fab.backgroundColor,
        isNull,
        reason:
            'três telas pintavam o próprio FAB à mão e discordavam entre si; '
            'agora quem decide é o floatingActionButtonTheme',
      );
      expect(
        AppTheme.light.floatingActionButtonTheme.backgroundColor,
        AppColors.gold,
        reason: 'o ouro é a ação primária e a recompensa',
      );
    });

    testWidgets('o ouro é o mesmo nos dois temas', (tester) async {
      expect(
        AppTheme.dark.floatingActionButtonTheme.backgroundColor,
        AppTheme.light.floatingActionButtonTheme.backgroundColor,
        reason:
            'o botão de lançar é superfície de JOGO: não acompanha o brilho '
            'do papel',
      );
    });

    testWidgets('a tinta sobre o ouro é legível', (tester) async {
      final ink = AppTheme.light.floatingActionButtonTheme.foregroundColor!;

      // `goldInk` é um marrom quente, escolhido para o ouro em vez da tinta
      // genérica: 8.2:1 contra os 10:1 do `inkLight`, e muito mais quente.
      // A troca de 1.8 pontos de contraste é deliberada; o que o teste não
      // deixa passar é alguém achar que branco sobre ouro serve — 1.55:1.
      expect(ink, AppColors.goldInk);
      expect(
        AppColors.contrastRatio(ink, AppColors.gold),
        greaterThanOrEqualTo(4.5),
        reason: 'piso do WCAG AA para texto normal',
      );
      expect(
        AppColors.contrastRatio(AppColors.inkInverse, AppColors.gold),
        lessThan(2),
        reason: 'o "+" branco sobre ouro que o app tinha era ilegível',
      );
    });

    testWidgets('fica ACIMA da barra inferior, nunca por baixo', (
      tester,
    ) async {
      await tester.pumpWidget(_app(fab: const LaunchFab()));
      await tester.pump();

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final barra = tester.getRect(find.text('barra'));

      expect(
        fab.center.dy,
        lessThan(barra.center.dy),
        reason: 'centerDocked encaixa o botão no entalhe, acima da barra',
      );
    });

    testWidgets('fica no CENTRO horizontal', (tester) async {
      await tester.pumpWidget(_app(fab: const LaunchFab()));
      await tester.pump();

      final fab = tester.getRect(find.byType(FloatingActionButton));
      final tela = tester.getSize(find.byType(Scaffold));

      expect(
        fab.center.dx,
        closeTo(tela.width / 2, 1),
        reason: 'é decisão de produto: o "+" mora no meio da barra',
      );
    });

    testWidgets('aceita um rótulo de acessibilidade próprio', (tester) async {
      await tester.pumpWidget(
        _app(fab: const LaunchFab(tooltip: 'Lançar despesa ou receita')),
      );
      await tester.pump();

      expect(find.byTooltip('Lançar despesa ou receita'), findsOneWidget);
    });
  });
}
