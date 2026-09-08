import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../services/auth_provider.dart';
import '../../models/task.dart';
import '../../widgets/app_avatar.dart';
import '../admin/create_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  TaskItem? _task;
  bool _loading = true;
  final _commentController = TextEditingController();
  bool _postingComment = false;
  double? _progressDraft;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final task = await TaskService.getTaskDetails(widget.taskId);
    if (!mounted) return;
    setState(() {
      _task = task;
      _loading = false;
      _progressDraft = task?.progress.toDouble();
    });
  }

  Future<void> _toggleSubtask(Subtask subtask, bool value) async {
    final res = await TaskService.updateTask(widget.taskId, subtaskId: subtask.id, isSubtaskCompleted: value);
    if (!mounted) return;
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to update subtask')),
      );
      return;
    }
    _load();
  }

  Future<void> _updateProgress(int value) async {
    final res = await TaskService.updateTask(widget.taskId, progress: value);
    if (!mounted) return;
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to update progress')),
      );
      return;
    }
    setState(() => _progressDraft = value.toDouble());
    _load();
  }

  Future<void> _updateStatus(String status) async {
    final res = await TaskService.updateTask(widget.taskId, status: status);
    if (!mounted) return;
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to update status')),
      );
      return;
    }
    _load();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _postingComment = true);
    final res = await TaskService.addComment(widget.taskId, text);
    if (!mounted) return;
    setState(() => _postingComment = false);
    if (res['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to post comment')),
      );
      return;
    }
    _commentController.clear();
    _load();
  }

  Future<void> _attachFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await TaskService.uploadAttachment(File(picked.path), taskId: widget.taskId);
    _load();
  }

  Future<void> _editTask() async {
    if (_task == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateTaskScreen(editingTask: _task)),
    );
    if (updated == true) _load();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete task'),
        content: const Text('This permanently removes the task for everyone assigned to it. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await TaskService.deleteTask(widget.taskId);
    if (!mounted) return;
    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Unable to delete task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_task == null) {
      return const Scaffold(body: Center(child: Text('Task not found')));
    }

    final task = _task!;
    final statusColor = AppColors.statusColor(task.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: isAdmin
            ? [
                IconButton(
                  tooltip: 'Edit task',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _editTask,
                ),
                IconButton(
                  tooltip: 'Delete task',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                  onPressed: _deleteTask,
                ),
                const SizedBox(width: 4),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.25)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(task.priority, AppColors.priorityColor(task.priority)),
                      _chip(task.status, statusColor),
                      if (task.categoryName != null)
                        _chip(task.categoryName!, AppColors.fromHex(task.categoryColor, fallback: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            if (task.description != null && task.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Description'),
                    const SizedBox(height: 8),
                    Text(task.description!, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (task.dueDate != null)
                  Expanded(
                    child: _infoTile(
                      icon: Icons.event_rounded,
                      label: 'Due Date',
                      value: DateFormat('MMM d, yyyy').format(task.dueDate!),
                    ),
                  ),
                if (task.dueDate != null) const SizedBox(width: 12),
                Expanded(
                  child: _infoTile(
                    icon: Icons.flag_rounded,
                    label: 'Priority',
                    value: task.priority,
                    valueColor: AppColors.priorityColor(task.priority),
                  ),
                ),
              ],
            ),
            if (task.assignees.isNotEmpty) ...[
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Assigned To'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: task.assignees
                          .map((a) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppAvatar(name: a.fullName, radius: 18),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.fullName.split(' ').first,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Progress'),
                      Text('${task.progress}%', style: TextStyle(fontWeight: FontWeight.w900, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: task.progress / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.border,
                      color: statusColor,
                    ),
                  ),
                  if (!isAdmin)
                    Slider(
                      value: (_progressDraft ?? task.progress.toDouble()).clamp(0, 100),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      label: '${task.progress}%',
                      onChanged: (v) => setState(() => _progressDraft = v),
                      onChangeEnd: (v) => _updateProgress(v.round()),
                    )
                  else
                    const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Pending', 'In Progress', 'Completed'].map((s) {
                      final selected = task.status == s;
                      return ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        selectedColor: AppColors.statusColor(s),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: selected ? AppColors.statusColor(s) : AppColors.border),
                        onSelected: (_) => _updateStatus(s),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (task.subtasks.isNotEmpty) ...[
              const SizedBox(height: 14),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Subtasks'),
                    const SizedBox(height: 4),
                    ...task.subtasks.map((s) => CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: s.isCompleted,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          title: Text(
                            s.title,
                            style: TextStyle(
                              decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                              color: s.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onChanged: (v) => _toggleSubtask(s, v ?? false),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Attachments'),
                      TextButton.icon(
                        onPressed: _attachFile,
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (task.attachments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('No attachments yet', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  else
                    ...task.attachments.map((a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 19),
                          ),
                          title: Text(a.fileName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Comments'),
                  const SizedBox(height: 10),
                  if (task.comments.isEmpty)
                    const Text('No comments yet.', style: TextStyle(color: AppColors.textSecondary))
                  else
                    ...task.comments.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppAvatar(name: c.fullName, radius: 15),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text(c.comment, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(hintText: 'Add a comment...'),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: IconButton(
                          onPressed: _postingComment ? null : _postComment,
                          icon: _postingComment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 19),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.cardShadow,
        ),
        child: child,
      );

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14));

  Widget _infoTile({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Container(
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
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: valueColor ?? AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      );
}
