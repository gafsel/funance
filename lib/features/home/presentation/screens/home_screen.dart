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
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;
    // final workspaceState = ref.watch(workspaceNotifierProvider);
    final authUser = ref.watch(authStateProvider).value;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Center(
            child: authUser?.photoUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(authUser!.photoUrl!),
                  )
                : const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 20),
                  ),
          ),
        ),
        title: _buildWorkspaceSelector(context, ref),
        centerTitle: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OverviewTab(),
          JourneyTab(),
          HistoryTab(),
          WorkspaceSettingsScreen(),
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
      onTap: () => _showWorkspacePicker(context, ref, workspaceState),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            currentWorkspace?.type == WorkspaceType.business ? Icons.business : Icons.home_outlined,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              currentWorkspace?.name ?? l10n.homeNoWorkspaceSelected,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  void _showWorkspacePicker(BuildContext context, WidgetRef ref, dynamic workspaceState) {
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
                  'Workspaces',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: workspaceState.availableWorkspaces.length,
                  itemBuilder: (context, index) {
                    final workspace = workspaceState.availableWorkspaces[index];
                    final isSelected = workspace.id == workspaceState.currentWorkspace?.id;
                    return ListTile(
                      leading: Icon(
                        workspace.type == WorkspaceType.business ? Icons.business : Icons.home_outlined,
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
            ],
          ),
        );
      },
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
              icon: const Icon(Icons.bar_chart_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(0),
            ),
            IconButton(
              icon: const Icon(Icons.rocket_launch_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(1),
            ),
            const SizedBox(width: 48), // Espaço para o FAB
            IconButton(
              icon: const Icon(Icons.history_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(2),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppColors.pureWhite),
              onPressed: () => _tabController.animateTo(3),
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
