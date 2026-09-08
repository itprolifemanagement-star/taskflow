import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single quick-stat shown inside a [GradientProgressCard]'s stats bar,
/// e.g. ("12", "Tasks").
class ProgressStat {
  final String value;
  final String label;
  const ProgressStat(this.value, this.label);
}

/// The purple gradient hero card used at the top of the user and admin
/// dashboards. Shows a greeting/headline, an optional completion ring, and
/// an optional row of quick stats sitting in a soft bar at the base —
/// mirrors the "Today's Progress" hero from the reference design.
class GradientProgressCard extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String subtitle;
  final double? percent;
  final List<ProgressStat> stats;

  const GradientProgressCard({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    this.percent,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 22, 22, stats.isEmpty ? 22 : 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x33625BF6), blurRadius: 24, offset: Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      headline,
                      style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, height: 1.15),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  ],
                ),
              ),
              if (percent != null) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: percent!.clamp(0, 1),
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                      Text(
                        '${(percent! * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i != 0) Container(width: 1, height: 30, color: Colors.white24),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[i].value,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stats[i].label,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
