import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/task_service.dart';
import '../../widgets/empty_state.dart';
import 'my_tasks_screen.dart';

/// Read-only categories browser for regular users — reuses the same
/// `categories/index.php` endpoint the admin Categories screen already
/// calls. Tapping a category opens My Tasks pre-filtered to it.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  static const _palette = [
    AppColors.primary,
    AppColors.info,
    AppColors.success,
    AppColors.warning,
    Color(0xFFEA580C),
    AppColors.danger,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final categories = await TaskService.listCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _loading = false;
    });
  }

  Color _colorFor(Map<String, dynamic> c, int index) {
    final fromApi = c['color'];
    if (fromApi is String && fromApi.isNotEmpty) {
      return AppColors.fromHex(fromApi, fallback: _palette[index % _palette.length]);
    }
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(
                        icon: Icons.category_rounded,
                        title: 'No categories yet',
                        subtitle: 'Categories created by your admin will show up here.',
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      final color = _colorFor(c, i);
                      final count = int.tryParse('${c['task_count'] ?? 0}') ?? 0;
                      final name = c['name'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => MyTasksScreen(initialCategory: name)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: color.withOpacity(.13), borderRadius: BorderRadius.circular(14)),
                                    child: Icon(Icons.label_rounded, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                                  ),
                                  Text('$count tasks', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
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
