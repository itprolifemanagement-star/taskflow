import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_avatar.dart';
import 'create_task_screen.dart';

/// Read-only profile + progress view for a single user, opened from the
/// admin Users list. Built entirely from the fields `users/list.php`
/// already returns (total_tasks / completed_tasks per user) — no new
/// endpoint required. "Assign Task" reuses the existing Create Task flow
/// with this user preselected.
class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user['full_name'] ?? '';
    final email = user['email'] ?? '';
    final department = user['department'];
    final role = (user['role'] ?? 'user').toString();
    final status = (user['status'] ?? 'active').toString();
    final total = int.tryParse('${user['total_tasks'] ?? 0}') ?? 0;
    final completed = int.tryParse('${user['completed_tasks'] ?? 0}') ?? 0;
    final pct = total == 0 ? 0.0 : completed / total;
    final userId = int.tryParse('${user['id']}');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    name: name,
                    radius: 38,
                    background: Colors.white,
                    foreground: AppColors.primary,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (department != null && '$department'.isNotEmpty) _pillLight(department.toString()),
                      _pillLight(role[0].toUpperCase() + role.substring(1)),
                      _pillLight(status[0].toUpperCase() + status.substring(1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Task Progress', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          Text('$completed/$total completed', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: pct, minHeight: 10, backgroundColor: AppColors.border, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: userId == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => CreateTaskScreen(preselectedUserId: userId)),
                          ),
                  icon: const Icon(Icons.add_task_rounded, size: 19),
                  label: const Text('Assign a Task'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillLight(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );
}
