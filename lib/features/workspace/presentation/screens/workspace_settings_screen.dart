import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../presentation/providers/workspace_providers.dart';
import 'category_management_screen.dart';
import '../../../finance/presentation/screens/account_management_screen.dart';

class WorkspaceSettingsScreen extends ConsumerWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workspaceSettingsTitle),
      ),
      body: workspace == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader(context, l10n.workspaceSettingsGeneralSection),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.workspaceSettingsEditName),
                  subtitle: Text(workspace.name),
                  onTap: () {
                    // TODO: Implementar edição de nome do workspace
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, l10n.workspaceSettingsDataSection),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: Text(l10n.workspaceSettingsCategories),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoryManagementScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.workspaceSettingsAccounts),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountManagementScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSectionHeader(context, l10n.workspaceSettingsTeamSection),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: Text(l10n.workspaceSettingsMembers),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implementar gestão de membros
                  },
                ),
              ],
            ),
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
}
