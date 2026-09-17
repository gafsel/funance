import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/theme/theme_mode_provider.dart';
import 'package:funances/features/workspace/presentation/widgets/appearance_section.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O seletor de tema.
///
/// A preferência é do APARELHO, não do workspace: quem usa o modo escuro à
/// noite usa nos dois cofres. E ela precisa sobreviver a fechar o app — um
/// seletor que esquece a escolha é pior do que não ter seletor, porque o
/// usuário aprende que mexer ali não adianta.

/// Espera a leitura assíncrona do disco terminar.
///
/// O notifier começa em `system` e corrige o estado quando as preferências
/// chegam. Sem este respiro, o teste leria sempre o valor inicial e passaria
/// mesmo se a restauração estivesse quebrada.
Future<void> _settled() => Future<void>.delayed(Duration.zero);

Widget _app() {
  return const ProviderScope(
    child: MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('pt'),
      home: Scaffold(
        body: SingleChildScrollView(child: AppearanceSection()),
      ),
    ),
  );
}

void main() {
  group('ThemeModeNotifier', () {
    test('sem preferência gravada, segue o sistema', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await _settled();

      expect(notifier.state, ThemeMode.system);
      notifier.dispose();
    });

    test('restaura a escolha gravada', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.storageKey: 'dark',
      });
      final notifier = ThemeModeNotifier();
      await _settled();

      expect(notifier.state, ThemeMode.dark);
      notifier.dispose();
    });

    test('valor ilegível não impede o app de abrir: cai no sistema', () async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.storageKey: 'sépia',
      });
      final notifier = ThemeModeNotifier();
      await _settled();

      expect(notifier.state, ThemeMode.system);
      notifier.dispose();
    });

    test('escolher grava no disco', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await _settled();

      await notifier.select(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeModeNotifier.storageKey), 'light');
      expect(notifier.state, ThemeMode.light);
      notifier.dispose();
    });

    test('os três modos dão a volta pelo disco sem se perderem', () {
      for (final mode in ThemeMode.values) {
        expect(ThemeModeNotifier.decode(ThemeModeNotifier.encode(mode)), mode);
      }
    });
  });

  group('AppearanceSection', () {
    testWidgets('oferece sistema, claro e escuro', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Sistema'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
    });

    testWidgets('escolher escuro persiste a preferência', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeModeNotifier.storageKey), 'dark');
    });

    testWidgets('abre já marcando o que foi gravado', (tester) async {
      SharedPreferences.setMockInitialValues({
        ThemeModeNotifier.storageKey: 'light',
      });
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      final segmented = tester.widget<SegmentedButton<ThemeMode>>(
        find.byType(SegmentedButton<ThemeMode>),
      );
      expect(segmented.selected, {ThemeMode.light});
    });
  });
}
