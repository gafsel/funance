import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_gradients.dart';
import 'package:funances/features/auth/presentation/providers/auth_providers.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';
import 'package:funances/features/home/presentation/widgets/history_tab.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isNavigationRailExtended = false;

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
    // final workspaceState = ref.watch(workspaceNotifierProvider);
    final authUser = ref.watch(authStateProvider).value;

    return LayoutBuilder(builder: (context, constraints) {
      final isLargeScreen = constraints.maxWidth > 800;

      return Scaffold(
        extendBody: true,
        appBar: isLargeScreen
            ? null
            : AppBar(
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
        body: Row(
          children: [
            if (isLargeScreen)
              _buildNavigationRail(context, authUser),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: isLargeScreen ? const NeverScrollableScrollPhysics() : null,
                children: const [
                  OverviewTab(),
                  JourneyTab(),
                  HistoryTab(),
                  WorkspaceSettingsScreen(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isLargeScreen ? null : _buildBottomBar(context),
        floatingActionButton: _buildFab(context),
        floatingActionButtonLocation: isLargeScreen
            ? FloatingActionButtonLocation.endFloat
            : FloatingActionButtonLocation.centerDocked,
      );
    });
  }

  Widget _buildNavigationRail(BuildContext context, dynamic authUser) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      extended: _isNavigationRailExtended,
      minExtendedWidth: 200,
      backgroundColor: AppColors.deepTurquoise,
      unselectedIconTheme: const IconThemeData(color: AppColors.pureWhite, opacity: 0.7),
      selectedIconTheme: const IconThemeData(color: AppColors.pureWhite),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.pureWhite),
      selectedLabelTextStyle: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
      leading: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(
              _isNavigationRailExtended ? Icons.menu_open : Icons.menu,
              color: AppColors.pureWhite,
            ),
            onPressed: () {
              setState(() {
                _isNavigationRailExtended = !_isNavigationRailExtended;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_isNavigationRailExtended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildWorkspaceSelector(context, ref),
            )
          else
            const Icon(Icons.account_balance_wallet, color: AppColors.pureWhite),
          const SizedBox(height: 24),
        ],
      ),
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (authUser?.photoUrl != null)
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(authUser!.photoUrl!),
              )
            else
              const CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 20),
              ),
            if (_isNavigationRailExtended) ...[
              const SizedBox(height: 8),
              Text(
                authUser?.displayName ?? '',
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      selectedIndex: _tabController.index,
      onDestinationSelected: (index) {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          label: Text(l10n.homeOverviewTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.rocket_launch_outlined),
          label: Text(l10n.homeJourneyTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.history_outlined),
          label: Text(l10n.homeHistoryTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.homeSettings),
        ),
      ],
    );
  }

  Widget _buildWorkspaceSelector(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
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
                  'Workspaces',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...workspaceState.availableWorkspaces.map((workspace) {
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
                          ref.read(WorkspaceViewProviders.workspace.notifier).setCurrentWorkspace(workspace);
                          Navigator.pop(context);
                        },
                      );
                    }),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: AppColors.vibrantTeal),
                      title: Text(
                        l10n.addWorkspaceButton,
                        style: const TextStyle(
                          color: AppColors.vibrantTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(WorkspaceViewProviders.workspace.notifier).reset();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                        );
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
                builder: (_) => TransactionFormScreen.creation(type: type),
              ),
            );
          },
        );
      },
    );
  }
}
