import 'package:flutter/material.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/core/widgets/app_chip.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';

/// O selo "Pessoal" / "Empresa" ao lado do nome do cofre.
///
/// O tipo do workspace virou regra de produto — ele decide missões, badges,
/// coaching e vocabulário — e mesmo assim só aparecia na interface como a
/// diferença entre dois ícones (`Icons.home_outlined` e `Icons.business`) no
/// seletor. Quem tem dois cofres precisa saber em qual está sem decifrar um
/// pictograma de 20px.
///
/// É discreto de propósito: muda os textos, não a identidade.
class WorkspaceTypeBadge extends StatelessWidget {
  const WorkspaceTypeBadge({super.key, required this.type, this.onGame = false});

  final WorkspaceType type;

  /// `true` quando o selo está sobre uma superfície de jogo.
  final bool onGame;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StatusPill(
      dense: true,
      tone: onGame ? StatusTone.reward : StatusTone.info,
      icon: switch (type) {
        WorkspaceType.personal => Icons.home_outlined,
        WorkspaceType.business => Icons.business_outlined,
      },
      label: switch (type) {
        WorkspaceType.personal => l10n.workspaceTypePersonalBadge,
        WorkspaceType.business => l10n.workspaceTypeBusinessBadge,
      },
    );
  }
}
