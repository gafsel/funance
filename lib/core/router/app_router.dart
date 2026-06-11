import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/screens/splash_screen.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/auth/presentation/screens/login_screen.dart';
import 'package:funances/features/coaching/presentation/screens/coaching_slides_screen.dart';
import 'package:funances/features/finance/domain/models/account_model.dart';
import 'package:funances/features/finance/domain/models/installment_model.dart';
import 'package:funances/features/finance/domain/models/order_model.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/finance/presentation/screens/account_form_screen.dart';
import 'package:funances/features/finance/presentation/screens/account_management_screen.dart';
import 'package:funances/features/finance/presentation/screens/account_statement_screen.dart';
import 'package:funances/features/finance/presentation/screens/category_planning_screen.dart';
import 'package:funances/features/finance/presentation/screens/planning_50_30_20_screen.dart';
import 'package:funances/features/finance/presentation/screens/invoice_detail_screen.dart';
import 'package:funances/features/finance/presentation/screens/reconciliation_screen.dart';
import 'package:funances/features/finance/presentation/screens/transaction_form_screen.dart';
import 'package:funances/features/finance/presentation/screens/transaction_wizard_screen.dart';
import 'package:funances/features/goal/domain/models/goal_model.dart';
import 'package:funances/features/goal/presentation/screen/goal_form_screen.dart';
import 'package:funances/features/home/presentation/screens/home_screen.dart';
import 'package:funances/features/onboarding/presentation/provider.dart';
import 'package:funances/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:funances/features/user/presentation/screens/user_profile_screen.dart';
import 'package:funances/features/workspace/domain/models/category_model.dart';
import 'package:funances/features/workspace/domain/models/workspace_model.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/features/workspace/presentation/providers.dart';
import 'package:funances/features/workspace/presentation/screens/category_management_screen.dart';
import 'package:funances/features/workspace/presentation/screens/invite_list_screen.dart';
import 'package:funances/features/workspace/presentation/screens/workspace_settings_screen.dart';
import 'package:funances/features/workspace/presentation/widgets/category_form_screen.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(AuthDomainProviders.user);
  final workspaceState = ref.watch(WorkspaceViewProviders.workspace);
  final inviteState = ref.watch(inviteNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
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
        if (needsOnboarding && workspaceState.currentWorkspace != null) {
          Future(() {
            ref
                .read(OnboardingViewProviders.onboarding.notifier)
                .load(workspaceState.currentWorkspace!);
          });
        }
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
        builder: (context, state) => OnboardingScreen(),
      ),
      GoRoute(
        path: '/workspace/form',
        builder: (context, state) => OnboardingScreen(),
      ),
      GoRoute(
        path: '/workspace/settings',
        builder: (context, state) => const WorkspaceSettingsScreen(),
      ),
      GoRoute(
        path: '/workspace/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/workspace/categories/form',
        builder: (context, state) {
          final category = state.extra as CategoryModel?;
          return CategoryFormScreen(category: category);
        },
      ),
      GoRoute(
        path: '/workspace/accounts',
        builder: (context, state) => const AccountManagementScreen(),
      ),
      GoRoute(
        path: '/accounts/form',
        builder: (context, state) {
          final account = state.extra as AccountModel?;
          final typeStr = state.uri.queryParameters['type'];
          final initialType = typeStr != null
              ? AccountType.values.firstWhere((e) => e.name == typeStr)
              : null;

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
                  error: (err, stack) =>
                      Scaffold(body: Center(child: Text('Error: $err'))),
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
        path: '/transactions/form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra != null) {
            if (extra['installment'] != null) {
              final installment = extra['installment'] as InstallmentModel;
              final forceEdit = state.uri.queryParameters['forceEdit'] == 'true';
              if (installment.isInvoice && !forceEdit) {
                return InvoiceDetailScreen(invoice: installment);
              }

              final statusStr = state.uri.queryParameters['status'];
              final status = statusStr != null
                  ? InstallmentStatus.values.firstWhere((e) => e.name == statusStr)
                  : null;

              return TransactionFormScreen.updateInstallment(
                installment: installment,
                status: status,
              );
            }
          }

          final typeStr = state.uri.queryParameters['type'];
          final type = OrderType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => OrderType.expense,
          );

          final hasCategory = extra?['category'] != null;
          final hasAccounts =
              state.uri.queryParameters['accountIdSource'] != null ||
              state.uri.queryParameters['accountIdTarget'] != null;

          if (hasCategory || hasAccounts || state.uri.queryParameters['description'] != null) {
            final statusStr = state.uri.queryParameters['status'];
            final status = statusStr != null
                ? InstallmentStatus.values.firstWhere((e) => e.name == statusStr)
                : null;

            final amountStr = state.uri.queryParameters['amount'];
            final amount = amountStr != null ? double.tryParse(amountStr) : null;

            final dateStr = state.uri.queryParameters['date'];
            final date = dateStr != null ? DateTime.tryParse(dateStr) : null;

            return TransactionFormScreen.creation(
              type: type,
              status: status,
              category: extra?['category'] as CategoryModel?,
              accountIdSource: state.uri.queryParameters['accountIdSource'],
              accountIdTarget: state.uri.queryParameters['accountIdTarget'],
              description: state.uri.queryParameters['description'],
              amount: amount,
              dueDate: date,
            );
          }

          final statusStr = state.uri.queryParameters['status'];
          final status = statusStr != null
              ? InstallmentStatus.values.firstWhere((e) => e.name == statusStr)
              : null;

          final skipTransactions = state.uri.queryParameters['skipTransactions'] == 'true';

          return TransactionWizardScreen(
            type: type,
            initialStatus: status,
            skipTransactions: skipTransactions,
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
          return CategoryPlanningScreen(type: type);
        },
      ),
      GoRoute(
        path: '/goals/form',
        builder: (context, state) {
          final goal = state.extra as GoalModel?;
          return GoalFormScreen(goal: goal);
        },
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (context, state) {
          final account = state.extra as AccountModel;
          return ReconciliationScreen(account: account);
        },
      ),
      GoRoute(
        path: '/planning-50-30-20',
        builder: (context, state) => const Planning503020Screen(),
      ),
      GoRoute(
        path: '/coaching',
        builder: (context, state) => const CoachingSlidesScreen(),
      ),
    ],
  );
});
