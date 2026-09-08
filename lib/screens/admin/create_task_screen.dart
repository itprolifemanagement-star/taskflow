import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';

class CreateTaskScreen extends StatefulWidget {
  /// When true, this is a user creating a personal note/task for themself
  /// rather than an admin assigning work to others.
  final bool personalNote;

  /// When set, the screen opens in edit mode for this existing task instead
  /// of creating a new one.
  final TaskItem? editingTask;

  /// Optional assignee to preselect, e.g. when opened from a user's profile
  /// in the admin Users screen ("Assign Task").
  final int? preselectedUserId;

  const CreateTaskScreen({
    super.key,
    this.personalNote = false,
    this.editingTask,
    this.preselectedUserId,
  });

  bool get isEditing => editingTask != null;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late final _title = TextEditingController(text: widget.editingTask?.title ?? '');
  late final _description = TextEditingController(text: widget.editingTask?.description ?? '');
  final _subtaskController = TextEditingController();
  late String _priority = widget.editingTask?.priority ?? 'Medium';
  DateTime? _dueDate;
  int? _reminderMinutesBefore;
  int? _categoryId;
  final List<String> _newSubtasks = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _categories = [];
  final Set<int> _selectedUserIds = {};
  bool _loading = false;
  bool _loadingUsers = true;
  bool _loadingCategories = true;

  static const _reminderOptions = <int?, String>{
    null: 'No reminder',
    15: '15 minutes before',
    30: '30 minutes before',
    60: '1 hour before',
    1440: '1 day before',
  };

  @override
  void initState() {
    super.initState();
    _dueDate = widget.editingTask?.dueDate;
    if (widget.preselectedUserId != null) _selectedUserIds.add(widget.preselectedUserId!);
    if (!widget.personalNote) _loadUsers();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final res = await ApiService.get('users/list.php');
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _users = List<Map<String, dynamic>>.from(res['users']);
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
    }
  }

  Future<void> _loadCategories() async {
    final categories = await TaskService.listCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loadingCategories = false;
      final existingName = widget.editingTask?.categoryName;
      if (existingName != null) {
        final match = categories.where((c) => c['name'] == existingName);
        if (match.isNotEmpty) _categoryId = int.tryParse('${match.first['id']}');
      }
    });
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null ? TimeOfDay.fromDateTime(_dueDate!) : TimeOfDay.now(),
    );
    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time?.hour ?? 17, time?.minute ?? 0);
    });
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _newSubtasks.add(text);
      _subtaskController.clear();
    });
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    if (!widget.personalNote && !widget.isEditing && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assign to at least one user')));
      return;
    }

    setState(() => _loading = true);

    Map<String, dynamic> res;
    if (widget.isEditing) {
      res = await TaskService.updateTask(
        widget.editingTask!.id,
        adminFields: {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          'priority': _priority,
          'due_date': _dueDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_dueDate!) : null,
          'category_id': _categoryId,
        },
      );
    } else {
      final reminderAt = (_dueDate != null && _reminderMinutesBefore != null)
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_dueDate!.subtract(Duration(minutes: _reminderMinutesBefore!)))
          : null;
      res = await TaskService.createTask(
        title: _title.text.trim(),
        description: _description.text.trim(),
        categoryId: _categoryId,
        priority: _priority,
        dueDate: _dueDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(_dueDate!) : null,
        reminderAt: reminderAt,
        assigneeIds: _selectedUserIds.toList(),
        subtasks: _newSubtasks,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? (widget.isEditing ? 'Failed to update task' : 'Failed to create task'))),
      );
    }
  }

  String get _screenTitle {
    if (widget.isEditing) return 'Edit Task';
    return widget.personalNote ? 'New Note' : 'New Task';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Task Title'),
                  TextField(controller: _title, decoration: const InputDecoration(hintText: 'e.g. Prepare monthly report')),
                  const SizedBox(height: 16),
                  _label('Description'),
                  TextField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Add details...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Due Date'),
                  InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.event_rounded)),
                      child: Text(
                        _dueDate == null ? 'Select date & time' : DateFormat('MMM d, yyyy • h:mm a').format(_dueDate!),
                        style: TextStyle(color: _dueDate == null ? AppColors.textSecondary : AppColors.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 16),
                    _label('Reminder'),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _dueDate == null
                          ? () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Pick a due date first')))
                          : () async {
                              final choice = await showModalBottomSheet<int>(
                                context: context,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _reminderOptions.entries
                                        .map((e) => ListTile(
                                              title: Text(e.value),
                                              trailing: _reminderMinutesBefore == e.key ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                                              // -1 is a sentinel for "No reminder" so it stays
                                              // distinguishable from the sheet being dismissed
                                              // (which also resolves the future with null).
                                              onTap: () => Navigator.pop(ctx, e.key ?? -1),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              );
                              if (choice == null) return; // dismissed without choosing — keep current value
                              setState(() => _reminderMinutesBefore = choice == -1 ? null : choice);
                            },
                      child: InputDecorator(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.alarm_rounded)),
                        child: Text(
                          _reminderOptions[_reminderMinutesBefore]!,
                          style: TextStyle(color: _reminderMinutesBefore == null ? AppColors.textSecondary : AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _label('Priority'),
                  Wrap(
                    spacing: 8,
                    children: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                      final selected = _priority == p;
                      return ChoiceChip(
                        label: Text(p),
                        selected: selected,
                        selectedColor: AppColors.priorityColor(p),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12.5),
                        side: BorderSide(color: selected ? AppColors.priorityColor(p) : AppColors.border),
                        onSelected: (_) => setState(() => _priority = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _label('Category'),
                  _loadingCategories
                      ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                      : _categories.isEmpty
                          ? const Text('No categories yet.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5))
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((c) {
                                final id = int.tryParse('${c['id']}');
                                final selected = _categoryId == id;
                                return ChoiceChip(
                                  label: Text(c['name'] ?? ''),
                                  selected: selected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: AppColors.background,
                                  labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                                  onSelected: (_) => setState(() => _categoryId = selected ? null : id),
                                );
                              }).toList(),
                            ),
                ],
              ),
            ),
            if (!widget.personalNote && !widget.isEditing) ...[
              const SizedBox(height: 14),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Assign To'),
                    _loadingUsers
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator())
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _users.map((u) {
                              final id = int.parse(u['id'].toString());
                              final selected = _selectedUserIds.contains(id);
                              return FilterChip(
                                label: Text(u['full_name']),
                                selected: selected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.background,
                                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5),
                                side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _selectedUserIds.add(id);
                                  } else {
                                    _selectedUserIds.remove(id);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ],
            if (!widget.isEditing) ...[
              const SizedBox(height: 14),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Subtasks'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            decoration: const InputDecoration(hintText: 'Add a subtask'),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        IconButton(onPressed: _addSubtask, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
                      ],
                    ),
                    ..._newSubtasks.asMap().entries.map((e) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_box_outline_blank_rounded, size: 18),
                          title: Text(e.value),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _newSubtasks.removeAt(e.key)),
                          ),
                        )),
                  ],
                ),
              ),
            ] else if ((widget.editingTask?.subtasks ?? []).isNotEmpty) ...[
              const SizedBox(height: 14),
              _sectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Subtasks'),
                    const SizedBox(height: 2),
                    const Text('Manage individual subtasks from the task\'s details screen.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...widget.editingTask!.subtasks.map((s) => Text('• ${s.title}', style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.isEditing ? 'Save Changes' : (widget.personalNote ? 'Create Note' : 'Create Task')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) => Container(
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

  Widget _label(String text) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)));
}
