import 'package:uuid/uuid.dart';

enum ChatRole { user, assistant, toolCall, toolResult }

class ToolCallInfo {
  final String id;
  final String name;
  final String arguments;
  String? result;

  ToolCallInfo({
    required this.id,
    required this.name,
    required this.arguments,
    this.result,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'arguments': arguments,
        'result': result,
      };

  factory ToolCallInfo.fromJson(Map<String, dynamic> json) => ToolCallInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        arguments: json['arguments'] as String,
        result: json['result'] as String?,
      );
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final List<ToolCallInfo>? toolCalls;
  final bool isLoading;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.toolCalls,
    this.isLoading = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    List<ToolCallInfo>? toolCalls,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      toolCalls: toolCalls ?? this.toolCalls,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'toolCalls': toolCalls?.map((t) => t.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: ChatRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        toolCalls: (json['toolCalls'] as List<dynamic>?)
            ?.map((t) => ToolCallInfo.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
