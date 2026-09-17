import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/screens/splash_screen.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/auth/presentation/screens/login_screen.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/screens/coaching_slides_screen.dart';
import 'package:funances/features/coaching/presentation/screens/coaching_history_screen.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_form_screen.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';
import 'package:funances/features/finance/presentation/screens/account_statement_screen.dart';
import 'package:funances/features/finance/presentation/screens/category_planning_screen.dart';
import 'package:funances/features/finance/presentation/screens/category_report_detail_screen.dart';
import 'package:funances/features/finance/presentation/screens/planning_50_30_20_screen.dart';
import 'package:funances/features/finance/presentation/screens/invoice_detail_screen.dart';
import 'package:funances/features/finance/presentation/screens/reconciliation_screen.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/screens/transaction_wizard_screen.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/screen/goal_form_screen.dart';
import 'package:funances/features/goal/presentation/screen/goal_detail_screen.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:funances/features/user/presentation/screens/user_profile_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/screens/badges_cabinet_screen.dart';
import 'package:funances/features/workspace/presentation/screens/category_management_screen.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_members_screen.dart';
import 'package:funances/features/workspace/presentation/screens/invite_list_screen.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_screen.dart';
import 'package:go_router/go_router.dart';

/// Notifica o GoRouter quando auth/workspace/convites mudam, sem recriar o
/// router (recriar o router descarta a pilha de navegação inteira).
///
/// Notifica APENAS quando muda algo que o `redirect` realmente usa. Notificar
/// em toda mudança de estado (ex.: o XP do workspace atualizando em tempo
/// real) força o go_router a reprocessar a rota atual, o que desidrata o
/// `extra` tipado para um Map e quebra telas abertas.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(AuthDomainProviders.user, (previous, next) {
      final before = (previous?.isLoading, previous?.valueOrNull?.id);
      final after = (next.isLoading, next.valueOrNull?.id);
      if (before != after) notifyListeners();
    });
    ref.listen(WorkspaceViewProviders.workspace, (previous, next) {
      final before = (
        previous?.isLoading,
        previous?.initialLoadDone,
        previous?.availableWorkspaces.isEmpty,
        previous?.currentWorkspace?.id,
        previous?.currentWorkspace?.lastOnboardingStep,
      );
      final after = (
        next.isLoading,
        next.initialLoadDone,
        next.availableWorkspaces.isEmpty,
        next.currentWorkspace?.id,
        next.currentWorkspace?.lastOnboardingStep,
      );
      if (before != after) notifyListeners();
    });
    ref.listen(inviteNotifierProvider, (previous, next) {
      final before = (
        previous?.isLoading,
        previous?.initialLoadDone,
        previous?.pendingInvites.length,
      );
      final after = (
        next.isLoading,
        next.initialLoadDone,
        next.pendingInvites.length,
      );
      if (before != after) notifyListeners();
    });
  }
}

