import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renderiza o pouco de Markdown que os textos do coaching realmente usam.
///
/// Substitui o `flutter_markdown`, que foi descontinuado. Trazer um pacote
/// novo para um único texto de slide seria trocar uma dependência morta por
/// outra viva com o mesmo tamanho de superfície; o que este app precisa cabe
/// em negrito, itálico, código, link e lista com marcador.
///
/// O que não estiver na gramática aparece literalmente, e isso é proposital:
/// o texto vem de uma IA, e uma sintaxe inesperada deve virar um caractere a
/// mais na tela — nunca um slide em branco.
class SimpleMarkdown extends StatefulWidget {
  const SimpleMarkdown({
    super.key,
    required this.data,
    this.style,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onTapLink,
  });

  /// Texto em Markdown.
  final String data;

  /// Estilo do corpo.
  final TextStyle? style;

  /// Estilo dos links. Sem ele, o link herda o corpo sublinhado.
  final TextStyle? linkStyle;

  final TextAlign textAlign;

  /// Chamado com a URL do link tocado. Sem ele, o link vira texto comum —
  /// quem exibe decide o que é um destino aceitável.
  final void Function(String href)? onTapLink;

  @override
  State<SimpleMarkdown> createState() => _SimpleMarkdownState();
}

class _SimpleMarkdownState extends State<SimpleMarkdown> {
  /// Os reconhecedores de toque dos links vivem enquanto o span existir e
  /// precisam ser descartados na mão; guardá-los aqui é o que evita vazá-los a
  /// cada rebuild.
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final TextStyle bodyStyle =
        widget.style ?? DefaultTextStyle.of(context).style;

    return SelectableText.rich(
      TextSpan(
        style: bodyStyle,
        children: _buildSpans(bodyStyle),
      ),
      textAlign: widget.textAlign,
    );
  }

  List<InlineSpan> _buildSpans(TextStyle bodyStyle) {
    final List<InlineSpan> spans = <InlineSpan>[];
    final List<String> lines = widget.data.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String? item = _bulletContent(line);

      if (item == null) {
        spans.addAll(_inlineSpans(line, bodyStyle));
      } else {
        // O marcador é desenhado pelo app: a sintaxe do Markdown ("- ", "* ")
        // não é o que o usuário deve ler.
        spans.add(const TextSpan(text: '•  '));
        spans.addAll(_inlineSpans(item, bodyStyle));
      }

      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }

    return spans;
  }

  /// O conteúdo de uma linha de lista, ou `null` se a linha não for uma.
  static String? _bulletContent(String line) {
    final RegExpMatch? match = _bullet.firstMatch(line);

    return match?.group(1);
  }

  List<InlineSpan> _inlineSpans(String text, TextStyle bodyStyle) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int cursor = 0;

    for (final RegExpMatch match in _inline.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      spans.add(_spanFor(match, bodyStyle));
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans;
  }

  InlineSpan _spanFor(RegExpMatch match, TextStyle bodyStyle) {
    final String? linkText = match.group(1);
    if (linkText != null) return _link(linkText, match.group(2)!, bodyStyle);

    final String? strong = match.group(3) ?? match.group(4);
    if (strong != null) {
      return TextSpan(
        text: strong,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    final String? emphasis = match.group(5) ?? match.group(6);
    if (emphasis != null) {
      return TextSpan(
        text: emphasis,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return TextSpan(
      text: match.group(7),
      style: const TextStyle(fontFamily: 'monospace'),
    );
  }

  InlineSpan _link(String text, String href, TextStyle bodyStyle) {
    final void Function(String href)? onTap = widget.onTapLink;

    // Sem quem trate o toque, o link vira texto comum: sublinhar algo que não
    // leva a lugar nenhum é pior do que não sublinhar.
    if (onTap == null) return TextSpan(text: text);

    final recognizer = TapGestureRecognizer()..onTap = () => onTap(href);
    _recognizers.add(recognizer);

    return TextSpan(
      text: text,
      style:
          widget.linkStyle ??
          bodyStyle.copyWith(decoration: TextDecoration.underline),
      recognizer: recognizer,
    );
  }
}

/// Linha de lista: "- item" ou "* item", com recuo opcional.
final RegExp _bullet = RegExp(r'^\s*[-*]\s+(.*)$');

/// Marcações inline, na ordem em que precisam ser tentadas: o link vem antes
/// do itálico para que o `*` dentro de uma URL não abra ênfase, e `**` antes
/// de `*` pelo mesmo motivo.
final RegExp _inline = RegExp(
  r'\[([^\]]+)\]\(([^)\s]+)\)'
  r'|\*\*([^*]+)\*\*'
  r'|__([^_]+)__'
  r'|\*([^*]+)\*'
  r'|_([^_]+)_'
  r'|`([^`]+)`',
);
