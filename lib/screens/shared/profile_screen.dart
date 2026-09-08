import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/app_avatar.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Reuses the same dashboard_stats.php endpoint the dashboard already
  // calls, so the profile header can show a quick Total/Completed summary
  // like the reference design — no new backend endpoint required.
  Future<void> _loadStats() async {
    final res = await TaskService.dashboardStats();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() => _stats = res['stats']);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await AuthService.logout();
    if (!context.mounted) return;
    await context.read<AuthProvider>().clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    name: user?.fullName ?? '?',
                    radius: 42,
                    background: Colors.white,
                    foreground: AppColors.primary,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                  if (user?.department != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user!.isAdmin ? 'Admin • ${user.department}' : user.department!,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  if (_stats != null) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _statColumn('${_stats?['total'] ?? 0}', 'Total Tasks')),
                          Container(width: 1, height: 30, color: Colors.white24),
                          Expanded(child: _statColumn('${_stats?['completed'] ?? 0}', 'Completed')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionLabel('Account'),
                _MenuCard(
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                  iconColor: AppColors.primary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _MenuCard(
                  icon: Icons.lock_outline_rounded,
                  label: 'Change Password',
                  iconColor: AppColors.info,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Preferences'),
                _MenuCard(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notification Settings',
                  iconColor: AppColors.warning,
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                ),
                const SizedBox(height: 20),
                _MenuCard(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  iconColor: AppColors.danger,
                  labelColor: AppColors.danger,
                  onTap: () => _logout(context),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
