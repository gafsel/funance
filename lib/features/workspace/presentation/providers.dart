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
import 'package:funances/features/workspace/presentation/model/workspace_view_model.dart';

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
            error: (_, __) {},
          );
        });

        return notifier;
      });

  static final currentWorkspaceId = Provider((ref) {
    return ref.watch(workspace).currentWorkspace?.id;
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
      workspaceId:
          ref.watch(WorkspaceViewProviders.workspace).currentWorkspace?.id ??
          "",
      repository: ref.read(repository),
    ),
  );
}

sealed class CategoryViewProviders {
  static final allStream = StreamProvider<List<CategoryModel>>((ref) {
    final service = ref.watch(CategoryDomainProviders.service);
    return service.getCategories();
  });

  static final byId = StreamProvider.family<CategoryModel?, String>((
    ref,
    categoryId,
  ) {
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
