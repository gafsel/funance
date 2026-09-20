import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/observability/app_logger.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/arena/presentation/widgets/hud_format.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';
import 'package:funances/features/arena/presentation/widgets/hud_sheets.dart';
import 'package:go_router/go_router.dart';

/// A faixa MENSAL no pé da Arena: quatro ícones e nada mais.
///
/// O embate acima é semanal. Aqui embaixo o escopo muda, e a separação é
/// deliberada: HPs em cima, leitura do mês embaixo — uma visão geral que não
/// disputa o destaque com o desafio da semana.
///
/// Cada ícone responde a três gestos: ver (o anel e a tinta), tocar (a folha
/// com os números) e segurar (a tela de dados de onde aqueles números saem).
class ArenaHudFooter extends ConsumerStatefulWidget {
  const ArenaHudFooter({
    super.key,
    required this.height,
    this.compact = false,
    this.reserveNotch = false,
  });

  final double height;

  /// Celular: ícone e tipografia menores.
  final bool compact;

  /// Abre um vão no MEIO da faixa para o botão de lançar.
  ///
  /// O FAB é entalhado no centro da barra inferior — decisão de produto, em
  /// todas as telas principais — e a metade de cima dele sobe para dentro do
  /// corpo da tela. O QA mediu a sobreposição: `Rect(172,708→228,764)` do
  /// botão contra `0,680→400,736` da faixa, 28px de ovo e vila escondidos
  /// atrás do círculo dourado.
  ///
  /// Quem cede é a faixa, e não o botão: lançar é a ação que o app existe
  /// para receber. Dois slots de cada lado do vão.
  final bool reserveNotch;

  @override
  ConsumerState<ArenaHudFooter> createState() => _ArenaHudFooterState();
}

class _ArenaHudFooterState extends ConsumerState<ArenaHudFooter> {
  /// A última falha já relatada. Existe porque `build` roda muitas vezes com
  /// o mesmo erro — a cada quadro de animação da cena acima — e o relatório
  /// não pode receber a mesma exceção quarenta vezes por segundo.
  Object? _reported;

  /// A faixa fica quieta, mas o erro NÃO some.
  ///
  /// Ela nasceu silenciosa de propósito: uma luta acontece logo acima, e um
  /// texto de erro no pé rouba a atenção dela para dizer "não sei". O que
  /// estava errado era o silêncio ser TOTAL — a falha não chegava a lugar
  /// nenhum, e uma faixa vazia em produção era indistinguível de uma faixa
  /// carregando. Quem não vê é o usuário; quem precisa ver é o relatório.
  void _report(AsyncValue<HudState> async) {
    final error = async.error;
    if (error == null || identical(error, _reported)) return;

    _reported = error;
    AppLogger.error(
      'HUD mensal: a leitura do rodapé falhou',
      error,
      async.stackTrace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(HudViewProviders.state);
    final isBusiness = ref.watch(ArenaViewProviders.isBusiness);

    _report(async);

    return Container(
      key: const ValueKey('arena-footer-slot'),
      height: widget.height,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gameFrame, width: 0.5)),
      ),
      // A faixa NUNCA muda de altura: ela é a mesma em carregamento, em erro
      // e com os quatro ícones. Foi para isso que ela nasceu reservada — uma
      // faixa que cresce quando os dados chegam reorganiza a cena, a altura
      // da Home e os quatro goldens de uma vez. E enquanto não há o que
      // mostrar ela fica VAZIA: sem esqueleto pulsante e sem texto de erro,
      // porque uma luta está acontecendo logo acima e quatro retângulos
      // piscando no pé roubariam a atenção dela para dizer "ainda não sei".
      child: async.when(
        loading: () => const SizedBox.expand(),
        error: (_, _) => const SizedBox.expand(),
        data: (hud) => LayoutBuilder(
          builder: (context, constraints) => _Slots(
            hud: hud,
            compact: widget.compact,
            isBusiness: isBusiness,
            reserveNotch: widget.reserveNotch,
            // O NOME sob cada figura só onde há largura para ele. Num
            // celular quatro rótulos a mais disputam os mesmos 400 px com
            // quatro números, e é o número que perde. Do tablet para cima a
            // faixa tem folga, e "Poção / Vila / Ovo / Gota" poupa o toque
            // que só serve para descobrir o que aquele desenho é.
            showNames: !constraints.layout.isCompact,
          ),
        ),
      ),
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots({
    required this.hud,
    required this.compact,
    required this.isBusiness,
    required this.showNames,
    required this.reserveNotch,
  });

