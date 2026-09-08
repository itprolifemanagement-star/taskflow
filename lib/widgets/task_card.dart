import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final bool showCheckbox;
  final ValueChanged<bool>? onCheckboxChanged;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.showCheckbox = false,
    this.onCheckboxChanged,
  });

  IconData get _statusIcon {
    switch (task.status) {
      case 'Completed':
        return Icons.check_rounded;
      case 'In Progress':
        return Icons.timelapse_rounded;
      case 'Overdue':
        return Icons.priority_high_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(task.status);
    final priorityColor = AppColors.priorityColor(task.priority);
    // Prefer the task's own category color for the leading badge (as the
    // API already provides it) so cards read as visually distinct by
    // category, the way the reference design does; fall back to priority.
    final accent = AppColors.fromHex(task.categoryColor, fallback: priorityColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCheckbox)
                  Padding(
                    padding: const EdgeInsets.only(right: 2, top: 2),
                    child: Checkbox(
                      value: task.status == 'Completed',
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      onChanged: (v) => onCheckboxChanged?.call(v ?? false),
                    ),
                  ),
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 13),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_statusIcon, color: accent, size: 21),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pill(task.status, statusColor),
                        ],
                      ),
                      if ((task.description ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d, yyyy').format(task.dueDate!),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                          ],
                          _pill(task.priority, priorityColor),
                          const Spacer(),
                          if (task.progress > 0)
                            Text('${task.progress}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (task.progress.clamp(0, 100)) / 100,
                          minHeight: 4,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
        ),
      );
}
