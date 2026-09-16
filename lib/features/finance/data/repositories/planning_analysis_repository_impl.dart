import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:funances/features/finance/domain/models/planning_503020_analysis.dart';
import 'package:funances/features/finance/domain/repositories/planning_analysis_repository.dart';

class PlanningAnalysisRepositoryImpl implements IPlanningAnalysisRepository {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  @override
  Future<Planning503020Analysis> analyze(String workspaceId) async {
    final callable = _functions.httpsCallable(
      'analyze503020Ideal',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
    );

    final result = await callable.call({'workspaceId': workspaceId});

    // O servidor persiste a análise e devolve o payload já validado com o id
    // do documento — o cliente não grava nada (a coleção é somente leitura).
    // O jsonDecode/jsonEncode normaliza os Map<Object?, Object?> aninhados
    // retornados pelo callable em Map<String, dynamic>.
    final data = jsonDecode(jsonEncode(result.data)) as Map<String, dynamic>;
    return Planning503020Analysis.fromJson(data);
  }
}
