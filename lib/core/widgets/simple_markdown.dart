import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renderiza o pouco de Markdown que os textos do coaching realmente usam.
///
/// Substitui o `flutter_markdown`, que foi descontinuado. Trazer um pacote
/// novo para um único texto de slide seria trocar uma dependência morta por
/// outra viva com o mesmo tamanho de superfície.
///
/// A gramática segue o que a IA de fato emite: título, divisor, citação,
/// lista, negrito, itálico, negrito-itálico, código e link.
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
    final List<MarkdownBlock> blocks = parseMarkdownBlocks(widget.data);

    if (blocks.length == 1) return _render(blocks.single, bodyStyle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [for (final block in blocks) _render(block, bodyStyle)],
    );
  }

  Widget _render(MarkdownBlock block, TextStyle bodyStyle) {
    return switch (block) {
      MarkdownDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          height: 1,
          color: (bodyStyle.color ?? Colors.grey).withValues(alpha: 0.4),
        ),
      ),
      MarkdownHeading(:final text, :final level) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _text(
          text,
          bodyStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: (bodyStyle.fontSize ?? 14) * _headingScale(level),
          ),
        ),
      ),
      // A citação é indentada e marcada por uma barra, como em qualquer
      // leitor de Markdown: sem isso ela se confundiria com o texto ao redor.
      MarkdownQuote(:final text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: (bodyStyle.color ?? Colors.grey).withValues(alpha: 0.5),
              ),
            ),
          ),
          child: _text(text, bodyStyle.copyWith(fontStyle: FontStyle.italic)),
        ),
      ),
      MarkdownParagraph(:final text) => _text(text, bodyStyle),
    };
  }

  static double _headingScale(int level) => switch (level) {
    1 => 1.5,
    2 => 1.3,
    _ => 1.15,
  };

  Widget _text(String source, TextStyle style) {
    return SelectableText.rich(
      TextSpan(style: style, children: _inlineSpans(source, style)),
      textAlign: widget.textAlign,
    );
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
    final String? linkText = match.group(_linkText);
    if (linkText != null) {
      return _link(linkText, match.group(_linkHref)!, bodyStyle);
    }

    final String? strongEm =
        match.group(_strongEmStar) ?? match.group(_strongEmUnderscore);
    if (strongEm != null) {
      return TextSpan(
        text: strongEm,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final String? strong =
        match.group(_strongStar) ?? match.group(_strongUnderscore);
    if (strong != null) {
      return TextSpan(
        text: strong,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    final String? emphasis = match.group(_emStar) ?? match.group(_emUnderscore);
    if (emphasis != null) {
      return TextSpan(
        text: emphasis,
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }

    return TextSpan(
      text: match.group(_code),
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

/// Um trecho do texto com um tipo de bloco.
///
/// Público porque `parseMarkdownBlocks` é o que o teste exercita: é aqui que
/// mora a decisão de o que é título, divisor e citação.
sealed class MarkdownBlock {
  const MarkdownBlock();
}

class MarkdownParagraph extends MarkdownBlock {
  const MarkdownParagraph(this.text);
  final String text;
}

class MarkdownHeading extends MarkdownBlock {
  const MarkdownHeading(this.text, this.level);
  final String text;
  final int level;
}

class MarkdownQuote extends MarkdownBlock {
  const MarkdownQuote(this.text);
  final String text;
}

class MarkdownDivider extends MarkdownBlock {
  const MarkdownDivider();
}

/// Quebra o texto em blocos.
///
/// Exposto para o teste: é aqui que mora a decisão de o que é título, divisor
/// e citação, e ela vale mais verificada do que espiada pela árvore de
/// widgets.
@visibleForTesting
List<MarkdownBlock> parseMarkdownBlocks(String data) {
  final List<MarkdownBlock> blocks = <MarkdownBlock>[];
  final List<String> paragraph = <String>[];
  final List<String> quote = <String>[];

  void flushParagraph() {
    while (paragraph.isNotEmpty && paragraph.first.trim().isEmpty) {
      paragraph.removeAt(0);
    }
    while (paragraph.isNotEmpty && paragraph.last.trim().isEmpty) {
      paragraph.removeLast();
    }
    if (paragraph.isEmpty) return;

    blocks.add(MarkdownParagraph(paragraph.join('\n')));
    paragraph.clear();
  }

  void flushQuote() {
    if (quote.isEmpty) return;

    blocks.add(MarkdownQuote(quote.join('\n')));
    quote.clear();
  }

  for (final String line in data.split('\n')) {
    if (_divider.hasMatch(line)) {
      flushQuote();
      flushParagraph();
      blocks.add(const MarkdownDivider());
      continue;
    }

    final RegExpMatch? heading = _heading.firstMatch(line);
    if (heading != null) {
      flushQuote();
      flushParagraph();
      blocks.add(MarkdownHeading(heading.group(2)!, heading.group(1)!.length));
      continue;
    }

    final RegExpMatch? quoted = _quote.firstMatch(line);
    if (quoted != null) {
      flushParagraph();
      quote.add(quoted.group(1)!);
      continue;
    }

    flushQuote();

    // O marcador é desenhado pelo app: a sintaxe do Markdown ("- ", "* ",
    // "1. ") não é o que o usuário deve ler.
    final RegExpMatch? bullet = _bullet.firstMatch(line);
    if (bullet != null) {
      paragraph.add('•  ${bullet.group(1)}');
      continue;
    }

    // Lista ordenada. O número vem do texto, e não de uma contagem nossa:
    // se a IA escreveu "1., 2., 5.", é isso que ela quis dizer — renumerar
    // seria inventar.
    final RegExpMatch? ordered = _ordered.firstMatch(line);
    paragraph.add(
      ordered == null ? line : '${ordered.group(1)}.  ${ordered.group(2)}',
    );
  }

  flushQuote();
  flushParagraph();

  // Texto vazio ainda precisa render alguma coisa: quem chama espera um
  // widget, não um espaço em branco na árvore.
  if (blocks.isEmpty) blocks.add(const MarkdownParagraph(''));

  return blocks;
}

/// Linha de lista: "- item" ou "* item", com recuo opcional.
final RegExp _bullet = RegExp(r'^\s*[-*]\s+(.*)$');

/// Linha de lista ordenada: "1. item", com recuo opcional.
final RegExp _ordered = RegExp(r'^\s*(\d{1,3})[.)]\s+(.*)$');

/// Título: de "#" a "######".
final RegExp _heading = RegExp(r'^\s*(#{1,6})\s+(.*)$');

/// Citação: "> texto".
final RegExp _quote = RegExp(r'^\s*>\s?(.*)$');

/// Divisor: três ou mais `-`, `*` ou `_` sozinhos na linha.
///
/// "sozinhos na linha" é o que separa `---` de `***Muito importante***`: o
/// segundo tem texto em volta e é ênfase, não divisor.
final RegExp _divider = RegExp(r'^\s*(?:-{3,}|\*{3,}|_{3,})\s*$');

// Índices dos grupos de `_inline`, nomeados para o `_spanFor` não virar uma
// contagem de parênteses.
const int _linkText = 1;
const int _linkHref = 2;
const int _strongEmStar = 3;
const int _strongEmUnderscore = 4;
const int _strongStar = 5;
const int _strongUnderscore = 6;
const int _emStar = 7;
const int _emUnderscore = 8;
const int _code = 9;

/// Fronteira de palavra para o `_`.
///
/// O CommonMark trata `_` e `*` de formas diferentes de propósito, e o motivo
/// aparece em nome de variável e identificador: em
/// "transport_fuel e groceries_market", o `_` NÃO abre ênfase, porque está
/// colado a letras dos dois lados. Antes o app tratava isso como itálico e
/// engolia os underscores, desfigurando o nome da categoria.
const String _notWord = r'(?<![\p{L}\p{N}])';
const String _notWordAfter = r'(?![\p{L}\p{N}])';

/// Marcações inline, na ordem em que precisam ser tentadas.
///
/// O link vem antes de tudo para que `*` e `_` dentro de uma URL não abram
/// ênfase; e as marcas triplas vêm antes das duplas, que vêm antes das
/// simples, senão `***x***` seria lido como negrito seguido de lixo.
final RegExp _inline = RegExp(
  r'\[([^\]]+)\]\(([^)\s]+)\)'
  r'|\*\*\*([^*]+)\*\*\*'
  '|${_notWord}___([^_]+)___$_notWordAfter'
  r'|\*\*([^*]+)\*\*'
  '|${_notWord}__([^_]+)__$_notWordAfter'
  r'|\*([^*]+)\*'
  '|${_notWord}_([^_]+)_$_notWordAfter'
  r'|`([^`]+)`',
  unicode: true,
);
