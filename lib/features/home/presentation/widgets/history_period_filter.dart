import 'package:flutter/material.dart';
import 'package:funances/core/theme/app_colors.dart';
import 'package:funances/core/utils/date_extension.dart';
import 'package:funances/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum HistoryPeriodType {
  day,
  month,
  quarter,
  semester,
  year,
  custom;

  String label(AppLocalizations l10n) {
    return switch (this) {
      HistoryPeriodType.day => l10n.periodFilterDay,
      HistoryPeriodType.month => l10n.periodFilterMonth,
      HistoryPeriodType.quarter => l10n.periodFilterQuarter,
      HistoryPeriodType.semester => l10n.periodFilterSemester,
      HistoryPeriodType.year => l10n.periodFilterYear,
      HistoryPeriodType.custom => l10n.periodFilterCustom,
    };
  }

  (DateTime startDate, DateTime endDate) getRange() {
    final now = DateTime.now();
    return switch (this) {
      HistoryPeriodType.day => (
        DateTime(now.year, now.month, now.day),
        DateTime(now.year, now.month, now.day, 23, 59, 59),
      ),
      HistoryPeriodType.month => (
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      ),
      HistoryPeriodType.quarter => _getQuarterRange(now),
      HistoryPeriodType.semester => _getSemesterRange(now),
      HistoryPeriodType.year => (
        DateTime(now.year, 1, 1),
        DateTime(now.year, 12, 31, 23, 59, 59),
      ),
      HistoryPeriodType.custom => (now, now), // Not really used for custom
    };
  }

  (DateTime startDate, DateTime endDate) nextRange(DateTime currentStart) {
    return switch (this) {
      HistoryPeriodType.day => (
        currentStart.addCalendarDays(1),
        currentStart.addCalendarDays(1).add(
          const Duration(hours: 23, minutes: 59, seconds: 59),
        ),
      ),
      HistoryPeriodType.month => (
        DateTime(currentStart.year, currentStart.month + 1, 1),
        DateTime(currentStart.year, currentStart.month + 2, 0, 23, 59, 59),
      ),
      HistoryPeriodType.quarter => _getQuarterRange(
        DateTime(currentStart.year, currentStart.month + 3, 1),
      ),
      HistoryPeriodType.semester => _getSemesterRange(
        DateTime(currentStart.year, currentStart.month + 6, 1),
      ),
      HistoryPeriodType.year => (
        DateTime(currentStart.year + 1, 1, 1),
        DateTime(currentStart.year + 1, 12, 31, 23, 59, 59),
      ),
      HistoryPeriodType.custom => (currentStart, currentStart),
    };
  }

  (DateTime startDate, DateTime endDate) previousRange(DateTime currentStart) {
    return switch (this) {
      HistoryPeriodType.day => (
        currentStart.addCalendarDays(-1),
        currentStart.subtract(const Duration(seconds: 1)),
      ),
      HistoryPeriodType.month => (
        DateTime(currentStart.year, currentStart.month - 1, 1),
        DateTime(currentStart.year, currentStart.month, 0, 23, 59, 59),
      ),
      HistoryPeriodType.quarter => _getQuarterRange(
        DateTime(currentStart.year, currentStart.month - 3, 1),
      ),
      HistoryPeriodType.semester => _getSemesterRange(
        DateTime(currentStart.year, currentStart.month - 6, 1),
      ),
      HistoryPeriodType.year => (
        DateTime(currentStart.year - 1, 1, 1),
        DateTime(currentStart.year - 1, 12, 31, 23, 59, 59),
      ),
      HistoryPeriodType.custom => (currentStart, currentStart),
    };
  }

  static (DateTime, DateTime) _getQuarterRange(DateTime now) {
    final quarter = ((now.month - 1) / 3).floor();
    final startMonth = quarter * 3 + 1;
    final endMonth = startMonth + 2;
    return (
      DateTime(now.year, startMonth, 1),
      DateTime(now.year, endMonth + 1, 0, 23, 59, 59),
    );
  }

  static (DateTime, DateTime) _getSemesterRange(DateTime now) {
    final semester = now.month <= 6 ? 0 : 1;
    final startMonth = semester * 6 + 1;
    final endMonth = startMonth + 5;
    return (
      DateTime(now.year, startMonth, 1),
      DateTime(now.year, endMonth + 1, 0, 23, 59, 59),
    );
  }
}

class HistoryPeriodFilter extends StatelessWidget {
  final HistoryPeriodType selectedType;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(HistoryPeriodType type, DateTime? start, DateTime? end)
  onSelected;

  const HistoryPeriodFilter({
    super.key,
    required this.selectedType,
    this.startDate,
    this.endDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final String dateRangeLabel;
    if (startDate != null && endDate != null) {
      if (selectedType == HistoryPeriodType.day) {
        dateRangeLabel = DateFormat.yMd().format(startDate!);
      } else {
        dateRangeLabel =
            '${DateFormat.yMd().format(startDate!)} - ${DateFormat.yMd().format(endDate!)}';
      }
    } else {
      dateRangeLabel = '';
    }

    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedType != HistoryPeriodType.custom) ...[
            FilledButton(
              onPressed: () {
                if (startDate != null) {
                  final range = selectedType.previousRange(startDate!);
                  onSelected(selectedType, range.$1, range.$2);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: AppColors.deepTurquoise,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    topLeft: Radius.circular(12),
                  ),
                ),
              ),
              child: const Icon(Icons.chevron_left),
            ),
          ],
          Expanded(
            child: PopupMenuButton<HistoryPeriodType>(
              initialValue: selectedType,
              onSelected: (type) async {
                if (type == HistoryPeriodType.custom) {
                  final picked = await showDateRangePicker(
                    context: context,
                    initialDateRange: startDate != null && endDate != null
                        ? DateTimeRange(start: startDate!, end: endDate!)
                        : null,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    onSelected(
                      type,
                      picked.start,
                      DateTime(
                        picked.end.year,
                        picked.end.month,
                        picked.end.day,
                        23,
                        59,
                        59,
                      ),
                    );
                  }
                } else {
                  final range = type.getRange();
                  onSelected(type, range.$1, range.$2);
                }
              },
              itemBuilder: (context) => HistoryPeriodType.values
                  .map(
                    (type) => PopupMenuItem(
                  value: type,
                  child: Text(type.label(l10n)),
                ),
              )
                  .toList(),
              child: Container(
                decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedType.label(l10n),
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                        if (dateRangeLabel.isNotEmpty)
                          Text(
                            dateRangeLabel,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedType != HistoryPeriodType.custom) ...[
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                foregroundColor: AppColors.deepTurquoise,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              onPressed: () {
                if (startDate != null) {
                  final range = selectedType.nextRange(startDate!);
                  onSelected(selectedType, range.$1, range.$2);
                }
              },
              child: const Icon(Icons.chevron_right),
            ),
          ],
        ],
      ),
    );
  }
}
