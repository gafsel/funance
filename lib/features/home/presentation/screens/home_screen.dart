import 'package:flutter/material.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';
import 'package:funances/features/home/presentation/widgets/history_tab.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_level_indicator.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:confetti/confetti.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isNavigationRailExtended = false;
  late ConfettiController _confettiController;
  int? _xpGain;
  int _xpGainSeq = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final workspaceState = ref.watch(workspaceNotifierProvider);
    final authUser = ref.watch(AuthDomainProviders.currentUser);

    // Reage às atualizações em tempo real do workspace (XP, badges, nível
    // concedidos pelo servidor) com celebrações imediatas.
    ref.listen(WorkspaceViewProviders.gamification, (previous, next) {
      final prevWorkspace = previous;
      final currWorkspace = next;

      if (prevWorkspace == null) return;
      if (prevWorkspace.workspaceId == null || currWorkspace.workspaceId == null) {
        return;
      }
      if (prevWorkspace.workspaceId != currWorkspace.workspaceId) return;

      final leveledUp = currWorkspace.level > prevWorkspace.level;
      final xpDelta = currWorkspace.xp - prevWorkspace.xp;

      if (leveledUp) {
        HapticFeedback.heavyImpact();
        _confettiController.play();
        _showLevelUpDialog(context, currWorkspace.level);
      } else if (xpDelta > 0) {
        HapticFeedback.mediumImpact();
        setState(() {
          _xpGain = xpDelta;
          _xpGainSeq++;
        });
      }

      final newBadges = currWorkspace.unlockedBadges.keys
          .toSet()
          .difference(prevWorkspace.unlockedBadges.keys.toSet());
      if (newBadges.isNotEmpty) {
        HapticFeedback.heavyImpact();
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.badgeUnlockedToast)),
              ],
            ),
            action: SnackBarAction(
              label: l10n.badgeUnlockedView,
              onPressed: () => context.push('/workspace/badges'),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return Scaffold(
          extendBody: true,
          appBar: isLargeScreen
              ? null
              : AppBar(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: () => context.push('/profile'),
                      child: Center(
                        child: UserAvatar(
                          displayName: authUser?.displayName,
                          photoUrl: authUser?.photoUrl,
                          radius: 16,
                        ),
                      ),
                    ),
                  ),
                  title: _buildWorkspaceSelector(
                    context,
                    ref,
                    isNavigationRail: false,
                  ),
                  centerTitle: true,
                  actions: const [
                    WorkspaceLevelIndicator(),
                  ],
                ),
          body: Stack(
            children: [
              Row(
                children: [
                  if (isLargeScreen) _buildNavigationRail(context, authUser),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: isLargeScreen
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      children: const [
                        JourneyTab(),
                        OverviewTab(),
                        HistoryTab(),
                        WorkspaceSettingsScreen(),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 30,
                  maxBlastForce: 40,
                  minBlastForce: 10,
                  emissionFrequency: 0.05,
                  colors: const [
                    AppColors.vibrantTeal,
                    AppColors.successGold,
                    AppColors.limeGreen,
                    AppColors.deepTurquoise,
                    Colors.pink,
                    Colors.purple,
                  ],
                ),
              ),
              if (_xpGain != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _XpGainToast(
                      key: ValueKey(_xpGainSeq),
                      amount: _xpGain!,
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: isLargeScreen ? null : _buildBottomBar(context),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const TransactionActionSheet(),
              );
            },
            backgroundColor: AppColors.successGold,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: AppColors.darkNavy),
          ),
          floatingActionButtonLocation: isLargeScreen
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  Widget _buildNavigationRail(BuildContext context, UserModel? authUser) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      extended: _isNavigationRailExtended,
      minExtendedWidth: 200,
      backgroundColor: AppColors.deepTurquoise,
      unselectedIconTheme: const IconThemeData(
        color: AppColors.pureWhite,
        opacity: 0.7,
      ),
      selectedIconTheme: const IconThemeData(color: AppColors.pureWhite),
      unselectedLabelTextStyle: const TextStyle(color: AppColors.pureWhite),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.pureWhite,
        fontWeight: FontWeight.bold,
      ),
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
              child: _buildWorkspaceSelector(
                context,
                ref,
                isNavigationRail: true,
              ),
            )
          else
            InkWell(
              onTap: () => _showWorkspacePicker(
                context,
                ref,
                ref.read(WorkspaceViewProviders.workspace),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.pureWhite,
              ),
            ),
          const SizedBox(height: 24),
          const WorkspaceLevelIndicator(),
          const SizedBox(height: 16),
        ],
      ),
      trailing: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => context.push('/profile'),
              child: UserAvatar(
                displayName: authUser?.displayName,
                photoUrl: authUser?.photoUrl,
                radius: 16,
              ),
            ),
            if (_isNavigationRailExtended) ...[
              const SizedBox(height: 8),
              Text(
                authUser?.displayName ?? '',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 12,
                ),
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
          icon: const Icon(Icons.rocket_launch_outlined),
          label: Text(l10n.homeJourneyTab),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.bar_chart_outlined),
          label: Text(l10n.homeOverviewTab),
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

  Widget _buildWorkspaceSelector(
    BuildContext context,
    WidgetRef ref, {
    required bool isNavigationRail,
  }) {
    final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
    final currentWorkspace = workspaceState.currentWorkspace;
    final l10n = AppLocalizations.of(context)!;
    final color = isNavigationRail ? AppColors.pureWhite : null;

    return InkWell(
      onTap: () => _showWorkspacePicker(context, ref, workspaceState),
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
              currentWorkspace?.name ?? l10n.homeNoWorkspaceSelected,
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

  void _showWorkspacePicker(
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
                          workspace.name,
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

  Widget _buildBottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: AppColors.deepTurquoise,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomBarItem(
              index: 0,
              icon: Icons.rocket_launch_outlined,
              selectedIcon: Icons.rocket_launch,
              label: l10n.homeJourneyTab,
            ),
            _buildBottomBarItem(
              index: 1,
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: l10n.homeOverviewTab,
            ),
            const SizedBox(width: 48), // Espaço para o FAB
            _buildBottomBarItem(
              index: 2,
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: l10n.homeHistoryTab,
            ),
            _buildBottomBarItem(
              index: 3,
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.homeSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    final color = isSelected
        ? AppColors.successGold
        : AppColors.pureWhite.withValues(alpha: 0.8);
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _tabController.animateTo(index),
          child: Semantics(
            label: label,
            selected: isSelected,
            button: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLevelUpDialog(BuildContext context, int newLevel) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      // Barreira mais leve para o confetti atrás do diálogo continuar visível.
      barrierColor: Colors.black26,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              l10n.levelUpTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.levelUpSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.levelUpContent(newLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.levelUpMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.closeButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/workspace/badges');
            },
            child: Text(
              l10n.viewAchievementsButton,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip animado de "+N XP" que sobe e desaparece — feedback imediato quando o
/// servidor concede XP ao workspace.
class _XpGainToast extends StatelessWidget {
  final int amount;

  const _XpGainToast({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      builder: (context, t, child) {
        // Entra rápido, sobe devagar e some no fim.
        final opacity = t < 0.15 ? t / 0.15 : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 24 - 24 * t), child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.deepTurquoise,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, color: AppColors.successGold, size: 20),
              const SizedBox(width: 6),
              Text(
                '+$amount XP',
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
