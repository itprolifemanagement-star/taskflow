class Subtask {
  final int id;
  final String title;
  bool isCompleted;

  Subtask({required this.id, required this.title, this.isCompleted = false});

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: int.parse(json['id'].toString()),
        title: json['title'] ?? '',
        isCompleted: json['is_completed'].toString() == '1',
      );
}

class TaskComment {
  final int id;
  final String comment;
  final String fullName;
  final String? profilePhoto;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.comment,
    required this.fullName,
    this.profilePhoto,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) => TaskComment(
        id: int.parse(json['id'].toString()),
        comment: json['comment'] ?? '',
        fullName: json['full_name'] ?? '',
        profilePhoto: json['profile_photo'],
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}

class TaskAttachment {
  final int id;
  final String fileName;
  final String filePath;
  final String? fileType;

  TaskAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileType,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        id: int.parse(json['id'].toString()),
        fileName: json['file_name'] ?? '',
        filePath: json['file_path'] ?? '',
        fileType: json['file_type'],
      );
}

class Assignee {
  final int id;
  final String fullName;
  final String? profilePhoto;

  Assignee({required this.id, required this.fullName, this.profilePhoto});

  factory Assignee.fromJson(Map<String, dynamic> json) => Assignee(
        id: int.parse(json['id'].toString()),
        fullName: json['full_name'] ?? '',
        profilePhoto: json['profile_photo'],
      );
}

class TaskItem {
  final int id;
  final String title;
  final String? description;
  final String priority; // Low | Medium | High | Urgent
  final String status; // Pending | In Progress | Completed | Overdue
  final int progress;
  final DateTime? dueDate;
  final String? categoryName;
  final String? categoryColor;
  final List<Assignee> assignees;
  List<Subtask> subtasks;
  List<TaskComment> comments;
  List<TaskAttachment> attachments;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.progress,
    this.dueDate,
    this.categoryName,
    this.categoryColor,
    this.assignees = const [],
    this.subtasks = const [],
    this.comments = const [],
    this.attachments = const [],
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      description: json['description'],
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      progress: int.tryParse(json['progress'].toString()) ?? 0,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      categoryName: json['category_name'],
      categoryColor: json['category_color'],
      assignees: (json['assignees'] as List<dynamic>? ?? [])
          .map((e) => Assignee.fromJson(e))
          .toList(),
      subtasks: (json['subtasks'] as List<dynamic>? ?? [])
          .map((e) => Subtask.fromJson(e))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => TaskComment.fromJson(e))
          .toList(),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => TaskAttachment.fromJson(e))
          .toList(),
    );
  }
}
