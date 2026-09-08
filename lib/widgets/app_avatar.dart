import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable initials avatar so avatars look identical wherever they show
/// up: the dashboard greeting, the profile header, assignee chips, and
/// comment threads.
class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color background;
  final Color foreground;
  final BoxBorder? border;

  const AppAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.background = AppColors.primaryLight,
    this.foreground = AppColors.primary,
    this.border,
  });

  String get _initial {
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      padding: border != null ? const EdgeInsets.all(3) : EdgeInsets.zero,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: background,
        child: Text(
          _initial,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }
}
