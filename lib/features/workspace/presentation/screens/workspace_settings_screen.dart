import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/l10n/app_localizations.dart';
import '../../presentation/providers/workspace_providers.dart';
import 'category_management_screen.dart';
import '../../../finance/presentation/screens/account_management_screen.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class WorkspaceSettingsScreen extends ConsumerWidget {
  const WorkspaceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final workspace = ref.watch(workspaceNotifierProvider).currentWorkspace;
    final isTab = Navigator.of(context).canPop() == false;

    final body = workspace == null
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: EdgeInsets.only(bottom: isTab ? 120 : 0),
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
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair', style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                },
              ),
            ],
          );

    if (isTab) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workspaceSettingsTitle),
      ),
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
}
