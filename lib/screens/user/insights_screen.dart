import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../widgets/status_donut.dart';

/// Read-only progress view for the signed-in user, built entirely from the
/// same `tasks/dashboard_stats.php` response the Home dashboard already
/// uses (status totals + progress_by_category) — no new endpoints.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _byCategory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final res = await TaskService.dashboardStats();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _stats = res['stats'];
        _byCategory = res['progress_by_category'] ?? [];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  int _n(String key) => int.tryParse('${_stats?[key] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final total = _n('total');
    final completed = _n('completed');
    final inProgress = _n('in_progress');
    final pending = _n('pending');
    final overdue = _n('overdue');
    final completionPct = total == 0 ? 0 : (completed / total * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        const Text('Task Breakdown', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 18),
                        StatusDonut(
                          centerValue: '$completionPct%',
                          centerLabel: 'Completed',
                          slices: [
                            DonutSlice('Completed', completed.toDouble(), AppColors.success),
                            DonutSlice('In Progress', inProgress.toDouble(), AppColors.info),
                            DonutSlice('Pending', pending.toDouble(), AppColors.warning),
                            if (overdue > 0) DonutSlice('Overdue', overdue.toDouble(), AppColors.danger),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _miniStat('$total', 'Total Tasks')),
                      const SizedBox(width: 12),
                      Expanded(child: _miniStat('$completed', 'Completed')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Progress by Category', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_byCategory.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'No categorized tasks yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ..._byCategory.map((c) {
                      final t = int.tryParse('${c['total']}') ?? 0;
                      final done = int.tryParse('${c['completed']}') ?? 0;
                      final pct = t == 0 ? 0.0 : done / t;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(c['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                Text('$done/$t', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _miniStat(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
