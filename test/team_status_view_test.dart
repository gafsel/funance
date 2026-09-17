import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/error_view.dart';
import 'package:funances/features/home/domain/models/mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/team_status_view.dart';
import 'package:funances/l10n/app_localizations.dart';

/// F2.6 — a Party sumia inteira sem planejamentos e o erro do stream virava
/// `SizedBox.shrink()`: o usuário via um buraco no lugar do time, sem nada
/// indicando o que aconteceu nem o que fazer.
MissionModel _mission({List<PlanningMission> planningMissions = const []}) {
  return MissionModel(
    pendingInstallments: const [],
    completedInstallments: const [],
    overdueInstallments: const [],
    planningMissions: planningMissions,
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 1, 7),
  );
}

Widget _app(Stream<MissionModel> stream) {
  return ProviderScope(
    overrides: [
      MissionViewProviders.mission.overrideWith((ref) => stream),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      locale: Locale('pt', 'BR'),
      home: Scaffold(
        body: SingleChildScrollView(child: TeamStatusView()),
      ),
    ),
  );
}

void main() {
  testWidgets('sem planejamentos, convida a criar o primeiro limite', (
    tester,
  ) async {
    await tester.pumpWidget(_app(Stream.value(_mission())));
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));

    // O título da seção continua na tela: a Party não some mais.
    expect(find.text(l10n.partyTitle), findsOneWidget);
    expect(find.text(l10n.partyEmptyTitle), findsOneWidget);
    expect(find.text(l10n.partyEmptyMessage), findsOneWidget);
    expect(find.text(l10n.partyEmptyButton), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('erro do stream mostra mensagem e botão de tentar de novo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(Stream<MissionModel>.error(Exception('falha de rede'))),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(l10n.partyErrorMessage), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
    // A mensagem crua da exceção nunca vai para a tela.
    expect(find.textContaining('falha de rede'), findsNothing);
  });
}
