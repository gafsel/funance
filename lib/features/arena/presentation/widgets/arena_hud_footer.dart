import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/domain/models/hud_state.dart';
import 'package:funances/features/arena/presentation/providers/arena_providers.dart';
import 'package:funances/features/arena/presentation/providers/hud_providers.dart';
import 'package:funances/features/arena/presentation/widgets/hud_glyph.dart';
import 'package:funances/features/arena/presentation/widgets/hud_sheets.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// A faixa MENSAL no pé da Arena: quatro ícones e nada mais.
///
/// O embate acima é semanal. Aqui embaixo o escopo muda, e a separação é
/// deliberada: HPs em cima, leitura do mês embaixo — uma visão geral que não
/// disputa o destaque com o desafio da semana.
///
/// Cada ícone responde a três gestos: ver (o anel e a tinta), tocar (a folha
/// com os números) e segurar (a tela de dados de onde aqueles números saem).
class ArenaHudFooter extends ConsumerWidget {
  const ArenaHudFooter({super.key, required this.height, this.compact = false});

  final double height;

  /// Celular: ícone e tipografia menores.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(HudViewProviders.state);
    final isBusiness = ref.watch(ArenaViewProviders.isBusiness);

    return Container(
      key: const ValueKey('arena-footer-slot'),
      height: height,
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
        data: (hud) =>
            _Slots(hud: hud, compact: compact, isBusiness: isBusiness),
      ),
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots({
    required this.hud,
    required this.compact,
    required this.isBusiness,
  });

  final HudState hud;
  final bool compact;
  final bool isBusiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.locale;

    return Row(
      children: [
        Expanded(
          child: _Slot(
            slot: HudSlot.potion,
            name: l10n.hudPotionTitle,
            value: hudTierLabel(l10n, hud.potion.ratio),
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
            name: isBusiness
                ? l10n.hudVillageTitleBusiness
                : l10n.hudVillageTitle,
            value: hud.village.isEmpty
                ? l10n.hudUnknown
                : '${hud.village.aliveCount}/${hud.village.plannedCount}',
            color: _villageColor(hud.village),
            filled: !hud.village.isEmpty,
            progress: hud.village.ring,
            compact: compact,
            onTap: () =>
                HudSheets.village(context, hud, isBusiness: isBusiness),
            path: '/planning',
          ),
        ),
        Expanded(
          child: _Slot(
            slot: HudSlot.egg,
            name: l10n.hudEggTitle,
            value: hudRatioLabel(l10n, hud.egg.ratio, locale),
            color: _eggColor(hud.egg),
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

/// A tinta do anel da vila: verde enquanto cabe, laranja perto do limite,
/// vermelho quando estourou.
///
/// A vila é o único dos quatro em que o anel JULGA, e ela pode: o limite é o
/// que o próprio usuário escreveu. Nos outros três o anel só mede tamanho.
Color _villageColor(HudVillage village) {
  if (village.isEmpty) return AppColors.inkInverse2;

  final progress = village.progress ?? 0;
  if (progress > 1) return AppColors.danger;
  if (progress >= 0.9) return AppColors.warning;
  return AppColors.success;
}

/// A tinta do ovo: do verde ao vermelho conforme a razão se aproxima de um
/// mês inteiro de receita.
Color _eggColor(HudEgg egg) {
  final value = egg.ratio.value;
  if (value == null) return AppColors.inkInverse2;
  if (value >= 1) return AppColors.danger;
  if (value >= 0.5) return AppColors.warning;
  return AppColors.success;
}

/// A classe, por extenso. Sem denominador, um traço — e nunca "gole", que
/// seria um veredito sobre um número que não existe.
String hudTierLabel(AppLocalizations l10n, HudRatio ratio) {
  return switch (ratio.tier) {
    null => l10n.hudUnknown,
    HudTier.none => l10n.hudTierNone,
    HudTier.semi => l10n.hudTierSemi,
    HudTier.regular => l10n.hudTierRegular,
    HudTier.superTier => l10n.hudTierSuper,
    HudTier.hyper => l10n.hudTierHyper,
  };
}

/// A razão com UMA casa decimal — "1,1×".
///
/// Uma casa e não duas: o rodapé responde "isto é grande?", e a segunda casa
/// decimal não muda a resposta. Os centavos exatos estão na folha.
///
/// Sem denominador, um traço: "0,0×" seria um número, e número é afirmação.
String hudRatioLabel(AppLocalizations l10n, HudRatio ratio, String locale) {
  final value = ratio.value;
  if (value == null) return l10n.hudUnknown;

  final text = value.toStringAsFixed(1);

  return l10n.hudRatioTimes(
    locale.startsWith('en') ? text : text.replaceAll('.', ','),
  );
}

/// Um ícone da faixa: anel, figura e o número curto ao lado.
class _Slot extends StatefulWidget {
  const _Slot({
    required this.slot,
    required this.name,
    required this.value,
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

    return Semantics(
      button: true,
      label: l10n.hudSlotSemantics(widget.name, widget.value),
      child: InkWell(
        borderRadius: AppRadius.brMd,
        onTap: widget.onTap,
        onLongPress: () => context.push(widget.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
          ),
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
