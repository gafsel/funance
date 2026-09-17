import 'package:flutter/material.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/home/home_bottom_bar_item.dart';
import 'package:funances/features/home/presentation/widgets/home/workspace_selector.dart';
import 'package:funances/features/home/presentation/widgets/home/xp_gain_toast.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/features/finance/presentation/widgets/transaction_action_sheet.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/history_tab.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});

    // Mantém o provider em dia com o gesto do usuário; sem isso, ir para a
    // Visão Geral pela barra e depois pelo cabeçalho da Jornada não faria
    // nada na segunda vez (o provider já estaria em 1).
    final selected = ref.read(HomeViewProviders.selectedTab);
    if (selected != _tabController.index) {
      ref.read(HomeViewProviders.selectedTab.notifier).state =
          _tabController.index;
    }
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

    // Uma aba pedindo outra (o cabeçalho da Jornada leva à Visão Geral).
    ref.listen(HomeViewProviders.selectedTab, (previous, next) {
      if (next != _tabController.index &&
          next >= 0 &&
          next < _tabController.length) {
        _tabController.animateTo(next);
      }
    });

    // Reage às atualizações em tempo real do workspace (XP, badges, nível
    // concedidos pelo servidor) com celebrações imediatas.
    ref.listen(WorkspaceViewProviders.gamification, (previous, next) {
      final prevWorkspace = previous;
      final currWorkspace = next;

      if (prevWorkspace == null) return;
      if (prevWorkspace.workspaceId == null ||
          currWorkspace.workspaceId == null) {
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

      final newBadges = currWorkspace.unlockedBadges.keys.toSet().difference(
        prevWorkspace.unlockedBadges.keys.toSet(),
      );
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
                  title: const WorkspaceSelector(isNavigationRail: false),
                  centerTitle: true,
                  actions: const [WorkspaceLevelIndicator()],
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
                    child: XpGainToast(
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
              child: const WorkspaceSelector(isNavigationRail: true),
            )
          else
            InkWell(
              onTap: () => showWorkspacePicker(
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
            HomeBottomBarItem(
              icon: Icons.rocket_launch_outlined,
              selectedIcon: Icons.rocket_launch,
              label: l10n.homeJourneyTab,
              isSelected: _tabController.index == 0,
              onTap: () => _tabController.animateTo(0),
            ),
            HomeBottomBarItem(
              icon: Icons.bar_chart_outlined,
              selectedIcon: Icons.bar_chart,
              label: l10n.homeOverviewTab,
              isSelected: _tabController.index == 1,
              onTap: () => _tabController.animateTo(1),
            ),
            const SizedBox(width: 48), // Espaço para o FAB
            HomeBottomBarItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: l10n.homeHistoryTab,
              isSelected: _tabController.index == 2,
              onTap: () => _tabController.animateTo(2),
            ),
            HomeBottomBarItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: l10n.homeSettings,
              isSelected: _tabController.index == 3,
              onTap: () => _tabController.animateTo(3),
            ),
          ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.levelUpContent(newLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.levelUpMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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