/// Recupera um `extra` tipado. Quando o go_router reprocessa a rota, o objeto
/// pode chegar desidratado como Map (via `jsonEncode`/`toJson`) — nesse caso,
/// re-hidrata com [fromJson]. Retorna null se não for possível.
T? _extraAs<T>(Object? extra, T Function(Map<String, dynamic>) fromJson) {
  if (extra is T) return extra;
  if (extra is Map) {
    try {
      return fromJson(Map<String, dynamic>.from(extra));
    } catch (_) {
      return null;
    }
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(context.l10n.routeNotFound),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(context.l10n.routeNotFoundGoHome),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(AuthDomainProviders.user);
      final workspaceState = ref.read(WorkspaceViewProviders.workspace);
      final inviteState = ref.read(inviteNotifierProvider);

      final isSplash = state.matchedLocation == '/splash';

      if (authState.isLoading) {
        return isSplash ? null : '/splash';
      }

      final user = authState.valueOrNull;
      final isLoggingIn = state.matchedLocation == '/login';

      if (user == null) {
        if (isLoggingIn) return null;
        return '/login';
      }

      // Aguarda carregamento inicial
      if (workspaceState.isLoading ||
          !workspaceState.initialLoadDone ||
          inviteState.isLoading ||
          !inviteState.initialLoadDone) {
        return null;
      }

      if (isLoggingIn || isSplash) {
        return '/';
      }

      // Convites pendentes
      if (inviteState.pendingInvites.isNotEmpty) {
        if (state.matchedLocation != '/invites') {
          return '/invites';
        }

        return null;
      }

      // Onboarding
      final hasNoWorkspaces = workspaceState.availableWorkspaces.isEmpty;
      final needsOnboarding =
          (workspaceState.currentWorkspace?.lastOnboardingStep ??
              OnboardingSteps.done) !=
          OnboardingSteps.done;

      if ((hasNoWorkspaces || needsOnboarding) &&
          state.matchedLocation != '/onboarding' &&
          state.matchedLocation != '/accounts/form') {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/invites',
        builder: (context, state) => const InviteListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingEntry(createNew: false),
      ),
      GoRoute(
        path: '/workspace/form',
        builder: (context, state) => const OnboardingEntry(createNew: true),
      ),
      GoRoute(
        path: '/workspace/settings',
        builder: (context, state) => const WorkspaceSettingsScreen(),
      ),
      GoRoute(
        path: '/workspace/badges',
        builder: (context, state) => const BadgesCabinetScreen(),
      ),
      GoRoute(
        path: '/workspace/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/workspace/categories/form',
        builder: (context, state) {
          final category = _extraAs(state.extra, CategoryModel.fromJson);
          return CategoryFormScreen(category: category);
        },
      ),
      GoRoute(
        path: '/workspace/accounts',
        builder: (context, state) => const AccountManagementScreen(),
      ),
      GoRoute(
        path: '/workspace/members',
        builder: (context, state) => const WorkspaceMembersScreen(),
      ),
      GoRoute(
        path: '/accounts/form',
        builder: (context, state) {
          final account = _extraAs(state.extra, AccountModel.fromJson);
          final typeStr = state.uri.queryParameters['type'];
          final initialType = AccountType.values
              .where((e) => e.name == typeStr)
              .firstOrNull;

          if (account != null) {
            return AccountFormScreen(account: account);
          }

          final accountId = state.uri.queryParameters['id'];
          if (accountId != null) {
            return Consumer(
              builder: (context, ref, child) {
                final accountAsync = ref.watch(
                  AccountViewProviders.byId(accountId),
                );
                return accountAsync.when(
                  data: (acc) => AccountFormScreen(account: acc),
                  loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Scaffold(
                    body: Center(child: Text(context.l10n.errorUnknown)),
                  ),
                );
              },
            );
          }

          return AccountFormScreen(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/accounts/:id/statement',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AccountStatementScreen(accountId: id);
        },
      ),
      GoRoute(
        path: '/invoices/detail',
        redirect: (context, state) =>
            _extraAs(state.extra, InstallmentModel.fromJson) != null
            ? null
            : '/',
        builder: (context, state) {
          final installment = _extraAs(state.extra, InstallmentModel.fromJson)!;
          return InvoiceDetailScreen(invoice: installment);
        },
      ),
      GoRoute(
        path: '/transactions/form',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          final statusStr = state.uri.queryParameters['status'];
          final status = InstallmentStatus.values
              .where((e) => e.name == statusStr)
              .firstOrNull;

          final extraInstallment = _extraAs(
            extra?['installment'],
            InstallmentModel.fromJson,
          );
          if (extraInstallment != null) {
            return TransactionFormScreen.updateInstallment(
              installment: extraInstallment,
              status: status,
            );
          }

          final typeStr = state.uri.queryParameters['type'];
          final type = OrderType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => OrderType.expense,
          );

          final extraCategory = _extraAs(
            extra?['category'],
            CategoryModel.fromJson,
          );
          final hasCategory = extraCategory != null;
          final hasDescription =
              state.uri.queryParameters['description'] != null;

          if (hasCategory || hasDescription) {
            final amountStr = state.uri.queryParameters['amount'];
            final amount = amountStr != null
                ? double.tryParse(amountStr)
                : null;

            final dateStr = state.uri.queryParameters['date'];
            final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

            // Só o nudge de gasto não planejado manda este parâmetro, para
            // abrir o formulário já em "toda vez" — foi o que o usuário
            // acabou de escolher, e obrigá-lo a repetir a escolha na tela
            // seguinte seria perguntar duas vezes a mesma coisa.
            final installmentTypeStr =
                state.uri.queryParameters['installmentType'];
            final installmentType = InstallmentType.values
                .where((e) => e.name == installmentTypeStr)
                .firstOrNull;

            return TransactionFormScreen.creation(
              type: type,
              status: status,
              installmentType: installmentType,
              category: extraCategory,
              accountIdSource: state.uri.queryParameters['accountIdSource'],
              accountIdTarget: state.uri.queryParameters['accountIdTarget'],
              description: state.uri.queryParameters['description'],
              amount: amount,
              dueDate: date,
            );
          }

          return TransactionWizardScreen(
            type: type,
            initialStatus: status,
            accountIdSource: state.uri.queryParameters['accountIdSource'],
          );
        },
      ),
      GoRoute(
        path: '/planning',
        builder: (context, state) {
          final typeStr = state.uri.queryParameters['type'];
          final type = CategoryType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => CategoryType.expense,
          );

          // O nudge de gasto não planejado chega aqui com a categoria e uma
          // sugestão de valor: quem veio definir um limite específico não
          // pode cair numa lista de trinta categorias sem saber qual era.
          final suggestedStr = state.uri.queryParameters['suggested'];

          return CategoryPlanningScreen(
            type: type,
            highlightCategoryId: state.uri.queryParameters['categoryId'],
            suggestedAmount: suggestedStr != null
                ? double.tryParse(suggestedStr)
                : null,
          );
        },
      ),
      GoRoute(
        path: '/category-details',
        builder: (context, state) {
          final typeStr = state.uri.queryParameters['type'];
          final type = CategoryType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => CategoryType.expense,
          );
          return CategoryReportDetailScreen(type: type);
        },
      ),
      GoRoute(
        path: '/goals/form',
        builder: (context, state) {
          final goal = _extraAs(state.extra, GoalModel.fromJson);
          return GoalFormScreen(goal: goal);
        },
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GoalDetailScreen(goalId: id);
        },
      ),
      GoRoute(
        path: '/reconciliation',
        redirect: (context, state) =>
            _extraAs(state.extra, AccountModel.fromJson) != null ? null : '/',
        builder: (context, state) {
          final account = _extraAs(state.extra, AccountModel.fromJson)!;
          return ReconciliationScreen(account: account);
        },
      ),
      GoRoute(
        path: '/planning-50-30-20',
        builder: (context, state) => const Planning503020Screen(),
      ),
      GoRoute(
        path: '/coaching',
        redirect: (context, state) =>
            _extraAs(state.extra, CoachingModel.fromJson) != null
            ? null
            : '/coaching/history',
        builder: (context, state) {
          final coaching = _extraAs(state.extra, CoachingModel.fromJson)!;
          return CoachingSlidesScreen(coaching: coaching);
        },
      ),
      GoRoute(
        path: '/coaching/history',
        builder: (context, state) => const CoachingHistoryScreen(),
      ),
    ],
  );
});
