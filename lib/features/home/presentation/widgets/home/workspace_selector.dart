import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
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
    final color = isNavigationRail ? AppColors.pureWhite : null;

    return InkWell(
      onTap: () => showWorkspacePicker(context, ref, workspaceState),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            currentWorkspace?.type == WorkspaceType.business
                ? Icons.business
                : Icons.home_outlined,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              currentWorkspace == null
                  ? l10n.homeNoWorkspaceSelected
                  : displayOr(currentWorkspace.name, l10n.unnamedWorkspace),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
              padding: const EdgeInsets.all(16.0),
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
                        color: isSelected ? AppColors.vibrantTeal : null,
                      ),
                      title: Text(
                        displayOr(workspace.name, l10n.unnamedWorkspace),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                          color: isSelected ? AppColors.vibrantTeal : null,
                        ),
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
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.vibrantTeal,
                    ),
                    title: Text(
                      l10n.addWorkspaceButton,
                      style: const TextStyle(
                        color: AppColors.vibrantTeal,
                        fontWeight: FontWeight.bold,
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
