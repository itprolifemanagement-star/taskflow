import 'dart:io';
import 'api_service.dart';
import '../models/task.dart';

class TaskService {
  static Future<List<TaskItem>> listTasks({String? status, String? search}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final res = await ApiService.get('tasks/list.php', query: query);
    if (res['success'] != true) return [];
    return (res['tasks'] as List<dynamic>).map((t) => TaskItem.fromJson(t)).toList();
  }

  static Future<TaskItem?> getTaskDetails(int taskId) async {
    final res = await ApiService.get('tasks/details.php', query: {'id': '$taskId'});
    if (res['success'] != true || res['task'] == null) return null;
    return TaskItem.fromJson(res['task']);
  }

  static Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    int? categoryId,
    required String priority,
    String? dueDate,
    String? reminderAt,
    List<int> assigneeIds = const [],
    List<String> subtasks = const [],
  }) {
    return ApiService.post('tasks/create.php', {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'priority': priority,
      'due_date': dueDate,
      'reminder_at': reminderAt,
      'assignee_ids': assigneeIds,
      'subtasks': subtasks,
    });
  }

  static Future<Map<String, dynamic>> updateTask(
    int taskId, {
    int? progress,
    String? status,
    int? subtaskId,
    bool? isSubtaskCompleted,
    Map<String, dynamic>? adminFields,
  }) {
    final body = <String, dynamic>{'task_id': taskId};
    if (progress != null) body['progress'] = progress;
    if (status != null) body['status'] = status;
    if (subtaskId != null) {
      body['subtask_id'] = subtaskId;
      body['is_completed'] = isSubtaskCompleted ?? false;
    }
    if (adminFields != null) body.addAll(adminFields);
    return ApiService.post('tasks/update.php', body);
  }

  static Future<Map<String, dynamic>> addComment(int taskId, String comment) {
    return ApiService.post('tasks/add_comment.php', {'task_id': taskId, 'comment': comment});
  }

  static Future<Map<String, dynamic>> uploadAttachment(File file, {int? taskId}) {
    return ApiService.uploadFile(
      'tasks/upload_attachment.php',
      file,
      fields: taskId != null ? {'task_id': '$taskId'} : {},
    );
  }

  static Future<Map<String, dynamic>> dashboardStats() {
    return ApiService.get('tasks/dashboard_stats.php');
  }

  /// Deletes a task. Assumes a `tasks/delete.php` endpoint following the
  /// same REST-style naming as the rest of this API (list/details/create/
  /// update). Add that endpoint on the backend if it doesn't exist yet —
  /// everything on the Flutter side is already wired to call it.
  static Future<Map<String, dynamic>> deleteTask(int taskId) {
    return ApiService.post('tasks/delete.php', {'task_id': taskId});
  }

  /// Categories are already used by the admin Categories screen via
  /// `categories/index.php`; centralizing the read here lets Create/Edit
  /// Task and the user-facing Categories screen reuse the same call.
  static Future<List<Map<String, dynamic>>> listCategories() async {
    final res = await ApiService.get('categories/index.php');
    if (res['success'] != true || res['categories'] == null) return [];
    return List<Map<String, dynamic>>.from(res['categories']);
  }
}
