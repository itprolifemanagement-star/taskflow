import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/gradient_progress_card.dart';
import '../../widgets/section_header.dart';
import '../user/task_details_screen.dart';
import '../shared/notifications_screen.dart';
import 'users_screen.dart';
import 'reports_screen.dart';
import 'activity_log_screen.dart';
import 'announcements_screen.dart';
import 'categories_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<TaskItem> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final statsRes = await TaskService.dashboardStats();
    final tasks = await TaskService.listTasks();
    if (!mounted) return;
    setState(() {
      _stats = statsRes['stats'];
      _recent = tasks.take(5).toList();
      _loading = false;
    });
  }

  int get _total => int.tryParse('${_stats?['total'] ?? 0}') ?? 0;
  int get _completed => int.tryParse('${_stats?['completed'] ?? 0}') ?? 0;
  int get _pending => int.tryParse('${_stats?['pending'] ?? 0}') ?? 0;

  double get _completionRate {
    if (_total == 0) return 0;
    return (_completed / _total).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                children: [
                  GradientProgressCard(
                    eyebrow: 'Good day, Admin 👋',
                    headline: 'Organization overview',
                    subtitle: 'Monitor tasks, people, and activity from one place.',
                    percent: _completionRate,
                    stats: [
                      ProgressStat('$_total', 'Total'),
                      ProgressStat('$_completed', 'Completed'),
                      ProgressStat('$_pending', 'Pending'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      StatCard(value: '$_total', label: 'Total Tasks', color: AppColors.primary, icon: Icons.assignment_rounded),
                      StatCard(value: '$_completed', label: 'Completed', color: AppColors.success, icon: Icons.check_circle_rounded),
                      StatCard(value: '${_stats?['in_progress'] ?? 0}', label: 'In Progress', color: AppColors.info, icon: Icons.timelapse_rounded),
                      StatCard(value: '$_pending', label: 'Pending', color: AppColors.warning, icon: Icons.schedule_rounded),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const SectionHeader(title: 'Administration'),
                  const SizedBox(height: 12),
                  _manageGrid(context),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent tasks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      Text('${_recent.length} shown', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_recent.isEmpty)
                    const Text('No recent tasks.', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ..._recent.map((t) => TaskCard(
                          task: t,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: t.id)))
                              .then((_) => _load()),
                        )),
                ],
              ),
      ),
    );
  }

  Widget _manageGrid(BuildContext context) {
    final items = [
      (Icons.people_alt_rounded, 'Users', const UsersScreen()),
      (Icons.bar_chart_rounded, 'Reports', const ReportsScreen()),
      (Icons.history_rounded, 'Activity Log', const ActivityLogScreen()),
      (Icons.campaign_rounded, 'Announcements', const AnnouncementsScreen()),
      (Icons.category_rounded, 'Categories', const CategoriesScreen()),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - 50) / 2,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.$3)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(11)),
                      child: Icon(item.$1, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
