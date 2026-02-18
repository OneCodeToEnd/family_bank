/// Agent 记忆模型
class AgentMemory {
  final int? id;
  final String type; // 'like' | 'dislike' | 'note'
  final String content;
  final String? relatedQuery;
  final DateTime createdAt;

  const AgentMemory({
    this.id,
    required this.type,
    required this.content,
    this.relatedQuery,
    required this.createdAt,
  });

  factory AgentMemory.fromMap(Map<String, dynamic> map) {
    return AgentMemory(
      id: map['id'] as int?,
      type: map['type'] as String,
      content: map['content'] as String,
      relatedQuery: map['related_query'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'content': content,
      'related_query': relatedQuery,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  AgentMemory copyWith({
    int? id,
    String? type,
    String? content,
    String? relatedQuery,
    DateTime? createdAt,
  }) {
    return AgentMemory(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      relatedQuery: relatedQuery ?? this.relatedQuery,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
