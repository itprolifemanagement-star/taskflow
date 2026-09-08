import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import '../../widgets/task_card.dart';
import '../../widgets/calendar_strip.dart';
import '../../widgets/empty_state.dart';
import 'task_details_screen.dart';

class MyTasksScreen extends StatefulWidget {
  /// Optional category name to pre-filter to, e.g. when arriving from the
  /// Categories screen. Purely a client-side filter on top of the list the
  /// API already returns.
  final String? initialCategory;
  const MyTasksScreen({super.key, this.initialCategory});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final _tabs = ['All', 'Pending', 'In Progress', 'Completed'];
  final _searchController = TextEditingController();
  int _tabIndex = 0;
  DateTime? _selectedDate;
  String? _selectedCategory;
  List<TaskItem> _allTasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final status = _tabIndex == 0 ? null : _tabs[_tabIndex];
    final tasks = await TaskService.listTasks(status: status, search: _searchController.text.trim());
    if (!mounted) return;
    setState(() {
      _allTasks = tasks;
      _loading = false;
    });
  }

  // Distinct category names present in the currently-loaded list, so the
  // filter row only ever shows options that actually have tasks.
  List<String> get _availableCategories {
    final names = _allTasks.map((t) => t.categoryName).whereType<String>().toSet().toList();
    names.sort();
    return names;
  }

  // The calendar strip and category chips both filter client-side on top
  // of whatever the API already returned for the current search/status —
  // no extra requests.
  List<TaskItem> get _visibleTasks {
    return _allTasks.where((t) {
      if (_selectedDate != null) {
        final due = t.dueDate;
        if (due == null) return false;
        if (due.year != _selectedDate!.year || due.month != _selectedDate!.month || due.day != _selectedDate!.day) {
          return false;
        }
      }
      if (_selectedCategory != null && t.categoryName != _selectedCategory) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _visibleTasks;
    final categories = _availableCategories;

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          CalendarStrip(
            selected: _selectedDate,
            onSelect: (date) => setState(() => _selectedDate = date),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final selected = _tabIndex == i;
                return ChoiceChip(
                  label: Text(_tabs[i]),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  onSelected: (_) {
                    setState(() => _tabIndex = i);
                    _load();
                  },
                );
              },
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final name = categories[i];
                  final selected = _selectedCategory == name;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _selectedCategory = selected ? null : name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primaryLight : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No tasks found',
                              subtitle: _selectedDate != null
                                  ? 'Nothing due on ${DateFormat('MMM d').format(_selectedDate!)}.'
                                  : _selectedCategory != null
                                      ? 'No tasks in "$_selectedCategory" right now.'
                                      : 'Try another search or filter.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => TaskCard(
                            task: tasks[i],
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => TaskDetailsScreen(taskId: tasks[i].id)))
                                .then((_) => _load()),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
