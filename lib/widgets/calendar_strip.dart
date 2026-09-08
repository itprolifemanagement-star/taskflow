import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Horizontal scrollable day picker, echoing the reference app's calendar
/// strip. Tapping a day filters the task list to items due that day;
/// tapping the selected day again clears the filter. Purely a client-side
/// filter on top of the existing task list — no new endpoints involved.
class CalendarStrip extends StatelessWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onSelect;
  final int daysBefore;
  final int daysAfter;

  const CalendarStrip({
    super.key,
    required this.selected,
    required this.onSelect,
    this.daysBefore = 3,
    this.daysAfter = 11,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: daysBefore));
    final days = List.generate(daysBefore + daysAfter + 1, (i) => start.add(Duration(days: i)));
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected = selected != null &&
              selected!.year == day.year &&
              selected!.month == day.month &&
              selected!.day == day.day;
          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelect(isSelected ? null : day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayLabels[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : (isToday ? AppColors.primary : AppColors.textPrimary),
                    ),
                  ),
                  if (isToday && !isSelected) ...[
                    const SizedBox(height: 3),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
