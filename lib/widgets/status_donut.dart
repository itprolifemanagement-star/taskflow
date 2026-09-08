import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class DonutSlice {
  final String label;
  final double value;
  final Color color;
  const DonutSlice(this.label, this.value, this.color);
}

/// Shared donut chart + legend used by the Insights and Reports screens so
/// both read from the same visual language. Built on `fl_chart`, which is
/// already a dependency in this project (see the existing Reports screen).
class StatusDonut extends StatelessWidget {
  final List<DonutSlice> slices;
  final String centerLabel;
  final String centerValue;
  final double size;

  const StatusDonut({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
    this.size = 168,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Column(
      children: [
        SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: size * 0.32,
                  sections: total == 0
                      ? [PieChartSectionData(value: 1, color: AppColors.border, showTitle: false)]
                      : slices
                          .where((s) => s.value > 0)
                          .map((s) => PieChartSectionData(value: s.value, color: s.color, showTitle: false, radius: size * 0.18))
                          .toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerValue, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                  Text(centerLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: slices.map((s) => _legendItem(s)).toList(),
        ),
      ],
    );
  }

  Widget _legendItem(DonutSlice s) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('${s.label} (${s.value.toInt()})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );
}
