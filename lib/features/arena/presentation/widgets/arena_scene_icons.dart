import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/presentation/widgets/arena_missions_sheet.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/home/domain/models/financial_health_model.dart';
import 'package:funances/features/home/domain/models/weekly_mission_model.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/coaching_insight_card.dart';
import 'package:funances/features/home/presentation/widgets/compass/compass_labels.dart';
import 'package:funances/features/home/presentation/widgets/compass/freedom_compass_sheet.dart';
import 'package:go_router/go_router.dart';

/// Os ícones de jogo na lateral da cena — decisão 7 do dono.
///
/// "como a primeira tela será apenas a imagem do jogo, precisamos que as
/// missões semanais e pessoais, a bússola e o coach sejam apresentados de uma
/// forma integrada → talvez em forma de ícones também, mas não necessariamente
/// na parte inferior".
///
/// Cada bloco que a Home tinha em cartão virou UM ícone com o número que o
/// cartão levava uma linha inteira para dizer:
///
/// - **pergaminho**, com "1/3": as missões da semana. Abre a mesma folha que
///   o bloco mostrava, com as mesmas ações;
/// - **bússola**, com a pontuação: abre a Bússola da Liberdade completa;
/// - **coach**: abre a última análise, ou pede uma nova — exatamente o que a
///   linha compacta do coaching fazia;
/// - **faísca**, com N em vermelho: os lançamentos identificados esperando
///   triagem. É o "sinal discreto na cena" da decisão 8 — a porta principal
///   deles agora é o FAB, e aqui fica só o aviso de que existem.
///
/// **Por que a lateral ESQUERDA e não o topo.** O topo já é do placar, que é
/// a leitura mais importante da tela; empurrar os ícones para lá espremeria as
/// duas barras que se opõem, que são o assunto. O pé é do HUD mensal. Sobram
/// as laterais — e entre as duas, a esquerda: o monstro fica em ~72% da
/// largura da cena e os heróis em ~30%, então a faixa de 44px na borda
/// esquerda é a única coluna que não passa por cima de ninguém.
///
/// **Por que uma coluna de círculos e não uma barra.** A 400px uma barra
/// horizontal de quatro rótulos ou corta as palavras ou come 60px de altura
/// da cena. Quatro círculos de 40px empilhados custam 44px de LARGURA, que a
/// cena tem de sobra na borda, e cada um carrega o seu número sem precisar de
/// legenda — que é como um jogo mostra recurso.
class ArenaSceneIcons extends ConsumerWidget {
  const ArenaSceneIcons({super.key, this.compact = false});

  /// Celular: círculo e badge menores.
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // As missões abrem a folha mesmo quando não há nenhuma: o ícone é
          // a porta da semana, e uma porta que some quando o servidor ainda
          // não gerou as missões deixa o usuário sem explicação nenhuma.
          ArenaSceneIcon(
            icon: Icons.menu_book_rounded,
            compact: compact,
            label: l10n.weeklyMissionsTitle,
            semanticsValue: l10n.weeklyMissionsProgress(
              '$done',
              '${missions.length}',
            ),
            badge: missions.isEmpty ? null : '$done/${missions.length}',
            onTap: () => ArenaMissionsSheet.show(context),
          ),
          ArenaSceneIcon(
            icon: Icons.explore_rounded,
            compact: compact,
            label: l10n.compassTitle,
            semanticsValue: health == null
                ? compassTierLabel(l10n, FreedomTier.unknown)
                : l10n.compassScoreOf(
                    '${health.score.round()}',
                    compassTierLabel(l10n, health.tier),
                  ),
            // A patente e a pontuação, nesta ordem de prioridade: o número
            // cabe no badge, a palavra não. Sem índice publicado o ícone
            // continua na cena, apagado — some o toque, não a explicação.
            badge: health == null ? null : '${health.score.round()}',
            onTap: health == null
                ? null
                : () => FreedomCompassSheet.show(context, health),
          ),
          ArenaSceneIcon(
            icon: Icons.psychology_rounded,
            compact: compact,
            label: l10n.coachingTitle,
            semanticsValue: freshCoaching
                ? l10n.coachingViewLast
                : l10n.coachingConsultAction,
            // Um ponto, e não um número: o coach não tem contagem. Ele diz
            // só "há algo novo para ler".
            badgeDot: freshCoaching,
            onTap: () =>
                CoachingInsightCard.openCoach(context, ref, insight),
          ),
          if (pending > 0)
            ArenaSceneIcon(
              icon: Icons.auto_awesome,
              compact: compact,
              urgent: true,
              label: l10n.automaticTransactionTitle,
              semanticsValue: l10n.automaticTransactionPendingCount(pending),
              badge: '$pending',
              onTap: () => context.push('/automatic-transactions'),
            ),
        ],
      ),
    );
  }
}

/// Um ícone da lateral: círculo escuro, moldura clara e um badge opcional.
///
/// A tinta é a do JOGO — `gameTrough` e `gameFrame` —, a mesma dos ícones do
/// rodapé mensal: os dois grupos moram sobre a mesma cena e precisam parecer
/// do mesmo conjunto, senão a tela vira dois HUDs sobrepostos.
///
/// O alvo de toque é de [minTarget] em qualquer tamanho, ainda que o círculo
/// desenhado encolha no celular: é o mínimo de acessibilidade, e ele não pode
/// depender do quanto a arte pediu.
class ArenaSceneIcon extends StatelessWidget {
  const ArenaSceneIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticsValue,
    required this.onTap,
    this.badge,
    this.badgeDot = false,
    this.urgent = false,
    this.compact = false,
  });

  /// Mínimo de alvo de toque, em pixels lógicos.
  static const double minTarget = 44;

  final IconData icon;

  /// O nome, para o leitor de tela e para o tooltip.
  final String label;

  /// O que o badge diz por extenso — "1 de 3 completadas", "72 de 100 •
  /// Guardião". É o que o badge NÃO consegue caber.
  final String semanticsValue;

  /// `null` desliga o ícone: ele continua na cena, apagado e sem toque.
  final VoidCallback? onTap;

  /// O número do canto. `null` quando não há o que contar.
  final String? badge;

  /// Um ponto no lugar do número, para o que não se conta.
  final bool badgeDot;

  /// Vermelho em vez de dourado: é pendência, não recompensa.
  final bool urgent;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final side = compact ? 36.0 : 40.0;
    final ink = enabled ? AppColors.inkInverse : AppColors.inkInverse2;

    final circle = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gameTrough.withValues(alpha: enabled ? 0.85 : 0.6),
        border: Border.all(
          color: AppColors.gameFrame.withValues(alpha: enabled ? 0.55 : 0.3),
        ),
      ),
      child: Icon(icon, size: side * 0.5, color: ink),
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: label,
      value: semanticsValue,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: minTarget,
              height: minTarget,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  circle,
                  if (badge != null || badgeDot)
                    Positioned(
                      right: 0,
                      bottom: compact ? 2 : 0,
                      child: _Badge(
                        text: badge,
                        urgent: urgent,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O número do canto do ícone.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.urgent, required this.style});

  /// `null` desenha o ponto.
  final String? text;
  final bool urgent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final background = urgent ? AppColors.danger : AppColors.gold;
    final ink = urgent ? AppColors.inkInverse : AppColors.goldInk;

    if (text == null) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background,
          border: Border.all(color: AppColors.gameTrough),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.gameTrough),
      ),
      child: Text(
        text!,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: style?.copyWith(color: ink, fontSize: 10, height: 1.4),
      ),
    );
  }
}
