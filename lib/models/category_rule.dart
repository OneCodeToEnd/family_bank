/// 分类规则模型
class CategoryRule {
  final int? id;
  final String keyword;
  final int categoryId;
  final int priority;
  final bool isActive;
  final int matchCount;
  final String source; // user/model
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryRule({
    this.id,
    required this.keyword,
    required this.categoryId,
    this.priority = 0,
    this.isActive = true,
    this.matchCount = 0,
    this.source = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryRule.fromMap(Map<String, dynamic> map) {
    return CategoryRule(
      id: map['id'] as int?,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as int,
      priority: map['priority'] as int? ?? 0,
      isActive: (map['is_active'] as int) == 1,
      matchCount: map['match_count'] as int? ?? 0,
      source: map['source'] as String? ?? 'user',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'keyword': keyword,
      'category_id': categoryId,
      'priority': priority,
      'is_active': isActive ? 1 : 0,
      'match_count': matchCount,
      'source': source,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  CategoryRule copyWith({
    int? id,
    String? keyword,
    int? categoryId,
    int? priority,
    bool? isActive,
    int? matchCount,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryRule(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      matchCount: matchCount ?? this.matchCount,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 增加匹配次数
  CategoryRule incrementMatchCount() {
    return copyWith(
      matchCount: matchCount + 1,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CategoryRule(id: $id, keyword: $keyword, categoryId: $categoryId, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CategoryRule &&
        other.id == id &&
        other.keyword == keyword &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ keyword.hashCode ^ categoryId.hashCode;
  }
}
