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
  const WorkspaceTypeBadge({
    super.key,
    required this.type,
    this.onGame = false,
    this.iconOnly = false,
  });

  final WorkspaceType type;

  /// `true` quando o selo está sobre uma superfície de jogo.
  final bool onGame;

  /// Só a figura, com a palavra no tooltip e na semântica.
  ///
  /// O dono, olhando a AppBar: *"o título do workspace ficou pressionado por
  /// causa do tipo do workspace… o nome do workspace é mais importante que o
  /// tipo pro usuário"*. E ele está certo sobre a hierarquia: o tipo é uma
  /// resposta de UMA vez ("em qual cofre eu estou?"), e o nome é o que se lê
  /// toda vez. Onde o espaço é disputado, o tipo cede a palavra e fica a
  /// figura — que é a mesma dos dois lugares onde ele já aparecia sozinho:
  /// o menu de troca de cofre e o rail colapsado.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StatusPill(
      dense: true,
      iconOnly: iconOnly,
      // O tom NÃO muda com a superfície. Antes o selo virava dourado sobre
      // fundo escuro, e dourado neste app quer dizer recompensa: o tipo do
      // cofre não é conquista nenhuma. Quem muda é a tinta do texto, que é o
      // que precisava de contraste.
      onGame: onGame,
      tone: StatusTone.info,
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
