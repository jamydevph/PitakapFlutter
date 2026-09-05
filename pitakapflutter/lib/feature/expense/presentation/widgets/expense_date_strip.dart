import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pitakapflutter/core/theme/app_theme.dart';
import 'package:pitakapflutter/core/utils/date_utils.dart';

const int dateStripDayCount = 7;

List<DateTime> dateStripDays({
  required DateTime selectedDay,
  required DateTime today,
  int dayCount = dateStripDayCount,
}) {
  final selected = startOfDay(selectedDay);
  final end = startOfDay(today);
  final windowStart = DateTime(end.year, end.month, end.day - (dayCount - 1));

  final anchor = selected.isBefore(windowStart) || selected.isAfter(end)
      ? selected
      : end;

  return [
    for (var offset = dayCount - 1; offset >= 0; offset--)
      DateTime(anchor.year, anchor.month, anchor.day - offset),
  ];
}

class ExpenseDateStrip extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  const ExpenseDateStrip({
    super.key,
    required this.selectedDay,
    required this.today,
    required this.onSelected,
  });

  static String weekdayInitial(DateTime day) {
    return DateFormat('E').format(day).characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final days = dateStripDays(selectedDay: selectedDay, today: today);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _DayChip(
                  day: day,
                  isSelected: isSameDay(day, selectedDay),
                  onTap: () => onSelected(day),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final background = isSelected ? colorScheme.primary : colorScheme.surface;
    final dayColor = isSelected ? colorScheme.onPrimary : colorScheme.onSurface;
    final initialColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ExpenseDateStrip.weekdayInitial(day),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: initialColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: dayColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