  final HudState hud;
  final bool compact;
  final bool isBusiness;
  final bool showNames;
  final bool reserveNotch;

  /// Largura do vão do botão de lançar, em pixels lógicos.
  ///
  /// O FAB tem 56 de diâmetro e o `notchMargin` da barra soma mais um respiro
  /// de cada lado. 76 deixa 10px de folga entre o círculo e o slot vizinho —
  /// o bastante para o anel não encostar no dourado.
  static const double notchWidth = 76;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;

    final potion = hudPotionSemantics(l10n, hud.potion, locale);
    final village = hudVillageSemantics(l10n, hud.village);
    final egg = hudEggSemantics(l10n, hud.egg, locale);
    final drop = hudDropSemantics(l10n, hud.drop, locale);

    return Row(
      children: [
        Expanded(
          child: _Slot(
            slot: HudSlot.potion,
            name: l10n.hudPotionTitle,
            value: hudTierLabel(l10n, hud.potion.ratio),
            semantics: potion,
            showName: showNames,
            color: hud.potion.isFilled
                ? AppColors.success
                : AppColors.inkInverse2,
            filled: hud.potion.isFilled,
            progress: hud.potion.ratio.fill,
            compact: compact,
            // A poção brilha quando muda de classe: é a única das quatro em
            // que subir é uma boa notícia, e a única que ganha festa.
            celebrateOn: hud.potion.ratio.tier,
            onTap: () => HudSheets.potion(context, hud),
            path: '/workspace/accounts?type=investment',
          ),
        ),
        Expanded(
          child: _Slot(
            slot: HudSlot.village,
            // "Vila" também na empresa. O nome do ícone é o do JOGO, e o
            // jogo é o mesmo nos dois workspaces; quem troca de vocabulário
            // é o texto financeiro da mini explicação, que fala em centro de
            // custo. Chamar o ícone de "Centros de custo" fazia a empresa
            // perder a única metáfora que a faixa tem.
            name: l10n.hudVillageTitle,
            value: hud.village.isEmpty
                ? l10n.hudUnknown
                : '${hud.village.aliveCount}/${hud.village.plannedCount}',
            semantics: village,
            showName: showNames,
            color: hudVillageColor(hud.village),
            filled: !hud.village.isEmpty,
            progress: hud.village.ring,
            compact: compact,
            onTap: () =>
                HudSheets.village(context, hud, isBusiness: isBusiness),
            path: '/planning',
          ),
        ),
        // O vão do botão de lançar, entre a vila e o ovo.
        if (reserveNotch) const SizedBox(width: notchWidth),
        Expanded(
          child: _Slot(
            slot: HudSlot.egg,
            name: l10n.hudEggTitle,
            value: hudRatioLabel(l10n, hud.egg.ratio, locale),
            semantics: egg,
            showName: showNames,
            color: hudEggRingColor(hud.egg),
            filled: !hud.egg.isEmpty,
            progress: hud.egg.ratio.fill,
            stage: hud.egg.stage,
            trembling: hud.egg.isTrembling,
            compact: compact,
            onTap: () => HudSheets.egg(context, hud),
            path: '/workspace/accounts?type=creditCard',
          ),
        ),
        Expanded(
          child: _Slot(
            slot: HudSlot.drop,
            name: l10n.hudDropTitle,
            value: hudRatioLabel(l10n, hud.drop.ratio, locale),
            semantics: drop,
            showName: showNames,
            color: hud.drop.isBlinking
                ? AppColors.violet
                : AppColors.inkInverse2,
            filled: hud.drop.isBlinking,
            progress: hud.drop.ratio.fill,
            blinking: hud.drop.isBlinking,
            compact: compact,
            onTap: () => HudSheets.drop(context, hud),
            path: '/workspace/accounts?type=debt',
          ),
        ),
      ],
    );
  }
}

/// Um ícone da faixa: anel, figura e o número curto ao lado.
class _Slot extends StatefulWidget {
  const _Slot({
    required this.slot,
    required this.name,
    required this.value,
    required this.semantics,
    required this.showName,
    required this.color,
    required this.filled,
    required this.progress,
    required this.compact,
    required this.onTap,
    required this.path,
    this.stage = 0,
    this.trembling = false,
    this.blinking = false,
    this.celebrateOn,
  });

  final HudSlot slot;
  final String name;
  final String value;

  /// O par que o leitor de tela recebe: o número por extenso e o ESTADO que
  /// a cor comunica.
  final ({String value, String state}) semantics;

  /// Desenhar o nome sob a figura. Só do tablet para cima.
  final bool showName;

  final Color color;
  final bool filled;
  final double progress;
  final bool compact;
  final VoidCallback onTap;

