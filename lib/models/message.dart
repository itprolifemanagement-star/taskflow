class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String? message;
  final String? attachmentPath;
  final String? attachmentName;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.message,
    this.attachmentPath,
    this.attachmentName,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: int.parse(json['id'].toString()),
        senderId: int.parse(json['sender_id'].toString()),
        receiverId: int.parse(json['receiver_id'].toString()),
        message: json['message'],
        attachmentPath: json['attachment_path'],
        attachmentName: json['attachment_name'],
        isRead: json['is_read'].toString() == '1',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}

class Conversation {
  final int userId;
  final String fullName;
  final String? profilePhoto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.userId,
    required this.fullName,
    this.profilePhoto,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        userId: int.parse(json['user_id'].toString()),
        fullName: json['full_name'] ?? '',
        profilePhoto: json['profile_photo'],
        lastMessage: json['last_message'],
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'])
            : null,
        unreadCount: int.tryParse(json['unread_count'].toString()) ?? 0,
      );
}

class AppNotification {
  final int id;
  final String title;
  final String? body;
  final String type;
  final int? referenceId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: int.parse(json['id'].toString()),
        title: json['title'] ?? '',
        body: json['body'],
        type: json['type'] ?? '',
        referenceId:
            json['reference_id'] != null ? int.tryParse(json['reference_id'].toString()) : null,
        isRead: json['is_read'].toString() == '1',
        createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      );
}
