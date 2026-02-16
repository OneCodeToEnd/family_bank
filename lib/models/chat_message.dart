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
}
