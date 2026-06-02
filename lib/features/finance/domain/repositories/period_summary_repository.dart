import 'package:funances/features/finance/domain/models/period_summary_model.dart';

abstract class IPeriodSummaryRepository {
  Stream<List<PeriodSummaryModel>> watchYear(String workspaceId, int year);

  Stream<List<PeriodSummaryModel>> watchMonth(String workspaceId, int year, int month);

  Stream<List<PeriodSummaryModel>> watchWeek(String workspaceId, int year, int week);
}
