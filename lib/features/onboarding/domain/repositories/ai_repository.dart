import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import '../../../finance/domain/models/order_model.dart';

abstract class IAIRepository {
  Future<List<GoalModel>> analyzeAccounts({
    required WorkspaceType workspaceType,
    required List<OrderModel> transactions,
  });

  Future<AnalysisResult> analyzeDocument({
    required String storagePath,
    required String fileName,
    required List<String> existingCategories,
  });
}

class AnalysisResult {
  final Map<String, dynamic> accountData;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> plannings;

  AnalysisResult({
    required this.accountData,
    this.orders = const [],
    this.plannings = const [],
  });
}
