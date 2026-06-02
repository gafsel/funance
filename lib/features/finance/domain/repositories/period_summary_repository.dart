import 'package:funances/features/finance/domain/models/period_summary_model.dart';

abstract class IPeriodSummaryRepository {
  Stream<PeriodSummaryModel?> watchYear(String workspaceId, int year);

  Stream<PeriodSummaryModel?> watchMonth(
    String workspaceId,
    int year,
    int month,
  );

  Stream<PeriodSummaryModel?> watchWeek(String workspaceId, int year, int week);
}
