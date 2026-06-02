import 'package:funances/features/finance/domain/models/period_summary_model.dart';
import 'package:funances/features/finance/domain/repositories/period_summary_repository.dart';

class PeriodSummaryService {
  final String workspaceId;
  final IPeriodSummaryRepository repository;

  PeriodSummaryService({required this.workspaceId, required this.repository});

  Stream<List<PeriodSummaryModel>> watchYear(int year) {
    return repository.watchYear(workspaceId, year);
  }

  Stream<List<PeriodSummaryModel>> watchMonth(int year, int month) {
    return repository.watchMonth(workspaceId, year, month);
  }

  Stream<List<PeriodSummaryModel>> watchWeek(int year, int week) {
    return repository.watchWeek(workspaceId, year, week);
  }
}
