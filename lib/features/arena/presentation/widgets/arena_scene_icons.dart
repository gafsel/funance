import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/presentation/widgets/arena_icon_glyphs.dart';
import 'package:funances/features/arena/presentation/widgets/arena_missions_sheet.dart';
import 'package:funances/features/coaching/presentation/coaching_actions.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';
import 'package:go_router/go_router.dart';

/// A faixa de ícones de jogo da cena — decisão 7 do dono.
///
/// "as missões semanais e pessoais, a bússola e o coach (...) talvez em forma
/// de ícones também, mas não necessariamente na parte inferior". Cada bloco
/// que a Home tinha em cartão virou UM ícone com o número que o cartão levava
/// uma linha inteira para dizer: pergaminho "1/3", bússola com a pontuação,
/// coach, e a faísca das pendências.
///
/// **Onde ela fica, e por que mudou.** A rodada 1 pôs os quatro numa coluna
/// no alto da lateral esquerda, e o QA achou o mago coberto a 400×544 — a
/// faixa de cena livre acima dos bonecos depende da PROPORÇÃO da caixa, e uma
/// coluna ancorada no topo não tem como acertá-la em toda altura. Agora eles
/// são uma FAIXA horizontal, logo abaixo do placar e dentro do mesmo scrim:
/// ali nunca há ator, porque o placar já está acima da cabeça do mais alto
/// deles. A não-sobreposição deixou de ser um chute e virou medida — ver
/// `ArenaGame.safeTopBand` e o teste em `home_arena_test`.
///
/// **A forma é a do rodapé mensal**, e não a do Material: anel com a figura
/// dentro, desenhada em código ([ArenaIconGlyph]), e o valor curto embaixo.
/// Ícone do Material sobre pixel art é um adesivo de outro aplicativo colado
/// no jogo — foi o segundo achado de game design do QA.
class ArenaSceneIcons extends ConsumerWidget {
  const ArenaSceneIcons({super.key, this.compact = false});

  /// Celular: anel e tipografia menores.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final missions =
        ref.watch(JourneyViewProviders.weeklyMissions).valueOrNull ??
        const <WeeklyMissionModel>[];
    final health = ref.watch(JourneyViewProviders.financialHealth).valueOrNull;
    final insight = ref.watch(CoachingViewProviders.lastInsight).valueOrNull;
    final pending = ref
        .watch(AutomaticTransactionViewProviders.automaticTransactions)
        .pendingTransactions
        .length;

