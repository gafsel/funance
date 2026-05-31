import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/money_form_field.dart';
import 'package:funances/l10n/app_localizations.dart';

void main() {
  group('MoneyFormField tests', () {
    testWidgets('should format input as currency for pt_BR', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('pt', 'BR')],
          locale: Locale('pt', 'BR'),
          home: Scaffold(
            body: MoneyFormField(),
          ),
        ),
      );

      final finder = find.byType(TextField);
      expect(finder, findsOneWidget);

      await tester.enterText(finder, '12345');
      await tester.pump();

      // Para pt_BR, NumberFormat.decimalPattern formata 123.45 como "123,45"
      expect(find.text('123,45'), findsOneWidget);
      expect(find.text('R\$'), findsOneWidget); // Símbolo da moeda pt_BR
    });

    testWidgets('should format input as currency for en_US', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', 'US')],
          locale: Locale('en', 'US'),
          home: Scaffold(
            body: MoneyFormField(),
          ),
        ),
      );

      final finder = find.byType(TextField);
      await tester.enterText(finder, '12345');
      await tester.pump();

      // Para en_US, 123.45 é "123.45"
      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('\$'), findsOneWidget); // Símbolo da moeda en_US
    });
  });
}
