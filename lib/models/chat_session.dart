import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final int messageCount;

  ChatSession({
    String? id,
    required this.title,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.messages = const [],
    this.messageCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ChatSession copyWith({
    String? title,
    bool? isPinned,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    int? messageCount,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'is_pinned': isPinned ? 1 : 0,
        'messages': jsonEncode(messages.map((m) => m.toJson()).toList()),
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ChatSession.fromMap(Map<String, dynamic> map,
      {bool loadMessages = false}) {
    List<ChatMessage> messages = [];
    int messageCount = 0;

    if (loadMessages && map['messages'] != null) {
      final list = jsonDecode(map['messages'] as String) as List<dynamic>;
      messages =
          list.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
      messageCount = messages.length;
    } else if (map['message_count'] != null) {
      messageCount = map['message_count'] as int;
    }

    return ChatSession(
      id: map['id'] as String,
      title: map['title'] as String,
      isPinned: (map['is_pinned'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      messages: messages,
      messageCount: messageCount,
    );
  }
}
