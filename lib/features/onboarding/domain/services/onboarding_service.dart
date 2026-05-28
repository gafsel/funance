import '../../../finance/domain/models/order_model.dart';
import '../../../finance/domain/models/planning_model.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../../finance/domain/models/account_model.dart';
import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';

abstract class IOnboardingService {
  Future<List<GoalModel>> analyzeAccounts({
    required WorkspaceType workspaceType,
    required List<OrderModel> transactions,
  });

  Future<WorkspaceModel> createWorkspace({
    required String userId,
    required String name,
    required WorkspaceType type,
  });

  Future<void> finalizeOnboarding({
    required String userId,
    required String workspaceId,
    required List<AccountModel> accounts,
    required List<GoalModel> goals,
    required List<String> inviteEmails,
    List<OrderModel> orders = const [],
    List<PlanningModel> plannings = const [],
  });

  Future<AnalysisResult> analyzeDocument({
    required String storagePath,
    required String fileName,
    required List<String> existingCategories,
  });
}
