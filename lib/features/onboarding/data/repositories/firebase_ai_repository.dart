import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import '../../../finance/domain/models/order_model.dart';
import '../../../goal/domain/models/goal_model.dart';
import '../../../workspace/domain/models/workspace_model.dart';
import 'package:funances/features/onboarding/domain/repositories/ai_repository.dart';
import 'package:funances/core/exceptions/business_exception.dart';

class FirebaseAIRepository implements IAIRepository {
  final FirebaseFunctions _functions;

  FirebaseAIRepository({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _convertValue(value)));
    }
    return {};
  }

  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertToMap(value);
    } else if (value is List) {
      return value.map((e) => _convertValue(e)).toList();
    }
    return value;
  }

  @override
  Future<List<GoalModel>> analyzeAccounts({
    required WorkspaceType workspaceType,
    required List<OrderModel> transactions,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeOnboarding');
      
      final result = await callable.call({
        'workspaceType': workspaceType.name,
        'transactions': transactions.map((t) => {
          'description': t.description,
          'totalAmount': t.totalAmount,
          'type': t.type.name,
          'category': t.category.name,
          'date': t.date.toIso8601String(),
        }).toList(),
      });

      final data = _convertToMap(result.data);
      final suggestionsData = data['suggestions'] as List? ?? [];
      return suggestionsData.map((data) {
        final map = _convertToMap(data);
        return GoalModel(
          id: const Uuid().v4(),
          name: map['name'],
          targetAmount: (map['targetAmount'] as num? ?? 0.0).toDouble(),
          currentAmount: 0.0,
          type: GoalType.values.firstWhere(
            (e) => e.name == map['type'],
            orElse: () => GoalType.saveMoney,
          ),
          deadline: DateTime.now().add(Duration(days: (map['deadlineMonths'] ?? 6) * 30)),
          icon: map['icon'] ?? 'star',
        );
      }).toList();
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }

  @override
  Future<AnalysisResult> analyzeDocument({
    required String storagePath,
    required String fileName,
    required List<String> existingCategories,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeAccountDocument');
      
      final result = await callable.call({
        'storagePath': storagePath,
        'fileName': fileName,
        'existingCategories': existingCategories,
      });

      final data = _convertToMap(result.data);
      
      return AnalysisResult(
        accountData: _convertToMap(data['account']),
        orders: (data['orders'] as List? ?? []).map((e) => _convertToMap(e)).toList(),
        plannings: (data['plannings'] as List? ?? []).map((e) => _convertToMap(e)).toList(),
      );
    } catch (e, s) {
      throw BusinessException(ErrorCode.unknown, originalError: e, stackTrace: s);
    }
  }
}
