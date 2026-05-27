import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/auth/presentation/providers/auth_providers.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/providers/workspace_providers.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/home/presentation/widgets/history_tab.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // final theme = Theme.of(context);
    final workspaceState = ref.watch(workspaceNotifierProvider);
    // final currentWorkspace = workspaceState.currentWorkspace;
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: _buildWorkspaceSelector(context, ref),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkspaceSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.successGold,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.pureWhite.withValues(alpha: 0.6),
          tabs: [
            Tab(text: l10n.homeJourneyTab, icon: const Icon(Icons.rocket_launch_outlined)),
            Tab(text: l10n.homeOverviewTab, icon: const Icon(Icons.bar_chart_outlined)),
            Tab(text: l10n.homeHistoryTab, icon: const Icon(Icons.history_outlined)),
          ],
        ),
      ),
      drawer: _buildDrawer(context, ref, authUser, workspaceState),
      body: TabBarView(
        controller: _tabController,
        children: const [
          JourneyTab(),
          OverviewTab(),
          HistoryTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildWorkspaceSelector(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceNotifierProvider);
    final currentWorkspace = workspaceState.currentWorkspace;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            currentWorkspace?.type == WorkspaceType.business ? Icons.business : Icons.home_outlined,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            currentWorkspace?.name ?? l10n.homeNoWorkspaceSelected,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, dynamic authUser, dynamic workspaceState) {
    // final l10n = AppLocalizations.of(context)!;
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: authUser?.photoUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(authUser!.photoUrl!))
                : const CircleAvatar(child: Icon(Icons.person)),
            accountName: Text(authUser?.displayName ?? 'Usuário'),
            accountEmail: Text(authUser?.email ?? ''),
            decoration: const BoxDecoration(
              color: AppColors.deepTurquoise,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workspaces',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    // TODO: Iniciar fluxo de criação de novo workspace
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: workspaceState.availableWorkspaces.length,
              itemBuilder: (context, index) {
                final workspace = workspaceState.availableWorkspaces[index];
                final isSelected = workspace.id == workspaceState.currentWorkspace?.id;
                return ListTile(
                  leading: Icon(
                    workspace.type == 'business' ? Icons.business : Icons.home_outlined,
                    color: isSelected ? AppColors.vibrantTeal : null,
                  ),
                  title: Text(
                    workspace.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected ? AppColors.vibrantTeal : null,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    ref.read(workspaceNotifierProvider.notifier).setCurrentWorkspace(workspace);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.coralOrange),
            title: const Text('Sair', style: TextStyle(color: AppColors.coralOrange)),
            onTap: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: AppColors.deepTurquoise,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.rocket_launch_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(0),
            ),
            const SizedBox(width: 48), // Espaço para o FAB
            IconButton(
              icon: const Icon(Icons.history_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.goldGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.successGold.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.pureWhite, width: 2),
      ),
      child: FloatingActionButton(
        onPressed: () => _showActionMenu(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: AppColors.deepTurquoise, size: 32),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TransactionActionSheet(
          onSelect: (type) {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TransactionFormScreen(initialType: type),
              ),
            );
          },
        );
      },
    );
  }
}
