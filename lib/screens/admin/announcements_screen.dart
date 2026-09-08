import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/empty_state.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('announcements/index.php');
    if (res['success'] == true) {
      _announcements = List<Map<String, dynamic>>.from(res['announcements']);
    }
    setState(() => _loading = false);
  }

  Future<void> _createAnnouncement() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: bodyController, maxLines: 3, decoration: const InputDecoration(hintText: 'Message')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Post')),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      await ApiService.post('announcements/index.php', {
        'title': titleController.text.trim(),
        'body': bodyController.text.trim(),
      });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton(onPressed: _createAnnouncement, child: const Icon(Icons.add_rounded)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(
                        icon: Icons.campaign_rounded,
                        title: 'No announcements yet',
                        subtitle: 'Tap + to post one to the whole team.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                    itemCount: _announcements.length,
                    itemBuilder: (context, i) {
                      final a = _announcements[i];
                      final createdAt = DateTime.tryParse(a['created_at'] ?? '');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(11)),
                                  child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(a['body'] ?? '', style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                            const SizedBox(height: 10),
                            Text(
                              'By ${a['author_name']}${createdAt != null ? ' • ${timeago.format(createdAt, locale: 'en_short')}' : ''}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
