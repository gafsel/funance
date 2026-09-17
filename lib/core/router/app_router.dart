import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/core/presentation/screens/splash_screen.dart';
import 'package:funances/core/router/entity_route.dart';
import 'package:funances/core/utils/build_context_extension.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/auth/presentation/screens/login_screen.dart';
import 'package:funances/features/coaching/domain/models/coaching_model.dart';
import 'package:funances/features/coaching/presentation/providers.dart';
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
import 'package:funances/features/goal/presentation/provider.dart';
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
/// real) força o go_router a reprocessar a rota atual — trabalho por nada, e
/// pisca a tela de quem está no meio de um formulário.
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

/// Toda rota de detalhe recebe o id pelo endereço e carrega o documento pelo
/// provider (ver [EntityRoute]). Nada de objeto no `extra`: `extra` é memória
/// do processo, some no F5 da web e no hot restart, e o que sobrava disso era
/// um redirect para a home no meio da navegação de quem só apertou "atualizar".


/// Id vindo da query. **Vazio é ausente.**
///
/// Uma tela montava `/accounts/form?id=${account?.id ?? ''}` e, sem conta,
/// mandava `?id=` — que chegava aqui como o id `''`. A rota ia então procurar
/// um documento de id vazio e mostrava "este item não existe mais" no lugar do
/// formulário de criação. Tratar vazio como ausente é a diferença entre "não
/// me disseram qual" e "me disseram um que não existe".
@visibleForTesting
String? idParam(Uri uri, String name) {
  final value = uri.queryParameters[name]?.trim();
  return (value == null || value.isEmpty) ? null : value;
}

/// O que a rota `/accounts/form` recebe pelo endereço.
///
/// Separado do `builder` para poder ser testado sem montar a tela: é aqui que
/// se decide entre editar (id) e criar (com ou sem tipo sugerido).
@visibleForTesting
({String? accountId, AccountType? initialType}) accountFormArgs(Uri uri) {
  final typeStr = uri.queryParameters['type'];

  return (
    accountId: idParam(uri, 'id'),
    initialType: AccountType.values.where((e) => e.name == typeStr).firstOrNull,
  );
}

/// O formulário de criação montado a partir do ENDEREÇO.
///
/// Todos os parâmetros vêm da query — é o que faz um refresh no meio do
/// preenchimento reabrir o mesmo formulário, com o mesmo valor e a mesma data,
/// em vez de voltar ao início.
Widget _transactionCreation(
  GoRouterState state,
  OrderType type,
  InstallmentStatus? status,
  CategoryModel? category,
) {
  final amountStr = state.uri.queryParameters['amount'];
  final dateStr = state.uri.queryParameters['date'];

  // Só o nudge de gasto não planejado manda este parâmetro, para abrir o
  // formulário já em "toda vez" — foi o que o usuário acabou de escolher, e
  // obrigá-lo a repetir a escolha na tela seguinte seria perguntar duas vezes
  // a mesma coisa.
  final installmentTypeStr = state.uri.queryParameters['installmentType'];

  return TransactionFormScreen.creation(
    type: type,
    status: status,
    installmentType: InstallmentType.values
        .where((e) => e.name == installmentTypeStr)
        .firstOrNull,
    category: category,
    accountIdSource: state.uri.queryParameters['accountIdSource'],
    accountIdTarget: state.uri.queryParameters['accountIdTarget'],
    description: state.uri.queryParameters['description'],
    amount: amountStr != null ? double.tryParse(amountStr) : null,
    dueDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
  );
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
          final id = idParam(state.uri, 'id');
          if (id == null) return const CategoryFormScreen();

          return EntityRoute<CategoryModel>(
            provider: CategoryViewProviders.byId(id),
            builder: (context, category) =>
                CategoryFormScreen(category: category),
          );
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
          final args = accountFormArgs(state.uri);
          final accountId = args.accountId;

          if (accountId != null) {
            return EntityRoute<AccountModel>(
              provider: AccountViewProviders.byId(accountId),
              builder: (context, account) =>
                  AccountFormScreen(account: account),
            );
          }

          return AccountFormScreen(initialType: args.initialType);
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
        path: '/invoices/:id',
        builder: (context, state) => EntityRoute<InstallmentModel>(
          provider: FinanceViewProviders.installmentById(
            state.pathParameters['id']!,
          ),
          builder: (context, invoice) => InvoiceDetailScreen(invoice: invoice),
        ),
      ),
      GoRoute(
        path: '/transactions/form',
        builder: (context, state) {
          final statusStr = state.uri.queryParameters['status'];
          final status = InstallmentStatus.values
              .where((e) => e.name == statusStr)
              .firstOrNull;

          final installmentId = idParam(state.uri, 'installmentId');
          if (installmentId != null) {
            return EntityRoute<InstallmentModel>(
              provider: FinanceViewProviders.installmentById(installmentId),
              builder: (context, installment) =>
                  TransactionFormScreen.updateInstallment(
                    installment: installment,
                    status: status,
                  ),
            );
          }

          final typeStr = state.uri.queryParameters['type'];
          final type = OrderType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => OrderType.expense,
          );

          final categoryId = idParam(state.uri, 'categoryId');
          final hasDescription =
              state.uri.queryParameters['description'] != null;

          if (categoryId != null) {
            return EntityRoute<CategoryModel>(
              provider: CategoryViewProviders.byId(categoryId),
              builder: (context, category) =>
                  _transactionCreation(state, type, status, category),
            );
          }

          if (hasDescription) {
            return _transactionCreation(state, type, status, null);
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
          final id = idParam(state.uri, 'id');
          if (id == null) return const GoalFormScreen();

          return EntityRoute<GoalModel>(
            provider: GoalViewProvider.goalById(id),
            builder: (context, goal) => GoalFormScreen(goal: goal),
          );
        },
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (context, state) => EntityRoute<GoalModel>(
          provider: GoalViewProvider.goalById(state.pathParameters['id']!),
          title: context.l10n.goalDetailsTitle,
          builder: (context, goal) => GoalDetailScreen(goal: goal),
        ),
      ),
      GoRoute(
        path: '/reconciliation',
        builder: (context, state) {
          final accountId = idParam(state.uri, 'accountId');
          if (accountId == null) {
            return const ReconciliationAccountPickerScreen();
          }

          return EntityRoute<AccountModel>(
            provider: AccountViewProviders.byId(accountId),
            title: context.l10n.reconciliationTitle,
            builder: (context, account) =>
                ReconciliationScreen(account: account),
          );
        },
      ),
      GoRoute(
        path: '/planning-50-30-20',
        builder: (context, state) => const Planning503020Screen(),
      ),
      GoRoute(
        path: '/coaching',
        redirect: (context, state) =>
            idParam(state.uri, 'id') == null ? '/coaching/history' : null,
        builder: (context, state) => EntityRoute<CoachingModel>(
          provider: CoachingViewProviders.insightById(
            idParam(state.uri, 'id')!,
          ),
          builder: (context, coaching) =>
              CoachingSlidesScreen(coaching: coaching),
        ),
      ),
      GoRoute(
        path: '/coaching/history',
        builder: (context, state) => const CoachingHistoryScreen(),
      ),
    ],
  );
});
