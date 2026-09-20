import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_radius.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/arena/presentation/screens/arena_screen.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// O desafio da semana, no topo da Home.
///
/// Substitui os dois blocos que abriam a Jornada:
///
/// - o **cabeçalho "quanto sobra"**, cujo número virou a vida livre dos
///   heróis, dentro do detalhe das contas. Ele era um número grande e
///   parado; aqui o mesmo dinheiro tem um adversário, e a barra mostra o que
///   a semana fez com ele;
/// - a **faixa de "vence hoje e amanhã"**, que desceu para dentro do detalhe
///   do monstro como "próximo golpe". Na Home ela repetia, em texto, o que a
///   barra do monstro diz em um relance.
///
/// A altura da cena é uma FRAÇÃO da tela, não um número fixo: num celular a
/// luta precisa de corpo para ser luta (~40% da altura visível), e num
/// monitor a mesma fração viraria um mural. O teto de 220px é o que segura o
/// desktop.
class ArenaHomeBlock extends ConsumerWidget {
  const ArenaHomeBlock({super.key});

  /// Fração da altura da tela que a cena ocupa no celular.
  ///
  /// Encolheu de 0,34 para 0,30 quando a faixa do HUD mensal foi reservada no
  /// pé da cena (`arenaFooterSlotHeight`): o bloco inteiro tem um orçamento
  /// de altura, e ele não podia crescer por causa de um espaço que ainda está
  /// vazio.
  static const double compactSceneFraction = 0.30;

  /// Teto da cena no desktop.
  static const double wideSceneHeight = 190;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // `LayoutBuilder`, e não o `MediaQuery` da janela: no desktop a Home
    // divide a largura com o `NavigationRail`, e uma janela de 1040px entrega
    // ao bloco bem menos do que isso.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.layout.isCompact;
        final sceneHeight = compact
            ? (MediaQuery.sizeOf(context).height * compactSceneFraction).clamp(
                140.0,
                230.0,
              )
            : wideSceneHeight;

        return _block(context, l10n, compact, sceneHeight);
      },
    );
  }

  Widget _block(
    BuildContext context,
    AppLocalizations l10n,
    bool compact,
    double sceneHeight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: ColoredBox(
          color: AppColors.surfaceDeep,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.arenaWeekChallenge,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.inkInverse2),
                      ),
                    ),
                    // A porta para a tela cheia. Ela saiu da `AppBar` — o
                    // ícone de escudo ao lado do nível competia com o próprio
                    // bloco, que agora está logo abaixo.
                    IconButton(
                      key: const ValueKey('arena-open-full'),
                      tooltip: l10n.arenaTitle,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.open_in_full,
                        size: 18,
                        color: AppColors.inkInverse2,
                      ),
                      onPressed: () => context.push(arenaRoutePath),
                    ),
                  ],
                ),
              ),
              ArenaView(sceneHeight: sceneHeight, compact: compact),
            ],
          ),
        ),
      ),
    );
  }
}
