import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/simple_markdown.dart';

/// Percorre os spans da tela e devolve (texto, estilo) de cada um.
List<(String, TextStyle?)> _spans(WidgetTester tester) {
  final SelectableText field = tester.widget(find.byType(SelectableText));
  final List<(String, TextStyle?)> out = <(String, TextStyle?)>[];

  field.textSpan!.visitChildren((span) {
    if (span is TextSpan && span.text != null) out.add((span.text!, span.style));
    return true;
  });

  return out;
}

String _plainText(WidgetTester tester) =>
    _spans(tester).map((s) => s.$1).join();

Future<void> _pump(
  WidgetTester tester,
  String data, {
  void Function(String href)? onTapLink,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SimpleMarkdown(data: data, onTapLink: onTapLink),
      ),
    ),
  );
}

void main() {
  testWidgets('negrito vira peso, e os asteriscos somem da tela', (
    tester,
  ) async {
    await _pump(tester, 'Você gastou **R\$ 300** a mais.');

    expect(_plainText(tester), 'Você gastou R\$ 300 a mais.');
    expect(
      _spans(tester)
          .firstWhere((s) => s.$1 == 'R\$ 300')
          .$2
          ?.fontWeight,
      FontWeight.bold,
    );
  });

  testWidgets('itálico com underscore também é reconhecido', (tester) async {
    await _pump(tester, 'Isso é _importante_.');

    expect(_plainText(tester), 'Isso é importante.');
    expect(
      _spans(tester).firstWhere((s) => s.$1 == 'importante').$2?.fontStyle,
      FontStyle.italic,
    );
  });

  testWidgets('lista vira marcador, não hífen solto', (tester) async {
    await _pump(tester, '- Corte o delivery\n- Reveja assinaturas');

    // O usuário lê um marcador; a sintaxe do Markdown não é conteúdo.
    expect(_plainText(tester), '•  Corte o delivery\n•  Reveja assinaturas');
  });

  group('links', () {
    testWidgets('o toque entrega a URL, e só o texto aparece', (tester) async {
      final tocados = <String>[];

      await _pump(
        tester,
        'Veja o [planejamento](https://funance.app/plan) agora.',
        onTapLink: tocados.add,
      );

      expect(_plainText(tester), 'Veja o planejamento agora.');

      final span = _spans(tester).firstWhere((s) => s.$1 == 'planejamento');
      expect(span.$2?.decoration, TextDecoration.underline);
    });

    testWidgets('sem quem trate o toque, o link vira texto comum', (
      tester,
    ) async {
      // Sublinhar algo que não leva a lugar nenhum é pior do que não
      // sublinhar.
      await _pump(tester, 'Veja o [planejamento](https://funance.app/plan).');

      final span = _spans(tester).firstWhere((s) => s.$1 == 'planejamento');
      expect(span.$2?.decoration, isNot(TextDecoration.underline));
    });
  });

  group('texto que a IA pode gerar', () {
    testWidgets('sintaxe incompleta aparece literalmente, sem quebrar', (
      tester,
    ) async {
      // O texto vem de uma IA. Um asterisco solto tem que virar um caractere
      // a mais na tela, nunca um slide em branco.
      await _pump(tester, 'Gastou **muito e [link sem destino');

      expect(_plainText(tester), 'Gastou **muito e [link sem destino');
    });

    testWidgets('texto vazio não quebra a tela', (tester) async {
      await _pump(tester, '');

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('as quebras de linha do original são preservadas', (
      tester,
    ) async {
      await _pump(tester, 'Primeira\n\nSegunda');

      expect(_plainText(tester), 'Primeira\n\nSegunda');
    });
  });
}
