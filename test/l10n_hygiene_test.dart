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

/// O código do APP, menos o que o `gen-l10n` gera (que cita TODAS as chaves
/// e por isso não serve de evidência de uso).
///
/// `test/` ficou de fora: um teste que afirma que uma chave NÃO aparece mais
/// na tela cita o nome dela, e isso bastava para a varredura dar a chave por
/// usada. Foi assim que `onboardingGoalsTitle` sobreviveu à própria
/// aposentadoria — o único lugar que ainda a mencionava era a asserção que
/// provava que ninguém a usa.
List<File> _sourceFiles() {
  final files = <File>[];
  for (final root in ['lib']) {
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
    // ACESSO DE MEMBRO, não "qualquer identificador": a versão anterior deste
    // teste aceitava a chave `currentBalance` como usada porque existe um
    // CAMPO com esse nome num modelo — nada a ver com a tradução. O que prova
    // uso de uma chave é `l10n.chave` (ou `.chave` num alias), e é só isso que
    // conta aqui.
    final acessos = <String>{};
    final membro = RegExp(r'\.([A-Za-z_][A-Za-z0-9_]*)');
    final nu = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

    for (final file in _sourceFiles()) {
      final fonte = file.readAsStringSync();
      acessos.addAll(membro.allMatches(fonte).map((m) => m.group(1)!));

      // Dentro de uma `extension ... on AppLocalizations` a chave é lida sem
      // ponto (`return transactionStatusPaid;`) — ali o identificador solto É
      // o acesso.
      if (fonte.contains('on AppLocalizations')) {
        acessos.addAll(nu.allMatches(fonte).map((m) => m.group(0)!));
      }
    }

    final orphans = pt.keys.where((k) => !acessos.contains(k)).toList();

    expect(orphans, isEmpty, reason: 'chaves sem uso: ${orphans.join(', ')}');
  });

  /// B6 — metadado é CONTRATO, não enfeite.
  ///
  /// Sem `@chave.placeholders`, o `gen-l10n` adivinha o tipo do argumento
  /// (`Object`) e a chave aceita qualquer coisa: um `int` onde o texto espera
  /// data, um `DateTime` onde espera número. E quando o metadado existe num
  /// ARB e falta no outro — era o caso de `journeyStreakWeeks` —, as duas
  /// traduções passam a ter ASSINATURAS diferentes, e a que não tem metadado
  /// é a que decide, porque o template é o português.
  test('toda chave com placeholder tem metadado nos DOIS idiomas', () {
    final comPlaceholder = RegExp(r'\{[A-Za-z_][A-Za-z0-9_]*[,}]');

    for (final entry in {'pt': pt, 'en': en}.entries) {
      final cru =
          jsonDecode(File('lib/l10n/app_${entry.key}.arb').readAsStringSync())
              as Map<String, dynamic>;

      final semMetadado = entry.value.entries
          .where((e) => comPlaceholder.hasMatch(e.value))
          .map((e) => e.key)
          .where((k) => !cru.containsKey('@$k'))
          .toList();

      expect(
        semMetadado,
        isEmpty,
        reason:
            'sem @placeholders em ${entry.key}: ${semMetadado.join(', ')}',
      );
    }
  });

  test('"Party" saiu do ARB junto com o bloco', () {
    // Decisão 9 do dono: *"na aba de visão geral, pode retirar a
    // visualização de Party — essa visão não faz mais sentido com a nova
    // visão de jogo"*. O bloco saiu da Visão Geral, e com ele as chaves que
    // só ele usava.
    //
    // O que este teste guarda não é a ausência em si — disso já cuida a
    // varredura de órfãs acima —, é a DIREÇÃO: o vocabulário de party era
    // uma decisão de produto ("party é o grupo de categorias, equipe são os
    // membros"), e uma chave nova com esse nome significa que o bloco
    // voltou por uma porta lateral, sem a decisão ter sido revista.
    final voltaram = pt.keys.where((k) => k.startsWith('party')).toList();

    expect(voltaram, isEmpty, reason: 'a Party voltou: ${voltaram.join(', ')}');

    // E os membros do workspace continuam sendo a equipe.
    expect(pt['workspaceSettingsTeamSection'], 'Equipe');
  });
}
