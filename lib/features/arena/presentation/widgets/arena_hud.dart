import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_durations.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/utils/num_extensions.dart';
import 'package:funances/core/widgets/animated_double.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/features/arena/domain/models/arena_state.dart';
import 'package:funances/features/arena/presentation/widgets/arena_hp_bar.dart';

/// O placar da luta, no alto da cena.
///
/// A disposição é a do jogo de luta, e a escolha não é enfeite: o Street
/// Fighter resolveu há trinta e cinco anos o problema que esta tela tem —
/// mostrar DUAS vidas que se opõem, de relance, sem legenda. Quem está de que
/// lado se lê pela posição; quem está ganhando, pelo tamanho da barra; quanto
/// falta para o fim, pelo relógio do meio.
///
/// - **esquerda, enchendo para a direita**: os heróis. A vida é o saldo das
///   contas líquidas, medido contra o saldo de domingo. A hachura é o que já
///   tem dono (a vida do monstro);
/// - **direita, espelhada**: o monstro — os compromissos agendados da semana
///   mais o atraso;
/// - **centro**: o dia da semana, que é o relógio do round.
class ArenaHud extends StatelessWidget {
  const ArenaHud({
    super.key,
    required this.state,
    required this.monsterName,
    this.onTapHeroes,
    this.onTapMonster,
    this.compact = false,
  });

  final ArenaState state;

  /// O nome do bicho da semana, já traduzido.
  final String monsterName;

  final VoidCallback? onTapHeroes;
  final VoidCallback? onTapMonster;

  /// Celular: tipografia e marcador menores.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _Side(
            onTap: onTapHeroes,
            semanticsLabel: l10n.arenaHeroesSemantics(
              state.currentBalance.asCurrency(locale: context.locale),
              state.committed.asCurrency(locale: context.locale),
            ),
            title: _heroNames(context),
            badge: _heroBadge(context),
            bar: ArenaHpBar(
              ratio: state.heroHpRatio,
              committedRatio: state.committedRatio,
              overflowing: state.isOverhealed,
              color: state.heroMood == HeroMood.exhausted
                  ? context.palette.dangerText
                  : AppColors.teal,
              height: compact ? 12 : 16,
            ),
            value: _HeroValue(state: state, compact: compact),
          ),
        ),
        AppSpacing.gapXs,
        ArenaDayMarker(
          label: l10n.arenaDayOfWeek(state.day.ordinal, 7),
          semanticsLabel: l10n.arenaDaysLeft(state.day.daysLeft),
          diameter: compact ? 34 : 42,
        ),
        AppSpacing.gapXs,
        Expanded(
          child: _Side(
            mirrored: true,
            onTap: onTapMonster,
            semanticsLabel: l10n.arenaMonsterSemantics(
              state.monsterHp.asCurrency(locale: context.locale),
              state.monsterMaxHp.asCurrency(locale: context.locale),
            ),
            title: Text(
              monsterName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: context.palette.onGame2),
            ),
            badge: _monsterBadge(context),
            bar: ArenaHpBar(
              ratio: state.monsterHpRatio,
              mirrored: true,
              color: AppColors.violet,
              height: compact ? 12 : 16,
            ),
            value: _MonsterValue(state: state, compact: compact),
          ),
        ),
      ],
    );
  }

  /// Os nomes dos membros, separados por ponto. É quem está lutando.
  Widget _heroNames(BuildContext context) {
    final palette = context.palette;
    final names = state.heroes.map((h) => h.name).join(' · ');

    return Text(
      names.isEmpty ? context.l10n.arenaHeroesFallback : names,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: palette.onGame2),
    );
  }

  Widget? _heroBadge(BuildContext context) {
    final l10n = context.l10n;

    if (state.heroMood == HeroMood.exhausted) {
      return StatusPill(
        label: l10n.arenaExhausted,
        tone: StatusTone.danger,
        dense: true,
        onGame: true,
      );
    }

    if (state.isOverhealed) {
      return StatusPill(
        label: l10n.arenaOverheal(
          state.overheal.asCurrency(locale: context.locale),
        ),
        tone: StatusTone.ok,
        dense: true,
        onGame: true,
      );
    }

    if (state.extraMembers > 0) {
      return StatusPill(
        label: l10n.arenaTeamExtra(state.extraMembers),
        tone: StatusTone.neutral,
        dense: true,
        onGame: true,
      );
    }

    return null;
  }

  Widget? _monsterBadge(BuildContext context) {
    final l10n = context.l10n;

    if (state.isDefeated) {
      return StatusPill(
        label: l10n.arenaMonsterDefeated,
        tone: StatusTone.ok,
        dense: true,
        onGame: true,
      );
    }

    if (state.isEnraged) {
      // Só o VALOR, sem a palavra "enfurecido": a 400px o selo completo
      // saía cortado em "Enfureci…", que não informa nada. Quem diz que o
      // bicho está enfurecido é a cara dele — a skin de demônio — e a cor de
      // perigo do selo; o que o texto tem de carregar é o número.
      return StatusPill(
        label: l10n.arenaEnraged(
          state.overdueAmount.asCurrency(locale: context.locale),
        ),
        tone: StatusTone.danger,
        dense: true,
        onGame: true,
      );
    }

    return null;
  }
}

