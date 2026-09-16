import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O que o painel entregou a quem vai enviar o arquivo.
///
/// Os testes chamam `acceptForTest`, a mesma porta por onde passam o seletor
/// de arquivos e o arrastar-e-soltar — dirigir o `FilePicker` nativo num
/// teste de widget não é possível, mas a barreira exercitada é a de verdade.
typedef Selection = ({File file, String name});

Widget _app(StatementUploadPanel panel) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('pt'),
  home: Scaffold(body: panel),
);

StatementUploadPanel _panel(List<Selection> selected) => StatementUploadPanel(
  allowedExtensions: const ['pdf', 'ofx'],
  onFileSelected: (file, name) => selected.add((file: file, name: name)),
  title: 'Envie o extrato',
  dragOverTitle: 'Solte aqui',
  supportedFormatsText: 'PDF ou OFX',
  selectFileButtonText: 'Escolher arquivo',
);

/// Grava um arquivo de verdade: o painel mede o tamanho pelo sistema de
/// arquivos, então um fake em memória não provaria nada.
File _fileOfSize(Directory dir, String name, int bytes) {
  final file = File('${dir.path}/$name')..createSync(recursive: true);
  file.writeAsBytesSync(List<int>.filled(bytes, 0));
  return file;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('funances-upload-test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('arquivo de 11 MB não chega ao onFileSelected', (tester) async {
    final selected = <Selection>[];
    await tester.pumpWidget(_app(_panel(selected)));

    final grande = _fileOfSize(tempDir, 'extrato.pdf', 11 * 1024 * 1024);

    tester
        .state<StatementUploadPanelState>(find.byType(StatementUploadPanel))
        .acceptForTest(grande, 'extrato.pdf');
    await tester.pumpAndSettle();

    expect(
      selected,
      isEmpty,
      reason: 'o arquivo não pode subir para o Storage só para ser recusado',
    );
    // A mensagem diz o tamanho real, o limite e a saída (OFX).
    expect(find.textContaining('11.0 MB'), findsOneWidget);
    expect(find.textContaining('10 MB'), findsOneWidget);
    expect(find.textContaining('OFX'), findsWidgets);
  });

  testWidgets('arquivo dentro do limite é entregue', (tester) async {
    final selected = <Selection>[];
    await tester.pumpWidget(_app(_panel(selected)));

    final pequeno = _fileOfSize(tempDir, 'extrato.ofx', 2048);

    tester
        .state<StatementUploadPanelState>(find.byType(StatementUploadPanel))
        .acceptForTest(pequeno, 'extrato.ofx');
    await tester.pumpAndSettle();

    expect(selected, hasLength(1));
    expect(selected.single.name, 'extrato.ofx');
  });

  testWidgets('arquivo inexistente é recusado, não tratado como 0 byte', (
    tester,
  ) async {
    final selected = <Selection>[];
    await tester.pumpWidget(_app(_panel(selected)));

    final sumiu = File('${tempDir.path}/nao-existe.pdf');
    expect(sumiu.existsSync(), isFalse);

    tester
        .state<StatementUploadPanelState>(find.byType(StatementUploadPanel))
        .acceptForTest(sumiu, 'nao-existe.pdf');
    await tester.pumpAndSettle();

    expect(
      selected,
      isEmpty,
      reason: 'sem arquivo não há o que analisar; 0 byte passaria no limite',
    );
    expect(find.text('Não foi possível ler o arquivo.'), findsOneWidget);
  });

  testWidgets('extensão fora da lista é recusada', (tester) async {
    final selected = <Selection>[];
    await tester.pumpWidget(_app(_panel(selected)));

    final planilha = _fileOfSize(tempDir, 'extrato.xlsx', 1024);

    tester
        .state<StatementUploadPanelState>(find.byType(StatementUploadPanel))
        .acceptForTest(planilha, 'extrato.xlsx');
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(find.textContaining('Formato não suportado'), findsOneWidget);
  });

  test('o limite do painel é o mesmo do servidor', () {
    expect(StatementUploadLimits.maxBytes, 10 * 1024 * 1024);
  });
}
