import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_theme.dart';
import 'package:funances/core/widgets/app_error_widget.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/l10n/app_localizations.dart';

/// M9 / M10 — as duas superfícies de erro do app.
///
/// `ErrorView` cobre a falha de uma SEÇÃO (o resto da tela continua útil) e
/// `AppErrorWidget` substitui a tela inteira quando o próprio build falha.
/// Anunciam a mesma coisa — algo quebrou e não foi culpa de quem está lendo —
/// e apareciam com vermelhos e cinzas diferentes: o `ErrorView` misturava
/// `errorContainer` a 35% com `error` a 25%, e o `AppErrorWidget` era cinza
/// de `onSurfaceVariant` com espaçamentos 24/12/4 fora da escala.

final _temas = {
  'claro': (theme: AppTheme.light, palette: AppPalette.light),
  'escuro': (theme: AppTheme.dark, palette: AppPalette.dark),
};

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pump();
}

BoxDecoration _decoracao(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(ErrorView),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

void main() {
  _temas.forEach((nome, tema) {
    group('ErrorView no tema $nome', () {
      testWidgets('M9 — fundo e borda saem da tinta de erro da paleta', (
        tester,
      ) async {
        await _pump(
          tester,
          const ErrorView(message: 'Sem conexão'),
          theme: tema.theme,
        );

        final decoracao = _decoracao(tester);

        expect(decoracao.color, tema.palette.dangerText.withValues(alpha: 0.12));
        expect(
          (decoracao.border! as Border).top.color,
          tema.palette.dangerText.withValues(alpha: 0.28),
          reason:
              'as mesmas frações da StatusPill: o cartão de erro é da mesma '
              'família das pílulas de "atrasado" e "acima do plano"',
        );
      });

      testWidgets('a mensagem se lê sobre o próprio fundo', (tester) async {
        await _pump(
          tester,
          const ErrorView(message: 'Sem conexão'),
          theme: tema.theme,
        );

        final fundo = Color.alphaBlend(
          _decoracao(tester).color!,
          tema.palette.paper,
        );
        final tinta = tester.widget<Text>(find.text('Sem conexão')).style!.color!;

        expect(
          AppColors.contrastRatio(tinta, fundo),
          greaterThanOrEqualTo(4.5),
        );
      });

      testWidgets('sem onRetry não promete uma ação que não existe', (
        tester,
      ) async {
        await _pump(
          tester,
          const ErrorView(message: 'Sem conexão'),
          theme: tema.theme,
        );

        expect(find.byType(OutlinedButton), findsNothing);
      });

      testWidgets('com onRetry, o botão chama de volta', (tester) async {
        var tentou = false;

        await _pump(
          tester,
          ErrorView(message: 'Sem conexão', onRetry: () => tentou = true),
          theme: tema.theme,
        );

        await tester.tap(find.byType(OutlinedButton));
        expect(tentou, isTrue);
      });
    });

    group('AppErrorWidget no tema $nome', () {
      testWidgets('M10 — mesma cara do ErrorView', (tester) async {
        await _pump(tester, const AppErrorWidget(), theme: tema.theme);

        expect(
          tester.widget<Icon>(find.byIcon(Icons.cloud_off)).color,
          tema.palette.dangerText,
        );
        expect(
          tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(AppErrorWidget),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .color,
          tema.palette.background,
        );
      });

      testWidgets('M10 — nunca mostra a exceção crua', (tester) async {
        await _pump(tester, const AppErrorWidget(), theme: tema.theme);

        expect(find.textContaining('Exception'), findsNothing);
        expect(find.textContaining('#0'), findsNothing);
        expect(find.text('Algo deu errado'), findsOneWidget);
      });
    });
  });

  testWidgets('M10 — o AppErrorWidget funciona ACIMA do Localizations', (
    tester,
  ) async {
    // É o caso que ele existe para cobrir: o erro acontece na construção do
    // próprio `MaterialApp`, e não há traduções para pedir.
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AppErrorWidget(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Algo deu errado'), findsOneWidget);
    expect(
      find.text('Já fomos avisados e estamos trabalhando nisso.'),
      findsOneWidget,
    );
  });
}
