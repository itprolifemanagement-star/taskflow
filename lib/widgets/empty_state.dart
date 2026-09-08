import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent "nothing here yet" placeholder reused across list screens
/// (messages, notifications, categories, users, activity log, etc.)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