  /// Para onde o toque LONGO leva.
  final String path;

  final int stage;
  final bool trembling;
  final bool blinking;

  /// Quando este valor muda, a figura dá um brilho. É o que a poção usa ao
  /// ganhar classe.
  final Object? celebrateOn;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> with TickerProviderStateMixin {
  /// O ciclo contínuo: a gota que pisca e o ovo que treme.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// O brilho de uma vez só: a poção que ganhou classe.
  ///
  /// É um controlador SEPARADO porque os dois movimentos têm ciclos de vida
  /// opostos — um repete enquanto a condição existir, o outro acontece uma
  /// vez e acaba. Com um controlador só, a sincronização do ciclo matava o
  /// brilho no quadro seguinte ao disparo.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: AppDurations.celebrate,
  );

  @override
  void didUpdateWidget(_Slot old) {
    super.didUpdateWidget(old);

    // `old.celebrateOn != null` evita a festa da PRIMEIRA leitura: a classe
    // que chega do Firestore não foi conquistada agora.
    if (widget.celebrateOn != old.celebrateOn &&
        old.celebrateOn != null &&
        !AppDurations.reduceMotion(context)) {
      _flash.forward(from: 0);
    }

    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  /// Liga ou desliga o movimento contínuo.
  ///
  /// "Reduzir movimento" para o ciclo no zero — e parar no zero importa: a
  /// gota parada no meio de um piscar ficaria meio transparente para sempre,
  /// e o ovo, torto.
  void _sync() {
    final moves =
        (widget.blinking || widget.trembling) &&
        !AppDurations.reduceMotion(context) &&
        TickerMode.valuesOf(context).enabled;

    if (moves && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!moves && _loop.isAnimating) {
      _loop
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final glyphSize = widget.compact ? 20.0 : 24.0;
    final ringSize = widget.compact ? 30.0 : 36.0;

    final figuraEValor = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_loop, _flash]),
          builder: (context, child) => _animated(child!),
          child: HudRing(
            progress: widget.progress,
            color: widget.color,
            size: ringSize,
            stroke: widget.compact ? 2.5 : 3,
            child: HudGlyph(
              slot: widget.slot,
              color: widget.color,
              size: glyphSize,
              stage: widget.stage,
              filled: widget.filled,
            ),
          ),
        ),
        AppSpacing.gapXxs,
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.value,
              maxLines: 1,
              style:
                  (widget.compact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.labelMedium)
                      ?.copyWith(color: AppColors.inkInverse),
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      // O rótulo carrega o JULGAMENTO, e não só o número: "Ovo: 1,1× da
      // receita, faturas acima da receita, perigo". O que a cor diz sem
      // texto tem de ser dito em texto para quem não a vê.
      label: l10n.hudSlotSemantics(
        widget.name,
        widget.semantics.value,
        widget.semantics.state,
      ),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: widget.onTap,
        onLongPress: () => context.push(widget.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: widget.showName
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    figuraEValor,
                    // O nome é EXCLUÍDO da semântica: ele já está no rótulo
                    // do botão, e lido duas vezes viraria "Ovo: … Ovo".
                    ExcludeSemantics(
                      child: Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.inkInverse2,
                        ),
                      ),
                    ),
                  ],
                )
              : Center(child: figuraEValor),
        ),
      ),
    );
  }

  /// O movimento de cada figura.
  Widget _animated(Widget child) {
    var painted = child;

    if (_flash.value > 0) {
      // O brilho da promoção: cresce e volta.
      painted = Transform.scale(
        scale: 1 + 0.18 * _pingPong(_flash.value),
        child: painted,
      );
    }

    if (widget.blinking) {
      // Piscar é OPACIDADE e não sumiço: a gota nunca desaparece, senão o
      // rodapé ficaria com um buraco a cada segundo.
      return Opacity(
        opacity: 0.55 + 0.45 * _pingPong(_loop.value),
        child: painted,
      );
    }

    if (widget.trembling) {
      // Um tremor de menos de um pixel e meio. Ovo que sacode a faixa inteira
      // vira enfeite; este é um nervoso de canto de olho.
      final t = _loop.value;
      return Transform.translate(
        offset: Offset(1.5 * _pingPong(t) * (t < 0.5 ? 1 : -1), 0),
        child: painted,
      );
    }

    return painted;
  }

  /// 0 → 1 → 0. É o que faz tudo aqui VOLTAR ao lugar em vez de saltar no
  /// fim do ciclo.
  static double _pingPong(double t) => 1 - (2 * t - 1).abs();
}
