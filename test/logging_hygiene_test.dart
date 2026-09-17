import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F4.5 (QA) — um logger só, de verdade.
///
/// O app teve três destinos ao mesmo tempo: `print`/`debugPrint`, o
/// `package:logger` e `dart:developer` espalhado por repositórios, notifiers e
/// widgets. Três destinos querem dizer que, ao investigar uma falha, não há um
/// lugar para olhar — e que erro tratado em release não chegava a lugar
/// nenhum. `AppLogger` é a porta única; `dart:developer` só existe atrás dela.
void main() {
  final permitido = RegExp(r'^lib[/\\]core[/\\]observability[/\\]');

  List<File> dartFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('dart:developer só dentro de core/observability', () {
    final infratores = <String>[];

    for (final file in dartFiles()) {
      if (permitido.hasMatch(file.path)) continue;
      if (file.readAsStringSync().contains("import 'dart:developer'")) {
        infratores.add(file.path);
      }
    }

    expect(
      infratores,
      isEmpty,
      reason:
          'use AppLogger (core/observability/app_logger.dart): ${infratores.join(', ')}',
    );
  });

  test('sem print, debugPrint ou package:logger no app', () {
    final infratores = <String>[];
    final proibidos = RegExp(r"(^|\W)(print|debugPrint)\(|package:logger/");

    for (final file in dartFiles()) {
      if (file.path.endsWith('.g.dart') || file.path.contains('.freezed.')) {
        continue;
      }

      final linhas = file.readAsStringSync().split('\n');
      for (var i = 0; i < linhas.length; i++) {
        final linha = linhas[i];
        if (linha.trimLeft().startsWith('//')) continue;
        if (proibidos.hasMatch(linha)) {
          infratores.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(infratores, isEmpty, reason: infratores.join(', '));
  });
}
