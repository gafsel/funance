import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/router/entity_route.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F3.9 — a rota de detalhe recebe o id e carrega pelo provider. Nenhum dos
/// três estados pode acabar numa tela em branco, e nenhum deles redireciona
/// para a home: era isso que acontecia quando o `extra` se perdia num F5.

/// Controla o que o provider devolve, para exercitar os três estados.
AsyncValue<String?> _resposta = const AsyncValue.loading();
int _leituras = 0;

final _entidadeProvider = Provider<AsyncValue<String?>>((ref) {
  _leituras++;
  return _resposta;
});

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: EntityRoute<String>(
          provider: _entidadeProvider,
          builder: (context, value) =>
              Scaffold(body: Center(child: Text('detalhe de $value'))),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    _resposta = const AsyncValue.loading();
    _leituras = 0;
  });

  testWidgets('carregando mostra o indicador, não uma tela vazia', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('com o documento, abre a tela de detalhe', (tester) async {
    _resposta = const AsyncValue.data('fatura-1');

    await _pump(tester);

    expect(find.text('detalhe de fatura-1'), findsOneWidget);
  });

  testWidgets('documento inexistente explica, e não volta para a home', (
    tester,
  ) async {
    _resposta = const AsyncValue.data(null);

    await _pump(tester);

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
    expect(find.text(l10n.errorNotFound), findsOneWidget);
    expect(find.text(l10n.routeNotFoundGoHome), findsOneWidget);
  });

  testWidgets('erro mostra mensagem classificada e tenta de novo', (
    tester,
  ) async {
    _resposta = AsyncValue.error(Exception('falhou'), StackTrace.current);

    await _pump(tester);

    expect(find.byType(ErrorView), findsOneWidget);

    final antes = _leituras;
    _resposta = const AsyncValue.data('fatura-2');

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
    await tester.tap(find.text(l10n.retry));
    await tester.pump();

    // "Tentar de novo" invalida o provider: houve nova leitura, e a tela
    // finalmente abriu.
    expect(_leituras, greaterThan(antes));
    expect(find.text('detalhe de fatura-2'), findsOneWidget);
  });
}
