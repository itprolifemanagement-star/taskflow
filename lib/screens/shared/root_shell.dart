import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_provider.dart';
import '../user/dashboard_screen.dart';
import '../user/my_tasks_screen.dart';
import '../shared/messages_screen.dart';
import '../shared/profile_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/create_task_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final pages = [
      isAdmin ? const AdminDashboardScreen() : const DashboardScreen(),
      const MyTasksScreen(),
      const SizedBox.shrink(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_task_fab',
        elevation: 3,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => isAdmin
                  ? const CreateTaskScreen()
                  : const CreateTaskScreen(personalNote: true),
            ),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0x1A171722), blurRadius: 28, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0)),
              Expanded(child: _navItem(Icons.checklist_outlined, Icons.checklist_rounded, 'Tasks', 1)),
              const SizedBox(width: 56),
              Expanded(child: _navItem(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages', 3)),
              Expanded(child: _navItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int idx) {
    final selected = _index == idx;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => _index = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 21),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
