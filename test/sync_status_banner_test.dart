import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/firestore/sync_status.dart';
import 'package:funances/core/firestore/write_failures.dart';
import 'package:funances/core/widgets/sync_status_banner.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Uma tela como as do app: barra embaixo e botão flutuante ancorado nela.
///
/// É o que a primeira versão da tarja cobria — ela era um `Stack` colado no
/// rodapé, exatamente por cima da navegação.
const Key _bottomBar = Key('bottom-bar');
const Key _fab = Key('fab');

Widget _app({
  required SyncStatus status,
  int pending = 0,
}) {
  return ProviderScope(
    overrides: [
      syncStatusProvider.overrideWith((ref) => Stream.value(status)),
      pendingWriteCountProvider.overrideWith((ref) => Stream.value(pending)),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt'),
      builder: (context, child) =>
          SyncStatusBanner(child: child ?? const SizedBox.shrink()),
      home: Scaffold(
        appBar: AppBar(title: const Text('Início')),
        body: const Center(child: Text('conteúdo')),
        bottomNavigationBar: const SizedBox(
          key: _bottomBar,
          height: 60,
          child: Text('navegação'),
        ),
        floatingActionButton: FloatingActionButton(
          key: _fab,
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    ),
  );
}

/// Publica uma falha e deixa o widget reagir.
///
/// São dois `pump`: o primeiro deixa o evento do stream ser entregue, o
/// segundo desenha o quadro já com a tarja.
Future<void> _report(WidgetTester tester, WriteFailureReason reason) async {
  WriteFailures.report(reason);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUp(PendingWrites.reset);

  testWidgets('online e sem pendência, a tarja não ocupa espaço nenhum', (
    tester,
  ) async {
    await tester.pumpWidget(_app(status: SyncStatus.online));
    await tester.pump();

    expect(find.textContaining('Sem conexão'), findsNothing);
    expect(find.textContaining('Salvo neste dispositivo'), findsNothing);
  });

  testWidgets('offline mostra a tarja', (tester) async {
    await tester.pumpWidget(_app(status: SyncStatus.offline));
    await tester.pump();

    expect(find.textContaining('Sem conexão'), findsOneWidget);
  });

  testWidgets('escrita pendente em outra coleção também acende a tarja', (
    tester,
  ) async {
    await tester.pumpWidget(_app(status: SyncStatus.online, pending: 1));
    await tester.pump();

    expect(find.textContaining('Sincronizando'), findsOneWidget);
  });

  group('a tarja não pode tapar a navegação', () {
    testWidgets('ela fica ACIMA da AppBar, não sobre a barra de baixo', (
      tester,
    ) async {
      await tester.pumpWidget(_app(status: SyncStatus.offline));
      await tester.pump();

      final tarja = tester.getRect(find.textContaining('Sem conexão'));
      final appBar = tester.getRect(find.byType(AppBar));

      expect(
        tarja.bottom,
        lessThanOrEqualTo(appBar.top),
        reason: 'a tarja empurra o conteúdo; não flutua sobre ele',
      );
    });

    testWidgets('barra de baixo e botão flutuante seguem alcançáveis', (
      tester,
    ) async {
      await tester.pumpWidget(_app(status: SyncStatus.offline));
      await tester.pump();

      final tarja = tester.getRect(find.textContaining('Sem conexão'));

      // Se a tarja voltasse para o rodapé, estes dois ficariam por baixo dela.
      expect(tarja.overlaps(tester.getRect(find.byKey(_bottomBar))), isFalse);
      expect(tarja.overlaps(tester.getRect(find.byKey(_fab))), isFalse);
    });
  });

  group('falha tardia de escrita', () {
    testWidgets('aparece mesmo sem nenhuma tela para mostrá-la', (
      tester,
    ) async {
      await tester.pumpWidget(_app(status: SyncStatus.online));
      await tester.pump();

      // A tela que salvou já fechou: não há Future para completar com erro
      // nem context para uma snackbar.
      await _report(tester, WriteFailureReason.permissionDenied);

      expect(
        find.textContaining('você não tem permissão'),
        findsOneWidget,
      );
    });

    testWidgets('sai sozinha depois de um tempo', (tester) async {
      await tester.pumpWidget(_app(status: SyncStatus.online));
      await tester.pump();

      await _report(tester, WriteFailureReason.tookTooLong);
      expect(find.textContaining('não respondeu'), findsOneWidget);

      await tester.pump(const Duration(seconds: 9));
      expect(find.textContaining('não respondeu'), findsNothing);
    });

    testWidgets('pode ser dispensada na hora', (tester) async {
      await tester.pumpWidget(_app(status: SyncStatus.online));
      await tester.pump();

      await _report(tester, WriteFailureReason.notFound);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.textContaining('não existe mais'), findsNothing);
    });
  });
}