/// Um lado do placar: nome em cima, barra no meio, número embaixo.
class _Side extends StatelessWidget {
  const _Side({
    required this.title,
    required this.bar,
    required this.value,
    required this.semanticsLabel,
    this.badge,
    this.onTap,
    this.mirrored = false,
  });

  final Widget title;
  final Widget bar;
  final Widget value;
  final String semanticsLabel;
  final Widget? badge;
  final VoidCallback? onTap;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    final align = mirrored ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: [
              // `Wrap`, e não `Row`: o selo mais longo ("Enfurecido:
              // +R$ 1.234,56 atrasado") não cabe na mesma linha do nome num
              // celular. Com `Row` ele saía cortado em "Enfureci…", que não
              // informa nada; aqui ele desce e continua legível.
              Wrap(
                spacing: AppSpacing.xxs,
                runSpacing: AppSpacing.xxs,
                alignment: mirrored ? WrapAlignment.end : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [title, ?badge],
              ),
              AppSpacing.gapXxs,
              bar,
              AppSpacing.gapXxs,
              value,
            ],
          ),
        ),
      ),
    );
  }
}

/// "R$ 3.980 / R$ 5.200" — o saldo de agora sobre o de domingo.
///
/// Os dois números juntos, e não só o de agora, porque é a RAZÃO entre eles
/// que a barra desenha: sem o segundo, uma barra pela metade não diz se a
/// semana começou com cinco mil ou com quinhentos.
class _HeroValue extends StatelessWidget {
  const _HeroValue({required this.state, required this.compact});

  final ArenaState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    final style =
        (compact ? theme.textTheme.labelMedium : theme.textTheme.titleSmall)
            ?.copyWith(
              color: palette.onGame,
              // Tabular: sem isso o número muda de LARGURA enquanto rola, e a
              // barra inteira treme junto.
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDouble.currency(
            state.currentBalance,
            duration: AppDurations.respectingMotion(
              context,
              AppDurations.celebrate,
            ),
            curve: AppDurations.curve,
            style: style,
          ),
          Text(
            ' / ${state.initialBalance.asCurrency(locale: context.locale)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: palette.onGame2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// "falta R$ 1.380" — o que ainda mantém o bicho em pé.
class _MonsterValue extends StatelessWidget {
  const _MonsterValue({required this.state, required this.compact});

  final ArenaState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    final l10n = context.l10n;

    final style =
        (compact ? theme.textTheme.labelMedium : theme.textTheme.titleSmall)
            ?.copyWith(
              color: palette.onGame,
              fontFeatures: const [FontFeature.tabularFigures()],
            );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.arenaRemainingPrefix} ',
            style: theme.textTheme.labelSmall?.copyWith(color: palette.onGame2),
          ),
          AnimatedDouble.currency(
            state.monsterHp,
            duration: AppDurations.respectingMotion(
              context,
              AppDurations.celebrate,
            ),
            curve: AppDurations.curve,
            style: style,
          ),
        ],
      ),
    );
  }
}
