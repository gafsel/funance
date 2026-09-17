import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F3.8 — o ARB é um lugar onde texto morto se acumula sem que nada quebre:
/// nada falha quando uma chave deixa de ser usada, e nada avisa quando ela
/// existe em português e não em inglês. Estes testes são o aviso.

Map<String, String> _messages(String path) {
  final raw = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return {
    for (final entry in raw.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
}

/// Todo o código do app, menos o que o `gen-l10n` gera (que cita TODAS as
/// chaves e por isso não serve de evidência de uso).
List<File> _sourceFiles() {
  final files = <File>[];
  for (final root in ['lib', 'test']) {
    for (final entity in Directory(root).listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.startsWith('lib/l10n')) continue;
      files.add(entity);
    }
  }
  return files;
}

void main() {
  final pt = _messages('lib/l10n/app_pt.arb');
  final en = _messages('lib/l10n/app_en.arb');

  test('pt e en têm exatamente as mesmas chaves', () {
    expect(pt.keys.toSet().difference(en.keys.toSet()), isEmpty,
        reason: 'chave sem tradução em inglês');
    expect(en.keys.toSet().difference(pt.keys.toSet()), isEmpty,
        reason: 'chave sem tradução em português');
  });

  test('nenhuma chave órfã: tudo que está no ARB aparece no código', () {
    final identifiers = <String>{};
    for (final file in _sourceFiles()) {
      identifiers.addAll(
        RegExp(r'[A-Za-z_][A-Za-z0-9_]*').allMatches(file.readAsStringSync()).map(
              (m) => m.group(0)!,
            ),
      );
    }

    final orphans = pt.keys.where((k) => !identifiers.contains(k)).toList();

    expect(orphans, isEmpty, reason: 'chaves sem uso: ${orphans.join(', ')}');
  });

  test('"Party" é o grupo de categorias; "Equipe" são os membros', () {
    // Decisão de produto: o vocabulário de jogo fica com as categorias.
    for (final key in [
      'partyTitle',
      'partyHpLabel',
      'partyStatusHealthy',
      'partyEmptyTitle',
      'partyEmptyMessage',
      'partyErrorMessage',
    ]) {
      expect(
        pt[key]!.toLowerCase(),
        contains('party'),
        reason: '$key deveria falar em party',
      );
      expect(
        pt[key]!.toLowerCase(),
        isNot(contains('equipe')),
        reason: '$key mistura o vocabulário dos membros',
      );
    }

    // E os membros do workspace continuam sendo a equipe.
    expect(pt['workspaceSettingsTeamSection'], 'Equipe');
  });
}
