import 'api_service.dart';
import '../models/message.dart';

class MessageService {
  static Future<List<Conversation>> listConversations() async {
    final res = await ApiService.get('messages/list.php');
    if (res['success'] != true) return [];
    return (res['conversations'] as List<dynamic>).map((c) => Conversation.fromJson(c)).toList();
  }

  static Future<List<ChatMessage>> getThread(int withUserId) async {
    final res = await ApiService.get('messages/list.php', query: {'with_user_id': '$withUserId'});
    if (res['success'] != true) return [];
    return (res['messages'] as List<dynamic>).map((m) => ChatMessage.fromJson(m)).toList();
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int receiverId,
    String? message,
    int? attachmentId,
  }) {
    return ApiService.post('messages/send.php', {
      'receiver_id': receiverId,
      'message': message,
      'attachment_id': attachmentId,
    });
  }
}

class NotificationService {
  static Future<Map<String, dynamic>> list() {
    return ApiService.get('notifications/list.php');
  }

  static Future<void> markRead({int? notificationId}) {
    return ApiService.post('notifications/mark_read.php', {
      if (notificationId != null) 'notification_id': notificationId,
    });
  }
}
