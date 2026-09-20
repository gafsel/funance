import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_palette.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_type_badge.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Qual workspace está aberto, e o atalho para trocar.
///
/// Aparece em dois lugares com a MESMA identidade: na AppBar do mobile e no
/// topo do `NavigationRail` estendido. Era um método da `HomeScreen` que
/// recebia `isNavigationRail` só para saber se pintava de branco.

class WorkspaceSelector extends ConsumerWidget {
  const WorkspaceSelector({super.key, required this.isNavigationRail});

  /// No rail estendido o seletor vive sobre o azul-petróleo, e o texto
  /// precisa ser branco; na AppBar ele herda o tema.
  final bool isNavigationRail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final currentWorkspace = workspaceState.currentWorkspace;
    final l10n = AppLocalizations.of(context)!;
    final color = isNavigationRail ? AppColors.inkInverse : null;

    return InkWell(
      onTap: () => showWorkspacePicker(context, ref, workspaceState),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              currentWorkspace == null
                  ? l10n.homeNoWorkspaceSelected
                  : displayOr(currentWorkspace.name, l10n.unnamedWorkspace),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // O tipo do cofre decide missão, badge, coaching e vocabulário, e
          // aparecia só como a diferença entre dois pictogramas de 20px. O
          // selo diz a palavra — e é aqui, ao lado do nome, que ele mora: o
          // corpo da Home tinha uma segunda cópia do mesmo cabeçalho.
          if (currentWorkspace != null) ...[
            AppSpacing.gapXs,
            WorkspaceTypeBadge(
              type: currentWorkspace.type,
              onGame: isNavigationRail,
            ),
          ],
          Icon(Icons.arrow_drop_down, color: color),
        ],
      ),
    );
  }
}

/// A folha de troca de workspace.
///
/// Fica fora do [WorkspaceSelector] porque o rail COLAPSADO também a abre —
/// ali não há espaço para o seletor inteiro, só para o ícone.
void showWorkspacePicker(
  BuildContext context,
  WidgetRef ref,
  WorkspaceState workspaceState,
) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: AppSpacing.allMd,
              child: Text(
                l10n.workspacePickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...workspaceState.availableWorkspaces.map((workspace) {
                    final isSelected =
                        workspace.id == workspaceState.currentWorkspace?.id;
                    return ListTile(
                      leading: Icon(
                        workspace.type == WorkspaceType.business
                            ? Icons.business
                            : Icons.home_outlined,
                        color: isSelected ? context.palette.tealText : null,
                      ),
                      title: Text(
                        displayOr(workspace.name, l10n.unnamedWorkspace),
                        style: isSelected
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: context.palette.tealText,
                              )
                            : null,
                      ),
                      selected: isSelected,
                      onTap: () {
                        ref
                            .read(WorkspaceViewProviders.workspace.notifier)
                            .setCurrentWorkspace(workspace);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.add_circle_outline,
                      color: context.palette.tealText,
                    ),
                    title: Text(
                      l10n.addWorkspaceButton,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.palette.tealText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/workspace/form');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
