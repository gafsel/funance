import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// O aceite MECÂNICO do design system.
///
/// Três rodadas de QA acharam a mesma família de defeito de três jeitos
/// diferentes: um hexadecimal solto, um `TextStyle` inline, um raio escrito à
/// mão. Cada um deles foi corrigido no arquivo em que apareceu, e nada
/// impedia o próximo de entrar — a revisão humana é boa para julgar uma
/// decisão de desenho e péssima para varrer 400 arquivos atrás de
/// `Colors.grey`.
///
/// Este teste é a varredura. Ele não julga nada: só diz onde uma decisão de
/// cor, tipografia ou raio foi tomada fora do único lugar que pode tomá-la.
void main() {
  /// Onde os tokens moram — e o único lugar onde um valor cru é legítimo.
  final tokens = RegExp(r'^lib[/\\]core[/\\]theme[/\\]');

  /// Código gerado não é escrito por ninguém, e reescrevê-lo é impossível.
  bool isGenerated(String path) =>
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      path.contains('${Platform.pathSeparator}l10n${Platform.pathSeparator}');

  List<File> sourceFiles() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !isGenerated(f.path))
      .toList();

  /// As linhas de código de um arquivo, sem comentário nenhum.
  ///
  /// Sem isto, a documentação que EXPLICA por que um token existe — "é um
  /// token e não um `Colors.transparent` solto" — seria contada como
  /// infração, e a regra puniria justamente quem a registrou.
  Iterable<(int, String)> codeLines(File file) sync* {
    var inBlock = false;
    final lines = file.readAsLinesSync();

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      if (inBlock) {
        final end = line.indexOf('*/');
        if (end < 0) continue;
        line = line.substring(end + 2);
        inBlock = false;
      }

      final block = line.indexOf('/*');
      if (block >= 0) {
        inBlock = !line.contains('*/', block);
        line = line.substring(0, block);
      }

      final slash = line.indexOf('//');
      if (slash >= 0) line = line.substring(0, slash);

      if (line.trim().isEmpty) continue;
      yield (i + 1, line);
    }
  }

  void semDecisaoSolta({
    required String nome,
    required RegExp padrao,
    required String use,
  }) {
    test('$nome só em core/theme', () {
      final infratores = <String>[];

      for (final file in sourceFiles()) {
        if (tokens.hasMatch(file.path)) continue;

        for (final (numero, line) in codeLines(file)) {
          if (padrao.hasMatch(line)) {
            infratores.add('${file.path}:$numero');
          }
        }
      }

      expect(
        infratores,
        isEmpty,
        reason: '$use — ${infratores.join(', ')}',
      );
    });
  }

  // `AppColors` não casa: o `C` vem depois de uma letra.
  semDecisaoSolta(
    nome: 'a paleta do Material',
    padrao: RegExp(r'(^|[^A-Za-z])Colors\.'),
    use: 'use AppColors ou context.palette',
  );

  semDecisaoSolta(
    nome: 'hexadecimal cru',
    padrao: RegExp(r'Color\(0x'),
    use: 'a cor nova é um token em AppColors',
  );

  semDecisaoSolta(
    nome: 'TextStyle inline',
    padrao: RegExp(r'(^|[^A-Za-z])TextStyle\('),
    use:
        'use theme.textTheme.<slot> (e `copyWith` para a tinta), ou um token '
        'em AppTypography',
  );

  semDecisaoSolta(
    nome: 'raio escrito à mão',
    padrao: RegExp(r'BorderRadius\.circular\('),
    use: 'use AppRadius',
  );

  test('a varredura enxerga o próprio arquivo de tokens', () {
    // Guarda da guarda: se o filtro de comentários ou a lista de arquivos
    // quebrar, os testes acima passam a passar por vacuidade. `app_theme.dart`
    // usa `Colors.transparent` de propósito e em código — é o caso conhecido
    // que prova que o padrão casa.
    final tema = File('lib/core/theme/app_theme.dart');
    final achou = codeLines(
      tema,
    ).any((l) => RegExp(r'(^|[^A-Za-z])Colors\.').hasMatch(l.$2));

    expect(achou, isTrue);
  });

  test('e não confunde comentário com código', () {
    final comentario = File(
      'lib/features/coaching/presentation/screens/coaching_slides_screen.dart',
    );

    expect(
      comentario.readAsStringSync(),
      contains('Colors.white'),
      reason: 'o arquivo CITA a paleta do Material numa explicação',
    );
    expect(
      codeLines(
        comentario,
      ).any((l) => RegExp(r'(^|[^A-Za-z])Colors\.').hasMatch(l.$2)),
      isFalse,
      reason: 'mas só num comentário, e comentário não é decisão',
    );
  });
}