    final done = missions.where((m) => m.status.isCompleted).length;
    final freshCoaching = insight != null && !insight.isDeprecated;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ArenaSceneIcon(
          glyph: ArenaGlyph.scroll,
          compact: compact,
          label: l10n.weeklyMissionsTitle,
          semanticsValue: l10n.weeklyMissionsProgress(
            '$done',
            '${missions.length}',
          ),
          // As missões abrem a folha mesmo quando não há nenhuma: o ícone é a
          // porta da semana, e uma porta que some quando o servidor ainda não
          // gerou as missões deixa o usuário sem explicação nenhuma.
          value: missions.isEmpty ? null : '$done/${missions.length}',
          filled: missions.isNotEmpty,
          progress: missions.isEmpty ? 0 : done / missions.length,
          color: AppColors.gold,
          onTap: () => ArenaMissionsSheet.show(context),
        ),
        ArenaSceneIcon(
          glyph: ArenaGlyph.compass,
          compact: compact,
          label: l10n.compassTitle,
          semanticsValue: health == null
              ? compassTierLabel(l10n, FreedomTier.unknown)
              : l10n.compassScoreOf(
                  '${health.score.round()}',
                  compassTierLabel(l10n, health.tier),
                ),
          // A pontuação, não a patente: o número cabe embaixo do anel, a
          // palavra não. Sem índice publicado o ícone continua na faixa,
          // apagado — some o toque, não a explicação.
          value: health == null ? null : '${health.score.round()}',
          filled: health != null,
          progress: health == null ? 0 : health.score / 100,
          color: health == null
              ? AppColors.inkInverse2
              : compassScoreColor(health.score),
          onTap: health == null
              ? null
              : () => FreedomCompassSheet.show(context, health),
        ),
        ArenaSceneIcon(
          glyph: ArenaGlyph.coach,
          compact: compact,
          label: l10n.coachingTitle,
          semanticsValue: freshCoaching
              ? l10n.coachingViewLast
              : l10n.coachingConsultAction,
          // O coach não tem contagem: o anel fica cheio quando há análise
          // nova para ler e vazio quando o convite é para pedir uma.
          progress: freshCoaching ? 1 : 0,
          filled: freshCoaching,
          color: freshCoaching ? AppColors.teal : AppColors.inkInverse2,
          onTap: () => CoachingActions.open(context, ref, insight),
        ),
        // A faísca NÃO some quando não há pendência: ela apaga, como os
        // outros três. Sumir tirava um ícone da faixa e reorganizava os
        // outros a cada notificação que chegava ou era consolidada — um
        // pulo de layout no meio de uma cena parada.
        ArenaSceneIcon(
          glyph: ArenaGlyph.spark,
          compact: compact,
          label: l10n.automaticTransactionTitle,
          semanticsValue: l10n.automaticTransactionPendingCount(pending),
          value: pending == 0 ? null : '$pending',
          filled: pending > 0,
          progress: 0,
          color: pending > 0 ? AppColors.danger : AppColors.inkInverse2,
          onTap: pending == 0
              ? null
              : () => context.push('/automatic-transactions'),
        ),
      ],
    );
  }
}

/// Um ícone da faixa: anel, figura dentro e o valor curto embaixo.
///
/// É a MESMA montagem dos quatro do rodapé mensal, de propósito: os dois
/// grupos moram sobre a mesma cena, e se cada um tivesse a sua forma a tela
/// viraria dois HUDs sobrepostos.
///
/// O alvo de toque é de [minTarget] em qualquer tamanho, ainda que o anel
/// desenhado encolha no celular: é o mínimo de acessibilidade, e ele não pode
/// depender do quanto a arte pediu.
class ArenaSceneIcon extends StatelessWidget {
  const ArenaSceneIcon({
    super.key,
    required this.glyph,
    required this.label,
    required this.semanticsValue,
    required this.color,
    required this.progress,
    required this.onTap,
    this.value,
    this.filled = true,
    this.compact = false,
  });

  /// Mínimo de alvo de toque, em pixels lógicos.
  static const double minTarget = 44;

  final ArenaGlyph glyph;

  /// O nome, para o leitor de tela e para o tooltip.
  final String label;

  /// O que o número NÃO consegue caber — "1 de 3 completadas", "72 de 100 •
  /// Guardião".
  final String semanticsValue;

  /// O número embaixo do anel. `null` quando não há o que contar.
  final String? value;

  /// Fração do anel, 0..1.
  final double progress;

  final Color color;

  /// Figura cheia ou contorno: contorno é o estado apagado.
  final bool filled;

  /// `null` desliga o ícone: ele continua na faixa, apagado e sem toque.
  final VoidCallback? onTap;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ringSize = compact ? 28.0 : 32.0;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      label: label,
      value: semanticsValue,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.brPill,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: minTarget),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArenaIconRing(
                      progress: progress,
                      color: color,
                      size: ringSize,
                      child: ArenaIconGlyph(
                        glyph: glyph,
                        color: color,
                        size: ringSize * 0.56,
                        filled: filled,
                      ),
                    ),
                    Text(
                      // Um traço, e não vazio: sem ele a faixa muda de ALTURA
                      // quando o último número some, e a cena inteira sobe.
                      value ?? '—',
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: value == null
                            ? AppColors.inkInverse2
                            : AppColors.inkInverse,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
