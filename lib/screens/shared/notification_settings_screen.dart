import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

/// Local notification preferences (stored on-device via SharedPreferences).
/// These control which push/in-app notification categories the user wants
/// to be alerted about. Wire this into your FCM payload filtering or
/// in-app notification list filtering as needed.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  final Map<String, bool> _prefs = {
    'task_assigned': true,
    'task_updates': true,
    'messages': true,
    'comments': true,
    'deadlines': true,
    'announcements': true,
  };

  final Map<String, _PrefMeta> _meta = {
    'task_assigned': _PrefMeta('New Task Assigned', Icons.assignment_rounded, AppColors.primary),
    'task_updates': _PrefMeta('Task Updates & Completion', Icons.update_rounded, AppColors.info),
    'messages': _PrefMeta('New Messages', Icons.chat_bubble_rounded, AppColors.success),
    'comments': _PrefMeta('Comments on Tasks', Icons.comment_rounded, AppColors.warning),
    'deadlines': _PrefMeta('Upcoming Deadlines', Icons.alarm_rounded, const Color(0xFFFB923C)),
    'announcements': _PrefMeta('Announcements', Icons.campaign_rounded, AppColors.danger),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (final key in _prefs.keys) {
        _prefs[key] = prefs.getBool('notif_$key') ?? true;
      }
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool value) async {
    setState(() => _prefs[key] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_$key', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Choose which alerts you'd like to receive.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ..._prefs.keys.map((key) {
                  final meta = _meta[key]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: meta.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 18),
                      ),
                      title: Text(meta.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      value: _prefs[key]!,
                      onChanged: (v) => _toggle(key, v),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _PrefMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _PrefMeta(this.label, this.icon, this.color);
}