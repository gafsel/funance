import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funances/core/widgets/simple_markdown.dart';

/// Percorre todos os blocos da tela e devolve (texto, estilo EFETIVO) de cada
/// span.
///
/// O estilo efetivo é o que a tela realmente pinta: o bloco define o estilo na
/// raiz (título em negrito, citação em itálico) e cada marcação inline
/// acrescenta o dela por cima.
List<(String, TextStyle?)> _spans(WidgetTester tester) {
  final out = <(String, TextStyle?)>[];

  for (final SelectableText field in tester.widgetList<SelectableText>(
    find.byType(SelectableText),
  )) {
    final TextSpan root = field.textSpan!;

    root.visitChildren((span) {
      if (span is TextSpan && span.text != null) {
        out.add((span.text!, root.style?.merge(span.style) ?? span.style));
      }
      return true;
    });
  }

  return out;
}

String _plainText(WidgetTester tester) =>
    _spans(tester).map((s) => s.$1).join();

(String, TextStyle?) _spanWith(WidgetTester tester, String text) =>
    _spans(tester).firstWhere((s) => s.$1 == text);

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
  group('underscore no meio de palavra NÃO é itálico', () {
    // Regra do CommonMark, e o motivo aparece em nome de categoria e de
    // variável: `_` só abre ênfase em fronteira de palavra. O app tratava
    // isto como itálico e engolia os underscores, desfigurando o nome.
    const frase = 'Gaste menos com transport_fuel e groceries_market agora';

    testWidgets('a frase do QA sai exatamente como entrou', (tester) async {
      await _pump(tester, frase);

      expect(_plainText(tester), frase);
    });

    testWidgets('e nada dela fica em itálico', (tester) async {
      await _pump(tester, frase);

      expect(
        _spans(tester).where((s) => s.$2?.fontStyle == FontStyle.italic),
        isEmpty,
      );
    });

    testWidgets('em fronteira de palavra o underscore ainda funciona', (
      tester,
    ) async {
      await _pump(tester, 'Isso é _importante_.');

      expect(_plainText(tester), 'Isso é importante.');
      expect(_spanWith(tester, 'importante').$2?.fontStyle, FontStyle.italic);
    });

    testWidgets('o asterisco no meio da palavra continua valendo', (
      tester,
    ) async {
      // O CommonMark trata `*` e `_` de formas diferentes de propósito.
      await _pump(tester, 'super*importante*aqui');

      expect(_plainText(tester), 'superimportanteaqui');
      expect(_spanWith(tester, 'importante').$2?.fontStyle, FontStyle.italic);
    });
  });

  group('blocos que o Gemini emite', () {
    testWidgets('## vira título, sem os cerquilhas na tela', (tester) async {
      await _pump(tester, '## Diagnóstico do seu mês');

      expect(_plainText(tester), 'Diagnóstico do seu mês');

      final titulo = _spanWith(tester, 'Diagnóstico do seu mês').$2;
      expect(titulo?.fontWeight, FontWeight.bold);
    });

    testWidgets('título é maior que o corpo', (tester) async {
      await _pump(tester, '## Diagnóstico\n\nTexto normal');

      final tituloSize = _spanWith(tester, 'Diagnóstico').$2?.fontSize;
      final corpoSize = _spanWith(tester, 'Texto normal').$2?.fontSize;

      expect(tituloSize, isNotNull);
      expect(tituloSize, greaterThan(corpoSize!));
    });

    testWidgets('*** vira negrito E itálico', (tester) async {
      await _pump(tester, '***Muito importante***');

      expect(_plainText(tester), 'Muito importante');

      final estilo = _spanWith(tester, 'Muito importante').$2;
      expect(estilo?.fontWeight, FontWeight.bold);
      expect(estilo?.fontStyle, FontStyle.italic);
    });

    testWidgets('--- vira divisor', (tester) async {
      await _pump(tester, 'Antes\n---\nDepois');

      expect(find.byType(Divider), findsOneWidget);
      expect(_plainText(tester), 'AntesDepois');
    });

    testWidgets('*** sozinho na linha é divisor, não ênfase', (tester) async {
      await _pump(tester, 'Antes\n***\nDepois');

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('> vira citação indentada, sem o sinal de maior', (
      tester,
    ) async {
      await _pump(tester, '> Dica: revise seus gastos');

      expect(_plainText(tester), 'Dica: revise seus gastos');
      expect(
        _spanWith(tester, 'Dica: revise seus gastos').$2?.fontStyle,
        FontStyle.italic,
      );
    });

    testWidgets('citação de várias linhas vira um bloco só', (tester) async {
      await _pump(tester, '> Primeira\n> Segunda');

      expect(_plainText(tester), 'Primeira\nSegunda');
    });
  });

  group('marcações inline', () {
    testWidgets('negrito vira peso, e os asteriscos somem da tela', (
      tester,
    ) async {
      await _pump(tester, 'Você gastou **R\$ 300** a mais.');

      expect(_plainText(tester), 'Você gastou R\$ 300 a mais.');
      expect(_spanWith(tester, 'R\$ 300').$2?.fontWeight, FontWeight.bold);
    });

    testWidgets('lista vira marcador, não hífen solto', (tester) async {
      await _pump(tester, '- Corte o delivery\n- Reveja assinaturas');

      expect(_plainText(tester), '•  Corte o delivery\n•  Reveja assinaturas');
    });

    testWidgets('lista ordenada mantém a numeração do texto', (tester) async {
      await _pump(tester, '1. Corte o delivery\n2. Reveja assinaturas');

      expect(
        _plainText(tester),
        '1.  Corte o delivery\n2.  Reveja assinaturas',
      );
    });

    testWidgets('a numeração vem do texto, não de uma contagem nossa', (
      tester,
    ) async {
      // Se a IA escreveu 1, 2, 5, é isso que ela quis dizer; renumerar seria
      // inventar conteúdo.
      await _pump(tester, '1. Um\n2. Dois\n5. Cinco');

      expect(_plainText(tester), '1.  Um\n2.  Dois\n5.  Cinco');
    });

    testWidgets('ponto depois de palavra não vira lista', (tester) async {
      await _pump(tester, 'Economize R\$ 300. Isso ajuda.');

      expect(_plainText(tester), 'Economize R\$ 300. Isso ajuda.');
    });
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
      expect(
        _spanWith(tester, 'planejamento').$2?.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('underscore dentro da URL não abre ênfase', (tester) async {
      await _pump(
        tester,
        'Veja [o plano](https://funance.app/my_plan_page) agora.',
        onTapLink: (_) {},
      );

      expect(_plainText(tester), 'Veja o plano agora.');
    });

    testWidgets('sem quem trate o toque, o link vira texto comum', (
      tester,
    ) async {
      await _pump(tester, 'Veja o [planejamento](https://funance.app/plan).');

      expect(
        _spanWith(tester, 'planejamento').$2?.decoration,
        isNot(TextDecoration.underline),
      );
    });
  });

  group('texto que a IA pode gerar', () {
    testWidgets('sintaxe incompleta aparece literalmente, sem quebrar', (
      tester,
    ) async {
      // Um asterisco solto tem que virar um caractere a mais na tela, nunca
      // um slide em branco.
      await _pump(tester, 'Gastou **muito e [link sem destino');

      expect(_plainText(tester), 'Gastou **muito e [link sem destino');
    });

    testWidgets('texto vazio não quebra a tela', (tester) async {
      await _pump(tester, '');

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('as quebras de linha de um parágrafo são preservadas', (
      tester,
    ) async {
      await _pump(tester, 'Primeira\n\nSegunda');

      expect(_plainText(tester), 'Primeira\n\nSegunda');
    });
  });

  group('divisão em blocos', () {
    test('um texto corrido é um bloco só', () {
      expect(parseMarkdownBlocks('oi'), [isA<MarkdownParagraph>()]);
    });

    test('título, corpo, divisor e citação viram quatro blocos', () {
      final blocos = parseMarkdownBlocks(
        '## Diagnóstico\nSeu mês foi bom.\n---\n> Dica: revise.',
      );

      expect(blocos, [
        isA<MarkdownHeading>(),
        isA<MarkdownParagraph>(),
        isA<MarkdownDivider>(),
        isA<MarkdownQuote>(),
      ]);
    });

    test('o nível do título é o número de cerquilhas', () {
      expect((parseMarkdownBlocks('# A').single as MarkdownHeading).level, 1);
      expect((parseMarkdownBlocks('### A').single as MarkdownHeading).level, 3);
    });
  });
}
