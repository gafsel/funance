import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/arena/presentation/widgets/arena_view.dart';

/// A rota da Arena. Uma tela, um placar e a cena embaixo.
const String arenaRoutePath = '/arena';

/// A Arena em tela cheia.
///
/// O MESMO bloco que abre a Home, com a cena tomando o que sobra em vez de
/// uma altura fixa. Ela continua existindo depois de a Arena virar o topo da
/// Home porque é onde a cena cabe inteira: num celular, o bloco da Home
/// mostra a luta em ~40% da tela, e quem quiser olhar o bicho de perto
/// precisa de um lugar para isso.
class ArenaScreen extends ConsumerWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppScaffold(
      constrained: false,
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        // A barra da Arena é de JOGO: fundo profundo e tinta clara nos dois
        // temas. O `titleTextStyle` precisa vir junto — o `appBarTheme` do
        // app fixa a cor do título, e sozinho o `foregroundColor` deixava
        // "Arena" preto sobre azul-escuro no tema claro.
        title: Text(
          l10n.arenaTitle,
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(color: AppColors.inkInverse),
        ),
        backgroundColor: AppColors.surfaceDeep,
        foregroundColor: AppColors.inkInverse,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => ArenaView(
                sceneHeight: null,
                compact: constraints.layout.isCompact,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            child: Text(
              l10n.arenaHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.inkInverse2),
            ),
          ),
          AppSpacing.gapXs,
        ],
      ),
    );
  }
}
