import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:funances/features/finance/presentation/providers.dart';
import 'package:funances/features/goal/data/repositories/goal_repository_impl.dart';
import 'package:funances/features/goal/domain/services/goal_service.dart';
import 'package:funances/features/goal/presentation/providers/goal_form_provider.dart';
import 'package:funances/features/workspace/presentation/providers.dart';

sealed class GoalDomainProvider {
  static final repository = Provider((_) => GoalRepositoryImpl());

  static final service = Provider(
    (ref) => GoalService(
      workspaceId:
          ref.read(WorkspaceViewProviders.workspace).currentWorkspace?.id ?? "",
      repository: ref.read(repository),
    ),
  );
}

sealed class GoalViewProvider {
  static final form = StateNotifierProvider.autoDispose(
    (ref) => GoalFormNotifier(
      goalService: ref.read(GoalDomainProvider.service),
      accountService: ref.read(AccountDomainProviders.service),
    ),
  );
}
