import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/features/finance/domain/services/unplanned_nudge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:funances/core/observability/app_logger.dart';

/// Memória local de "já perguntei sobre esta categoria hoje".
///
/// Fica em `SharedPreferences` e é por WORKSPACE: a mesma categoria na casa e
/// na empresa são decisões diferentes, e responder numa não pode calar a
/// outra. Não vai para o Firestore de propósito — é uma preferência de
/// apresentação deste aparelho, não um dado financeiro.
class SharedPreferencesUnplannedNudgeStore implements IUnplannedNudgeStore {
  SharedPreferencesUnplannedNudgeStore();

  static String keyFor(String workspaceId, String categoryId) =>
      'unplanned_nudge:$workspaceId:$categoryId';

  @override
  Future<bool> wasShownToday(
    String workspaceId,
    String categoryId,
    DateTime today,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(keyFor(workspaceId, categoryId));

      return stored == today.formated('yyyy-MM-dd');
    } catch (error, stack) {
      // Sem a preferência o convite aparece: perder a memória do dia é um
      // incômodo, e silenciar o convite por causa dela seria perder a feature.
      AppLogger.error(
        'Falha ao ler a memória do nudge de gasto não planejado',
        error,
        stack,
      );
      return false;
    }
  }

  @override
  Future<void> markShown(
    String workspaceId,
    String categoryId,
    DateTime today,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        keyFor(workspaceId, categoryId),
        today.formated('yyyy-MM-dd'),
      );
    } catch (error, stack) {
      AppLogger.error(
        'Falha ao gravar a memória do nudge de gasto não planejado',
        error,
        stack,
      );
    }
  }
}
