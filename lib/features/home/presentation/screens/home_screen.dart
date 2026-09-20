import 'package:flutter/material.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/theme/app_breakpoints.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/theme/app_spacing.dart';
import 'package:funances/core/widgets/app_scaffold.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/home/presentation/widgets/home/home_bottom_bar_item.dart';
import 'package:funances/features/home/presentation/widgets/home/workspace_selector.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:funances/features/finance/presentation/widgets/launch_fab.dart';
import 'package:funances/features/home/presentation/provider.dart';
import 'package:funances/features/home/presentation/widgets/history_tab.dart';
import 'package:funances/features/home/presentation/widgets/journey_tab.dart';
import 'package:funances/features/home/presentation/widgets/overview_tab.dart';
import 'package:funances/features/user/presentation/widgets/user_avatar.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/workspace_level_badge.dart';
import 'package:funances/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isNavigationRailExtended = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _tabController.addListener(_onTabChanged);
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

    // O feedback de conquista NÃO mora mais aqui. Ele subiu para o
    // `CelebrationHost`, pendurado no `builder` do `MaterialApp`: enquanto
    // este `ref.listen` estava na Home, quem ganhava XP dentro da
    // Conciliação, do 50-30-20 ou do formulário de transação — telas que
    // empilham rota por cima — não via retorno nenhum, porque a Home não
    // estava montada. Ver `core/celebration/`.

    return LayoutBuilder(
      builder: (context, constraints) {
        // Um corte só. O rail abria em 800 e o conteúdo das abas em 900: na
        // faixa de 801 a 900px a Home já pagava a largura do rail e nenhuma
        // aba reorganizava. Agora rail e conteúdo leem o MESMO `AppLayout`.
        final isLargeScreen = constraints.layout.usesRail;

        // `AppScaffold` e não `Scaffold`: é ele que decide entre rail e barra
        // inferior pelo MESMO `AppLayout` que as abas leem, e que põe o botão
        // de lançar no lugar certo de cada um dos dois. Antes essa decisão
        // estava escrita três vezes aqui — `isLargeScreen` para o rail, de
        // novo para a barra e uma terceira para a posição do FAB — e nada
        // garantia que as três concordassem.
        //
        // `constrained: false` porque quem limita a largura é cada aba: a
        // Jornada cabe na largura de conteúdo, o Histórico é uma lista de
        // borda a borda.
        return AppScaffold(
          constrained: false,
          appBar: isLargeScreen
              ? null
              : AppBar(
                  leading: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs),
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
                  // A identidade do cofre mora AQUI e só aqui: nome, selo de
                  // tipo e nível. O corpo da Jornada repetia os três num
                  // cabeçalho próprio, e o nível ainda aparecia duas vezes —
                  // uma no anel da barra, outra no selo do corpo.
                  actions: [_arenaEntry(context), const WorkspaceLevelBadge()],
                ),
          rail: _buildNavigationRail(context, authUser),
          bottomBar: _buildBottomBar(context),
          launchAction: const LaunchFab(),
          body: TabBarView(
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
        );
      },
    );
  }

  /// A ÚNICA entrada da POC da Arena.
  ///
  /// Um método, e não o widget escrito duas vezes: a AppBar só existe no
  /// compacto e o rail só existe no largo, então a porta precisa aparecer nos
  /// dois — e no macOS e na web é o rail que manda. `test/arena` garante que
  /// o endereço esteja escrito uma vez só.
  Widget _arenaEntry(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context)!.arenaTitle,
    icon: const Icon(Icons.shield_outlined, color: AppColors.inkInverse),
    onPressed: () => context.push('/arena'),
  );

  Widget _buildNavigationRail(BuildContext context, UserModel? authUser) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationRail(
      extended: _isNavigationRailExtended,
      leading: Column(
        children: [
          AppSpacing.gapMd,
          IconButton(
            icon: Icon(
              _isNavigationRailExtended ? Icons.menu_open : Icons.menu,
              color: AppColors.inkInverse,
            ),
            onPressed: () {
              setState(() {
                _isNavigationRailExtended = !_isNavigationRailExtended;
              });
            },
          ),
          AppSpacing.gapMd,
          if (_isNavigationRailExtended)
            const Padding(
              padding: AppSpacing.hMd,
              child: WorkspaceSelector(isNavigationRail: true),
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
                color: AppColors.inkInverse,
              ),
            ),
          AppSpacing.gapLg,
          const WorkspaceLevelBadge(onGame: true),
          _arenaEntry(context),
          AppSpacing.gapMd,
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
              AppSpacing.gapXs,
              Text(
                authUser?.displayName ?? '',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.inkInverse),
              ),
            ],
            AppSpacing.gapMd,
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
      notchMargin: AppSpacing.xs,
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
            const SizedBox(width: AppSpacing.xxxl), // Espaço para o FAB
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
}
