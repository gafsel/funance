import 'package:funances/features/goal/domain/repositories/goal_milestone_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoalMilestoneRepositoryImpl implements IGoalMilestoneRepository {
  static const _prefix = 'goal_milestone_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<int> getLastCelebratedMilestone(String goalId) async {
    final prefs = await _prefs;
    return prefs.getInt('$_prefix$goalId') ?? 0;
  }

  @override
  Future<void> saveCelebratedMilestone(String goalId, int milestone) async {
    final prefs = await _prefs;
    await prefs.setInt('$_prefix$goalId', milestone);
  }

  @override
  Future<void> cleanupMilestones(Set<String> activeGoalIds) async {
    final prefs = await _prefs;
    final keysToRemove = prefs.getKeys().where((key) {
      if (!key.startsWith(_prefix)) return false;
      final id = key.replaceFirst(_prefix, '');
      return !activeGoalIds.contains(id);
    }).toList();

    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
