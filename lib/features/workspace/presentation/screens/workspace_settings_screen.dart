import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/firestore/offline_write.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_card.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/core/presentation/display_names.dart';
import 'package:funances/core/widgets/section_header.dart';
import 'package:funances/features/workspace/presentation/widgets/appearance_section.dart';

class WorkspaceSettingsScreen extends ConsumerWidget {
  const WorkspaceSettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(AuthDomainProviders.service).signOut();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    }
  }

  Future<void> _editWorkspaceName(
    BuildContext context,
    WidgetRef ref,
    WorkspaceModel workspace,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController(text: workspace.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workspaceSettingsEditName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.onboardingWorkspaceNameLabel,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.saveButton),
          ),
        ],
      ),
    );

    final trimmed = newName?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == workspace.name) return;

    try {
      final WriteOutcome outcome = await ref
          .read(WorkspaceDomainProviders.repository)
          .updateWorkspace(workspace.copyWith(name: trimmed));
      // O watch em tempo real do workspace atualiza a UI automaticamente.

      // O nome novo já aparece pelo cache local; o que ainda não aconteceu é
      // os outros membros o verem.
      if (outcome == WriteOutcome.pending) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.savePendingSync)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorUnknown)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref
        .watch(WorkspaceViewProviders.workspace)
        .currentWorkspace;
    final isTab = Navigator.of(context).canPop() == false;
    final theme = Theme.of(context);

    // O recorte do topo — notch, ilha, barra de status.
    //
    // Como ABA, esta tela é o corpo direto do `TabBarView` da Home: não há
    // `AppBar` própria para empurrar o conteúdo para baixo, e num desktop com
    // rail (ou num celular cuja casca perca a barra) o primeiro cabeçalho de
    // seção nascia debaixo do relógio do sistema. Vai como PADDING da lista e
    // não como `SafeArea`: assim o conteúdo passa por baixo do recorte ao
    // rolar, em vez de bater numa parede invisível.
    //
    // Quando existe `AppBar` — a tela aberta por rota — o `Scaffold` já
    // consumiu esse recanto e `paddingOf` devolve zero. Os dois casos saem
    // certos sem um `if`.
    final topInset = MediaQuery.paddingOf(context).top;

    final body = workspace == null
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final layout = constraints.layout;
              if (!layout.isCompact) {
                final crossAxisCount = layout.columns;
                final itemWidth = constraints.maxWidth / crossAxisCount;
                // Ajusta o aspect ratio para manter uma altura máxima razoável
                final childAspectRatio = itemWidth / 160;

                return ListView(
                  padding: EdgeInsets.only(
                    top: topInset,
                    bottom: AppSpacing.bottomBarSafeArea,
                  ),
                  children: [
                    // Aparência e som no TOPO, aqui também: são as duas
                    // configurações que se trocam por gosto, e a grade de
                    // cartões abaixo é trabalho.
                    const AppearanceSection(),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      padding: AppSpacing.allMd,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: childAspectRatio > 1.5
                          ? childAspectRatio
                          : 1.5,
                      children: [
                        _buildGridItem(
                          context,
                          icon: Icons.edit_outlined,
                          title: l10n.workspaceSettingsEditName,
                          description: l10n.workspaceSettingsEditNameDesc,
                          subtitle: displayOr(
                            workspace.name,
                            l10n.unnamedWorkspace,
                          ),
                          onTap: () =>
                              _editWorkspaceName(context, ref, workspace),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.category_outlined,
                          title: l10n.workspaceSettingsCategories,
                          description: l10n.workspaceSettingsCategoriesDesc,
                          onTap: () {
                            context.push('/workspace/categories');
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          title: l10n.workspaceSettingsAccounts,
                          description: l10n.workspaceSettingsAccountsDesc,
                          onTap: () {
                            context.push('/workspace/accounts');
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.people_outline,
                          title: l10n.workspaceSettingsMembers,
                          description: l10n.workspaceSettingsMembersDesc,
                          onTap: () {
                            context.push('/workspace/members');
                          },
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.logout,
                          title: l10n.workspaceSettingsLogout,
                          description: l10n.workspaceSettingsLogoutDesc,
                          iconColor: AppColors.danger,
                          titleColor: AppColors.danger,
                          onTap: () => _signOut(context, ref),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.only(
                  top: topInset,
                  bottom: isTab ? AppSpacing.bottomBarSafeArea : 0,
                ),
                children: [
                  const AppearanceSection(),
                  const Divider(),
                  SectionHeader.label(l10n.profileTitle),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.profileEditTitle),
                    onTap: () {
                      context.push('/profile');
                    },
                  ),
                  const Divider(),
                  SectionHeader.label(l10n.workspaceSettingsGeneralSection),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.workspaceSettingsEditName),
                    subtitle: Text(
                      displayOr(workspace.name, l10n.unnamedWorkspace),
                    ),
                    onTap: () => _editWorkspaceName(context, ref, workspace),
                  ),
                  const Divider(),
                  SectionHeader.label(l10n.workspaceSettingsDataSection),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(l10n.workspaceSettingsCategories),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/workspace/categories');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(l10n.workspaceSettingsAccounts),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/workspace/accounts');
                    },
                  ),
                  const Divider(),
                  SectionHeader.label(l10n.workspaceSettingsTeamSection),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: Text(l10n.workspaceSettingsMembers),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/workspace/members');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: Text(
                      l10n.workspaceSettingsLogout,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              );
            },
          );

    if (isTab) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.workspaceSettingsTitle)),
      body: body,
    );
  }

  Widget _buildGridItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? theme.colorScheme.primary),
              AppSpacing.gapSm,
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          Text(
            description,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const Spacer(),
            Text(
              subtitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
