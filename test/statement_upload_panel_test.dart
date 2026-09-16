import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:funances/l10n/app_localizations.dart';

/// O que o painel entregou a quem vai enviar o arquivo.
typedef Selection = ({File file, String name});

/// Responde no lugar do seletor nativo de arquivos.
///
/// Os testes tocam o botão de verdade e o arquivo entra pelo mesmo caminho do
/// app — sem porta de teste no painel. Dirigir o seletor nativo num teste de
/// widget não é possível, mas `FilePicker.platform` é justamente a costura
/// que o pacote expõe para isso.
class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.picked);

  /// Arquivo devolvido ao toque no botão. Nulo é o usuário que desistiu.
  final File? picked;

  /// Nome que o seletor informa, que nem sempre é o do caminho.
  String? name;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final file = picked;
    if (file == null) return null;

    return FilePickerResult([
      PlatformFile(
        path: file.path,
        name: name ?? file.uri.pathSegments.last,
        // O tamanho declarado pelo seletor é de propósito diferente do real:
        // quem decide é o arquivo no disco, não o que o seletor disse.
        size: 0,
      ),
    ]);
  }
}

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

  /// Monta o painel, escolhe [file] no seletor e devolve o que foi entregue.
  Future<List<Selection>> pick(WidgetTester tester, File? file) async {
    FilePicker.platform = _FakeFilePicker(file);

    final selected = <Selection>[];
    await tester.pumpWidget(_app(_panel(selected)));

    await tester.tap(find.text('Escolher arquivo'));
    await tester.pumpAndSettle();

    return selected;
  }

  testWidgets('arquivo de 11 MB não chega ao onFileSelected', (tester) async {
    final grande = _fileOfSize(tempDir, 'extrato.pdf', 11 * 1024 * 1024);

    final selected = await pick(tester, grande);

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
    final pequeno = _fileOfSize(tempDir, 'extrato.ofx', 2048);

    final selected = await pick(tester, pequeno);

    expect(selected, hasLength(1));
    expect(selected.single.name, 'extrato.ofx');
  });

  testWidgets('arquivo inexistente é recusado, não tratado como 0 byte', (
    tester,
  ) async {
    final sumiu = File('${tempDir.path}/nao-existe.pdf');
    expect(sumiu.existsSync(), isFalse);

    final selected = await pick(tester, sumiu);

    expect(
      selected,
      isEmpty,
      reason: 'sem arquivo não há o que analisar; 0 byte passaria no limite',
    );
    expect(find.text('Não foi possível ler o arquivo.'), findsOneWidget);
  });

  testWidgets('extensão fora da lista é recusada', (tester) async {
    final planilha = _fileOfSize(tempDir, 'extrato.xlsx', 1024);

    final selected = await pick(tester, planilha);

    expect(selected, isEmpty);
    expect(find.textContaining('Formato não suportado'), findsOneWidget);
  });

  testWidgets('desistir do seletor não entrega nada', (tester) async {
    final selected = await pick(tester, null);

    expect(selected, isEmpty);
  });

  test('o limite do painel é o mesmo do servidor', () {
    expect(StatementUploadLimits.maxBytes, 10 * 1024 * 1024);
  });
}
