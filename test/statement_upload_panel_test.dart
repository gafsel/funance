import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/files/picked_document.dart';
import 'package:funances/features/finance/domain/services/statement_upload_limits.dart';
import 'package:funances/features/finance/presentation/widgets/statement_upload_panel.dart';
import 'package:funances/l10n/app_localizations.dart';

/// Responde no lugar do seletor nativo de arquivos.
///
/// Os testes tocam o botão de verdade e o arquivo entra pelo mesmo caminho do
/// app — sem porta de teste no painel. Dirigir o seletor nativo num teste de
/// widget não é possível, mas `FilePicker.platform` é justamente a costura
/// que o pacote expõe para isso.
class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.picked);

  /// O que o seletor devolve. Nulo é o usuário que desistiu.
  final PlatformFile? picked;

  /// O que o painel pediu ao seletor, para o teste conferir.
  bool? askedForData;

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
    askedForData = withData;

    final file = picked;
    if (file == null) return null;

    return FilePickerResult([file]);
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

StatementUploadPanel _panel(List<PickedDocument> selected) =>
    StatementUploadPanel(
      allowedExtensions: const ['pdf', 'ofx'],
      onFileSelected: selected.add,
      title: 'Envie o extrato',
      dragOverTitle: 'Solte aqui',
      supportedFormatsText: 'PDF ou OFX',
      selectFileButtonText: 'Escolher arquivo',
    );

/// O que o seletor devolve na WEB: bytes e nenhum caminho.
///
/// Era exatamente este caso que quebrava. O painel montava `File(path!)` com
/// um caminho que não existe no navegador e media o arquivo com
/// `existsSync()`/`lengthSync()`, que na web levantam `UnsupportedError`.
PlatformFile _webPick(String name, int bytes) => PlatformFile(
  name: name,
  // O tamanho declarado pelo seletor é de propósito diferente do real: quem
  // decide é o conteúdo, não o que o seletor disse.
  size: 0,
  bytes: Uint8List(bytes),
);

/// O que o seletor devolve no DESKTOP/MOBILE quando não carrega os bytes:
/// só o caminho de um arquivo que existe no disco.
PlatformFile _diskPick(Directory dir, String name, int bytes) {
  final file = File('${dir.path}/$name')..createSync(recursive: true);
  file.writeAsBytesSync(List<int>.filled(bytes, 0));

  return PlatformFile(name: name, size: 0, path: file.path);
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
  Future<List<PickedDocument>> pick(
    WidgetTester tester,
    PlatformFile? file, {
    _FakeFilePicker? picker,
  }) async {
    FilePicker.platform = picker ?? _FakeFilePicker(file);

    final selected = <PickedDocument>[];
    await tester.pumpWidget(_app(_panel(selected)));

    await tester.tap(find.text('Escolher arquivo'));
    await tester.pumpAndSettle();

    return selected;
  }

  group('seleção na web (bytes, sem caminho)', () {
    testWidgets('o painel pede os bytes ao seletor', (tester) async {
      // Sem `withData: true` a web devolve `bytes` nulo E `path` nulo: não
      // sobra nada para enviar ao Storage.
      final picker = _FakeFilePicker(_webPick('extrato.ofx', 2048));

      await pick(tester, null, picker: picker);

      expect(picker.askedForData, isTrue);
    });

    testWidgets('arquivo sem caminho é entregue com os bytes', (tester) async {
      final selected = await pick(tester, _webPick('extrato.ofx', 2048));

      expect(selected, hasLength(1));
      expect(selected.single.name, 'extrato.ofx');
      expect(selected.single.path, isNull);
      expect(selected.single.bytes, hasLength(2048));
    });

    testWidgets('o limite mede os bytes, não o que o seletor declarou', (
      tester,
    ) async {
      final selected = await pick(
        tester,
        _webPick('extrato.pdf', 11 * 1024 * 1024),
      );

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
  });

  group('seleção com caminho (desktop e mobile)', () {
    testWidgets('sem bytes no resultado, o painel lê o arquivo do disco', (
      tester,
    ) async {
      final selected = await pick(
        tester,
        _diskPick(tempDir, 'extrato.ofx', 2048),
      );

      expect(selected, hasLength(1));
      expect(selected.single.bytes, hasLength(2048));
      expect(selected.single.path, isNotNull);
    });

    testWidgets('arquivo que sumiu é recusado, não tratado como 0 byte', (
      tester,
    ) async {
      final sumiu = PlatformFile(
        name: 'nao-existe.pdf',
        size: 0,
        path: '${tempDir.path}/nao-existe.pdf',
      );

      final selected = await pick(tester, sumiu);

      expect(
        selected,
        isEmpty,
        reason: 'sem conteúdo não há o que analisar; 0 byte passaria no limite',
      );
      expect(find.text('Não foi possível ler o arquivo.'), findsOneWidget);
    });
  });

  testWidgets('arquivo vazio não vira análise de nada', (tester) async {
    final selected = await pick(tester, _webPick('extrato.ofx', 0));

    expect(selected, isEmpty);
    expect(find.text('Não foi possível ler o arquivo.'), findsOneWidget);
  });

  testWidgets('extensão fora da lista é recusada', (tester) async {
    final selected = await pick(tester, _webPick('extrato.xlsx', 1024));

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

  group('PickedDocument', () {
    test('a extensão sai do nome, em minúsculas', () {
      final doc = PickedDocument(name: 'Extrato.PDF', bytes: Uint8List(1));

      expect(doc.extension, 'pdf');
    });

    test('nome sem extensão não inventa uma', () {
      final doc = PickedDocument(name: 'extrato', bytes: Uint8List(1));

      expect(doc.extension, '');
    });

    test('o tamanho é o dos bytes', () {
      expect(
        PickedDocument(name: 'a.ofx', bytes: Uint8List(77)).sizeInBytes,
        77,
      );
    });
  });
}
