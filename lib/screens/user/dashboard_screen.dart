import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';
import '../../widgets/gradient_progress_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/app_avatar.dart';
import 'task_details_screen.dart';
import 'my_tasks_screen.dart';
import 'insights_screen.dart';
import 'categories_screen.dart';
import '../shared/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  List<TaskItem> _upcoming = [];
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
        _upcoming = (res['upcoming_tasks'] as List<dynamic>? ?? [])
            .map((t) => TaskItem.fromJson(t))
            .toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.fullName.split(' ').first ?? 'there';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  children: [
                    Row(
                      children: [
                        AppAvatar(name: user?.fullName ?? '?', radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, $firstName 👋', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 2),
                              const Text("Let's plan your day.", style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          icon: const Icon(Icons.notifications_none_rounded),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GradientProgressCard(
                      eyebrow: 'Today\'s Progress',
                      headline: '${(_completionRate * 100).round()}% complete',
                      subtitle: 'You\'ve completed $_completed of $_total tasks.',
                      percent: _completionRate,
                      stats: [
                        ProgressStat('$_total', 'Tasks'),
                        ProgressStat('$_completed', 'Completed'),
                        ProgressStat('$_pending', 'Pending'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _quickAction(
                            icon: Icons.insights_rounded,
                            label: 'Insights',
                            color: AppColors.info,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const InsightsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.category_rounded,
                            label: 'Categories',
                            color: AppColors.warning,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            icon: Icons.calendar_month_rounded,
                            label: 'Calendar',
                            color: AppColors.success,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MyTasksScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SectionHeader(
                      title: 'Upcoming Tasks',
                      actionLabel: 'See all',
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyTasksScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_upcoming.isEmpty)
                      _emptyState()
                    else
                      ..._upcoming.map((t) => TaskCard(
                            task: t,
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: t.id)))
                                .then((_) => _load()),
                          )),
                  ],
                ),
        ),
      ),
    );
  }

  int get _total => int.tryParse('${_stats?['total'] ?? 0}') ?? 0;
  int get _completed => int.tryParse('${_stats?['completed'] ?? 0}') ?? 0;
  int get _pending => int.tryParse('${_stats?['pending'] ?? 0}') ?? 0;

  double get _completionRate {
    if (_total == 0) return 0;
    return (_completed / _total).clamp(0, 1);
  }

  Widget _quickAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.task_alt_rounded, size: 38, color: AppColors.success),
            SizedBox(height: 10),
            Text('You’re all caught up', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text('No upcoming deadlines right now.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          ],
        ),
      );
}
