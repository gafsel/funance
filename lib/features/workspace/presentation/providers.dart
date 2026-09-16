import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/auth/presentation/providers.dart';
import 'package:funances/features/user/domain/models/user_model.dart';
import 'package:funances/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:funances/features/workspace/domain/repositories/workspace_repository.dart';
import 'package:funances/features/workspace/domain/services/workspace_service.dart';
import 'package:funances/features/workspace/domain/services/category_service.dart';
import 'package:funances/features/workspace/presentation/controller/category_form_notifier.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_notifier.dart';
import 'package:funances/features/workspace/presentation/model/category_view_models.dart';
import 'package:funances/features/workspace/presentation/model/workspace_members_view_models.dart';
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';
import 'package:funances/features/workspace/presentation/controller/workspace_members_notifier.dart';
import 'package:funances/features/workspace/presentation/controller/invite_providers.dart';
import 'package:funances/core/analytics/analytics_providers.dart';

import '../data/repositories/category_repository_impl.dart';
import '../domain/models/category_model.dart';
import '../domain/repositories/category_repository.dart';

sealed class WorkspaceDomainProviders {
  static final repository = Provider<IWorkspaceRepository>((ref) {
    return WorkspaceRepositoryImpl();
  });

  static final service = Provider((ref) {
    final repo = ref.watch(repository);
    return WorkspaceService(repo);
  });
}

sealed class WorkspaceViewProviders {
  static final workspace =
      StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
        final repository = ref.read(WorkspaceDomainProviders.repository);
        final notifier = WorkspaceNotifier(repository);

        // Reagir a mudanças de autenticação para carregar workspaces
        ref.listen(AuthDomainProviders.user, (previous, next) {
          next.when(
            data: (user) {
              if (user != null) {
                notifier.loadWorkspaces(user.id);
              } else {
                notifier.reset();
              }
            },
            loading: () {},
            error: (_, _) {},
          );
        });

        return notifier;
      });

  /// Id do workspace corrente, isolado do resto do estado.
  ///
  /// Todo provider de serviço/repositório observa este provider (e não
  /// `workspace`): o doc do workspace é observado em tempo real e cada XP,
  /// badge ou streak concedido pelo servidor produz um `WorkspaceState` novo.
  /// Observando só o id, os serviços são recriados apenas quando o usuário
  /// troca de workspace.
  static final currentWorkspaceId = Provider<String?>((ref) {
    return ref.watch(workspace.select((state) => state.currentWorkspace?.id));
  });

  /// XP, nível, badges e streak do workspace corrente.
  ///
  /// Para as telas que celebram gamificação (level-up, confete, snackbar de
  /// badge) reagirem em tempo real sem arrastar junto a recriação dos
  /// serviços.
  static final gamification = Provider<WorkspaceGamification>((ref) {
    return ref.watch(
      workspace.select(
        (state) =>
            state.currentWorkspace?.gamification ??
            const WorkspaceGamification(),
      ),
    );
  });

  /// Tela de gestão de membros.
  ///
  /// `autoDispose` de propósito: o stream de convites só precisa existir
  /// enquanto a tela está aberta.
  static final membersManagement = StateNotifierProvider.autoDispose<
    WorkspaceMembersNotifier,
    WorkspaceMembersState
  >((ref) {
    final state = ref.watch(workspace);

    return WorkspaceMembersNotifier(
      workspaceService: ref.watch(WorkspaceDomainProviders.service),
      inviteRepository: ref.watch(inviteRepositoryProvider),
      analytics: ref.watch(analyticsServiceProvider),
      workspaceId: state.currentWorkspace?.id ?? "",
      // O dono é o criador, que é members[0] — mesma definição do
      // `assertWorkspaceOwner` no backend.
      ownerId: state.currentWorkspace?.members.firstOrNull,
      currentUserId: ref.watch(AuthDomainProviders.currentUser)?.id,
    );
  });

  static final members = FutureProvider<List<UserModel>>((ref) async {
    final workspaceId = ref.watch(currentWorkspaceId);
    if (workspaceId == null) return [];
    final service = ref.read(WorkspaceDomainProviders.service);
    return await service.getWorkspaceMembers(workspaceId);
  });
}

sealed class CategoryDomainProviders {
  static final repository = Provider<ICategoryRepository>((ref) {
    return CategoryRepositoryImpl();
  });
  static final service = Provider(
    (ref) => CategoryService(
      workspaceId: ref.watch(WorkspaceViewProviders.currentWorkspaceId) ?? "",
      repository: ref.read(repository),
    ),
  );
}

sealed class CategoryViewProviders {
  static final allStream = StreamProvider<List<CategoryModel>>((ref) {
    final service = ref.watch(CategoryDomainProviders.service);
    return service.getCategories();
  });

  static final byId = StreamProvider.autoDispose
      .family<CategoryModel?, String>((ref, categoryId) {
        final categories = ref.watch(allStream);

        return categories.when(
          data: (data) => Stream.value(
            data.where((category) => category.id == categoryId).firstOrNull,
          ),
          error: (error, stack) => Stream.error(error, stack),
          loading: () => Stream.empty(),
        );
      });

  static final form = StateNotifierProvider.autoDispose
      .family<CategoryFormNotifier, CategoryFormState, CategoryModel?>((
        ref,
        category,
      ) {
        final service = ref.watch(CategoryDomainProviders.service);
        return CategoryFormNotifier(
          service: service,
          initialCategory: category,
        );
      });
}
