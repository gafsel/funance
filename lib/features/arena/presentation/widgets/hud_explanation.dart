import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';

/// A mini explicação das folhas do HUD, agora FORA do corpo da folha.
///
/// Ela morava entre o número grande e a lista, e o dono foi direto ao ponto:
/// *"a descrição ocupa muito espaço e o que importa fica espremido num scroll
/// na parte de baixo da tela"*. Três parágrafos — jogo, financeiro e XP —
/// somam mais altura do que a folha inteira tem num celular, e quem abriu a
/// folha pela décima vez abriu para ver os números, não para reler a regra.
///
/// O texto não mudou uma vírgula (ele é o mesmo do README, seção "HUD mensal
/// da Arena"); o que mudou foi QUANDO ele aparece: sozinho na primeira
/// abertura de cada folha, e depois só a pedido, pelo ícone de informação do
/// cabeçalho.
///
/// Dois formatos, e a escolha é de leitura:
///
/// * **celular** — folha modal SOBRE a folha. A alternativa era uma seção
///   expansível no topo, e ela foi descartada: abrir a explicação empurraria
///   a lista para baixo e mexeria no scroll da folha, que é exatamente a
///   queixa que originou este trabalho. Sobreposta, a explicação some e os
///   dados continuam onde estavam, no mesmo ponto de rolagem;
/// * **tablet e desktop** (≥ [AppBreakpoints.medium]) — diálogo ANCORADO ao
///   ícone. Numa janela de 1300 px uma folha modal subindo do pé da tela
///   deixa o gatilho (um ícone no alto) a meia tela de distância do que ele
///   abriu; o balão junto do ícone mantém a relação causa-efeito.
Future<void> showHudExplanation(
  BuildContext context, {
  required List<String> lines,
  Rect? anchor,
}) {
  final painel = _ExplanationPanel(lines: lines);

  if (context.layout.isCompact || anchor == null) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSheet),
      builder: (_) => painel,
    );
  }

  return showDialog<void>(
    context: context,
    // Tocar fora fecha, e fechar por fora também é ter lido: a marca de
    // "já vi" é gravada por quem chamou, não pelo botão.
    barrierDismissible: true,
    builder: (_) => _Anchored(anchor: anchor, child: painel),
  );
}

/// O conteúdo do painel: título, as três frases e o botão de fechar.
class _ExplanationPanel extends StatelessWidget {
  const _ExplanationPanel({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return SafeArea(
      // A MESMA chave de antes: o painel é o mesmo conteúdo, e quem o
      // procurava dentro da folha continua achando — agora só depois de
      // abri-lo.
      key: const ValueKey('hud-explanation'),
      child: Padding(
        padding: AppSpacing.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: palette.ink2),
                AppSpacing.gapXs,
                Expanded(
                  child: Text(
                    l10n.hudExplanationTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            // O texto ROLA e o botão não: "Entendi" é a saída, e uma saída
            // que sai da tela junto com o terceiro parágrafo prende quem só
            // queria voltar para os números.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, line) in lines.indexed) ...[
                      if (index > 0) AppSpacing.gapXs,
                      Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          // A primeira frase é a do JOGO, e ela é a que se
                          // lê primeiro: tinta principal. As outras duas
                          // ficam em tinta secundária. A hierarquia é a
                          // diferença entre "leia isto" e "três parágrafos
                          // cinzas" — e ela é a mesma de antes.
                          color: index == 0 ? palette.ink : palette.ink2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AppSpacing.gapMd,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: const ValueKey('hud-explanation-got-it'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.hudExplanationGotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O balão colado no ícone que o abriu.
class _Anchored extends StatelessWidget {
  const _Anchored({required this.anchor, required this.child});

  final Rect anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomSingleChildLayout(
      delegate: _AnchorDelegate(anchor),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 6,
        borderRadius: AppRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _AnchorDelegate extends SingleChildLayoutDelegate {
  const _AnchorDelegate(this.anchor);

  final Rect anchor;

  /// Respiro mínimo entre o balão e a borda da janela.
  static const double _margin = AppSpacing.md;

  /// Largura de leitura do balão. Acima disso o parágrafo vira uma linha de
  /// duzentos caracteres — é o mesmo limite de [AppLayout.readingMaxWidth],
  /// medido aqui contra a JANELA e não contra a coluna de conteúdo.
  static const double _maxWidth = 420;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(
      Size(
        math.min(_maxWidth, constraints.maxWidth - _margin * 2),
        constraints.maxHeight - _margin * 2,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Abaixo do ícone e alinhado à direita dele: o ícone mora no canto
    // direito do cabeçalho, e um balão crescendo para a direita sairia da
    // janela em toda tela.
    var y = anchor.bottom + AppSpacing.xs;

    if (y + childSize.height > size.height - _margin) {
      // Não coube embaixo: sobe para cima do ícone. Se também não couber lá,
      // encosta na margem de cima — cortar o fim do texto é melhor do que
      // cortar o começo dele.
      y = math.max(_margin, anchor.top - AppSpacing.xs - childSize.height);
    }

    final x = (anchor.right - childSize.width).clamp(
      _margin,
      math.max(_margin, size.width - childSize.width - _margin),
    );

    return Offset(x.toDouble(), y);
  }

  @override
  bool shouldRelayout(_AnchorDelegate old) => old.anchor != anchor;
}

/// O ícone de informação do cabeçalho de uma folha.
///
/// É o `Icons.info_outline` do app, e NÃO um [AppRing] com um "i" dentro.
/// O anel deste app é um medidor: ele existe para dizer quanto de alguma
/// coisa está cheio, e o cabeçalho da folha já tem um — o do próprio slot,
/// logo ali à esquerda, com a cor e o preenchimento da faixa. Um segundo
/// anel ao lado dele, cheio e sem dado nenhum por trás, seria lido como um
/// segundo medidor a 100%. O que o usuário procura quando quer ler de novo é
/// o símbolo universal de informação, e é ele que está aqui.
class HudExplanationButton extends StatelessWidget {
  const HudExplanationButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  /// "Como funciona a Poção". Vira tooltip E rótulo de leitor de tela.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      color: context.palette.ink2,
      // O rótulo vai no ÍCONE, e não só no tooltip: `tooltip` vira a dica de
      // quem usa mouse e a "dica" da semântica, mas não o NOME do botão — e
      // um botão sem nome é anunciado como "botão" e nada mais.
      icon: Icon(Icons.info_outline, semanticLabel: label),
    );
  }
}
