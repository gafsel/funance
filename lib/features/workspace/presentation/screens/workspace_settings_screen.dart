import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';

class WorkspaceSettingsScreen extends ConsumerWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref
        .watch(WorkspaceViewProviders.workspace)
        .currentWorkspace;
    final isTab = Navigator.of(context).canPop() == false;

    final body = workspace == null
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                final itemWidth = constraints.maxWidth / crossAxisCount;
                // Ajusta o aspect ratio para manter uma altura máxima razoável
                final childAspectRatio = itemWidth / 160;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: childAspectRatio > 1.5
                      ? childAspectRatio
                      : 1.5,
                  children: [
                    _buildGridItem(
                      context,
                      icon: Icons.edit_outlined,
                      title: l10n.workspaceSettingsEditName,
                      description: l10n.workspaceSettingsEditNameDesc,
                      subtitle: workspace.name,
                      onTap: () {
                        // TODO: Implementar edição de nome do workspace
                      },
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
                        // TODO: Implementar gestão de membros
                      },
                    ),
                    _buildGridItem(
                      context,
                      icon: Icons.logout,
                      title: l10n.workspaceSettingsLogout,
                      description: l10n.workspaceSettingsLogoutDesc,
                      iconColor: Colors.red,
                      titleColor: Colors.red,
                      onTap: () {
                        ref.read(AuthDomainProviders.service).signOut();
                      },
                    ),
                  ],
                );
              }

              return ListView(
                padding: EdgeInsets.only(bottom: isTab ? 120 : 0),
                children: [
                  _buildSectionHeader(
                    context,
                    l10n.workspaceSettingsGeneralSection,
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.workspaceSettingsEditName),
                    subtitle: Text(workspace.name),
                    onTap: () {
                      // TODO: Implementar edição de nome do workspace
                    },
                  ),
                  const Divider(),
                  _buildSectionHeader(
                    context,
                    l10n.workspaceSettingsDataSection,
                  ),
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
                  _buildSectionHeader(
                    context,
                    l10n.workspaceSettingsTeamSection,
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: Text(l10n.workspaceSettingsMembers),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Implementar gestão de membros
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      l10n.workspaceSettingsLogout,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      ref.read(AuthDomainProviders.service).signOut();
                    },
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
