import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../widgets/status_donut.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _byUser = [];
  List<dynamic> _byCategory = [];
  final _userFilterController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userFilterController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await TaskService.dashboardStats();
    if (res['success'] == true) {
      _stats = res['stats'];
      _byUser = res['progress_by_user'] ?? [];
      _byCategory = res['progress_by_category'] ?? [];
    }
    setState(() => _loading = false);
  }

  List<dynamic> get _filteredByUser {
    final q = _userFilterController.text.trim().toLowerCase();
    if (q.isEmpty) return _byUser;
    return _byUser.where((u) => '${u['full_name'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final total = int.tryParse('${_stats?['total'] ?? 0}') ?? 0;
    final completed = int.tryParse('${_stats?['completed'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_stats?['in_progress'] ?? 0}') ?? 0;
    final pending = int.tryParse('${_stats?['pending'] ?? 0}') ?? 0;
    final overdue = int.tryParse('${_stats?['overdue'] ?? 0}') ?? 0;
    final completionPct = total == 0 ? 0 : (completed / total * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
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
              child: StatusDonut(
                centerValue: '$completionPct%',
                centerLabel: 'Completion',
                slices: [
                  DonutSlice('Completed', completed.toDouble(), AppColors.success),
                  DonutSlice('In Progress', inProgress.toDouble(), AppColors.info),
                  DonutSlice('Pending', pending.toDouble(), AppColors.warning),
                  DonutSlice('Overdue', overdue.toDouble(), AppColors.danger),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress by User', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                Text('${_byUser.length} people', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            if (_byUser.length > 4)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _userFilterController,
                  decoration: const InputDecoration(hintText: 'Filter by user name', prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            if (_filteredByUser.isEmpty)
              const Text('No matching users.', style: TextStyle(color: AppColors.textSecondary))
            else
              ..._filteredByUser.map((u) {
                final t = int.tryParse('${u['total']}') ?? 0;
                final c = int.tryParse('${u['completed']}') ?? 0;
                final pct = t == 0 ? 0.0 : c / t;
                return _progressRow(u['full_name'] ?? '', c, t, pct, AppColors.primary);
              }),
            const SizedBox(height: 20),
            const Text('Progress by Category', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            if (_byCategory.isEmpty)
              const Text('No categorized tasks yet.', style: TextStyle(color: AppColors.textSecondary))
            else
              ..._byCategory.map((c) {
                final t = int.tryParse('${c['total']}') ?? 0;
                final done = int.tryParse('${c['completed']}') ?? 0;
                final pct = t == 0 ? 0.0 : done / t;
                return _progressRow(c['name'] ?? '', done, t, pct, AppColors.info);
              }),
          ],
        ),
      ),
    );
  }

  Widget _progressRow(String label, int done, int total, double pct, Color color) {
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              Text('$done/$total', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.border, color: color),
          ),
        ],
      ),
    );
  }
}
