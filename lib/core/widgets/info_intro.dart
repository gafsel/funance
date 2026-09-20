import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/intro/intro_store.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';

/// A explicação de uma tela, FORA do corpo dela.
///
/// Nasceu nas folhas do HUD, e o dono foi direto ao ponto: *"a descrição
/// ocupa muito espaço e o que importa fica espremido num scroll na parte de
/// baixo da tela"*. Depois ele pediu o mesmo para a vitrine de conquistas —
/// *"a descrição de como ganhar xp pode ser ocultada e mostrada apenas na
/// primeira vez que for aberto, como defini para os ícones do jogo"* —, e é
/// por isso que isto mora em `core`: são cinco telas com a mesma regra, e
/// duas implementações dela divergiriam na primeira mudança.
///
/// O que muda por tela é só o CONTEÚDO do painel. O resto — quando ele
/// aparece, como ele aparece e como ele some — é igual em todas.
///
/// Dois formatos, e a escolha é de leitura:
///
/// * **celular** — folha modal SOBRE a tela. A alternativa era uma seção
///   expansível no topo, e ela foi descartada: abrir a explicação empurraria
///   o conteúdo para baixo e mexeria no scroll, que é exatamente a queixa que
///   originou este trabalho. Sobreposta, a explicação some e os dados
///   continuam onde estavam, no mesmo ponto de rolagem;
/// * **tablet e desktop** (≥ [AppBreakpoints.medium]) — diálogo ANCORADO ao
///   ícone. Numa janela de 1300 px uma folha modal subindo do pé da tela
///   deixa o gatilho (um ícone no alto) a meia tela de distância do que ele
///   abriu; o balão junto do ícone mantém a relação causa-efeito.
Future<void> showIntroPanel(
  BuildContext context, {
  required Widget body,
  Rect? anchor,
}) {
  final painel = _IntroPanel(body: body);

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

/// O conteúdo do painel: título, o corpo da tela e o botão de fechar.
class _IntroPanel extends StatelessWidget {
  const _IntroPanel({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    return SafeArea(
      key: const ValueKey('intro-panel'),
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
                    l10n.introPanelTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            // O corpo ROLA e o botão não: "Entendi" é a saída, e uma saída
            // que sai da tela junto com o último parágrafo prende quem só
            // queria voltar para o conteúdo.
            Flexible(child: SingleChildScrollView(child: body)),
            AppSpacing.gapMd,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: const ValueKey('intro-panel-got-it'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.introPanelGotIt),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// As frases de uma explicação, da mais importante para a menos.
///
/// É o corpo das quatro folhas do HUD: jogo, financeiro e XP. As três linhas
/// existem juntas porque cada uma responde a uma pessoa diferente lendo a
/// MESMA tela — quem está jogando, quem quer o número e quem quer saber se
/// isso rende.
class IntroLines extends StatelessWidget {
  const IntroLines({super.key, required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) AppSpacing.gapXs,
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(
              // A primeira frase é a que se lê primeiro: tinta principal. As
              // outras ficam em tinta secundária. A hierarquia é a diferença
              // entre "leia isto" e "três parágrafos cinzas".
              color: index == 0 ? palette.ink : palette.ink2,
            ),
          ),
        ],
      ],
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

/// O ícone de informação que abre a explicação.
///
/// É o `Icons.info_outline` do app, e NÃO um anel com um "i" dentro. O anel
/// deste app é um medidor: ele existe para dizer quanto de alguma coisa está
/// cheio, e o cabeçalho de uma folha do HUD já tem um — o do próprio slot,
/// logo ali à esquerda, com a cor e o preenchimento da faixa. Um segundo anel
/// ao lado dele, cheio e sem dado nenhum por trás, seria lido como um segundo
/// medidor a 100%. O que o usuário procura quando quer ler de novo é o
/// símbolo universal de informação, e é ele que está aqui.
class InfoIntroButton extends StatelessWidget {
  const InfoIntroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onGame = false,
  });

  /// "Como funciona a Poção". Vira tooltip E rótulo de leitor de tela.
  final String label;

  final VoidCallback onPressed;

  /// O botão está sobre uma superfície de JOGO (escura nos dois temas).
  final bool onGame;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      color: onGame ? palette.onGame2 : palette.ink2,
      // O rótulo vai no ÍCONE, e não só no tooltip: `tooltip` vira a dica de
      // quem usa mouse e a "dica" da semântica, mas não o NOME do botão — e
      // um botão sem nome é anunciado como "botão" e nada mais.
      icon: Icon(Icons.info_outline, semanticLabel: label),
    );
  }
}

/// A regra do "primeira vez abre sozinho", para quem tem um painel.
///
/// Quem usa implementa [introKey] e [buildIntroBody], chama [scheduleIntro]
/// no `initState` e põe um [InfoIntroButton] com a [introAnchorKey] no
/// cabeçalho. O resto — perguntar ao disco, esperar a tela chegar, abrir o
/// painel e gravar a marca ao fechar — é igual nas cinco telas.
mixin IntroPanelMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Onde o balão do desktop se ancora.
  final GlobalKey introAnchorKey = GlobalKey();

  /// A apresentação automática acontece UMA vez por montagem, e o campo é o
  /// que garante isso: `addPostFrameCallback` roda por quadro, e sem ele um
  /// rebuild abriria um segundo painel por cima do primeiro.
  bool _introduced = false;

  String get introKey;

  Widget buildIntroBody(BuildContext context);

  /// Completa quando a tela terminou de aparecer. O padrão é "já apareceu";
  /// quem entra animando — uma folha modal — espera a animação.
  Future<void> waitIntroEntrance() => Future<void>.value();

  void scheduleIntro() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeIntroduce());
  }

  /// A primeira visita a esta tela mostra a explicação sozinha.
  ///
  /// A pergunta ao disco vem ANTES de qualquer espera de animação: quem já
  /// leu não pode pagar nem um quadro de atraso por causa de quem nunca leu.
  Future<void> _maybeIntroduce() async {
    if (_introduced) return;
    _introduced = true;

    final store = ref.read(IntroProviders.store);
    if (await store.wasSeen(introKey)) return;
    if (!mounted) return;

    await waitIntroEntrance();
    if (!mounted) return;

    await openIntro();
    await store.markSeen(introKey);
  }

  Future<void> openIntro() {
    return showIntroPanel(
      context,
      body: buildIntroBody(context),
      anchor: introAnchor(),
    );
  }

  /// O retângulo do ícone na tela, para o balão do desktop nascer colado
  /// nele. Sem render box — tela ainda não medida — o painel cai no formato
  /// de folha modal, que não depende de âncora.
  Rect? introAnchor() {
    final box = introAnchorKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// Espera uma rota modal terminar de entrar.
///
/// Um painel que aparece enquanto a folha ainda desliza mostra as duas em
/// movimento e faz o usuário achar que apertou duas vezes.
Future<void> waitModalEntrance(BuildContext context) {
  final animation = ModalRoute.of(context)?.animation;
  if (animation == null || animation.isCompleted) return Future<void>.value();

  final completer = Completer<void>();

  void listener(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      animation.removeStatusListener(listener);
      if (!completer.isCompleted) completer.complete();
    }
  }

  animation.addStatusListener(listener);
  return completer.future;
}
