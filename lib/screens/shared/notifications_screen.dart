import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../services/message_service.dart';
import '../../models/message.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await NotificationService.list();
    if (res['success'] == true) {
      _notifications = (res['notifications'] as List<dynamic>).map((n) => AppNotification.fromJson(n)).toList();
    }
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    await NotificationService.markRead();
    _load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_rounded;
      case 'task_completed':
        return Icons.check_circle_rounded;
      case 'task_updated':
        return Icons.update_rounded;
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'comment':
        return Icons.comment_rounded;
      case 'deadline':
        return Icons.alarm_rounded;
      case 'overdue':
        return Icons.warning_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'task_completed':
        return AppColors.success;
      case 'overdue':
        return AppColors.danger;
      case 'deadline':
        return AppColors.warning;
      case 'new_message':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet'),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) {
                      final n = _notifications[i];
                      final color = _colorFor(n.type);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: n.isRead ? AppColors.surface : AppColors.primaryLight.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await NotificationService.markRead(notificationId: n.id);
                              _load();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(_iconFor(n.type), color: color, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                        if (n.body != null && n.body!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(n.body!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        timeago.format(n.createdAt, locale: 'en_short'),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      if (!n.isRead) ...[
                                        const SizedBox(height: 6),
                                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
