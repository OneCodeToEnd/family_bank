import 'dart:convert';

/// 分类规则模型
class CategoryRule {
  final int? id;
  final String keyword;
  final int categoryId;
  final int priority;
  final bool isActive;
  final int matchCount;
  final String source; // user/model/learned

  // V3.0 新增字段
  final String matchType; // exact/partial/counterparty
  final String? matchPosition; // contains/prefix/suffix (仅用于partial)
  final double minConfidence; // 最小置信度阈值 (0-1)
  final String? counterparty; // 交易对方名称（如果matchType=counterparty）
  final List<String> aliases; // 别名列表（如：["星巴克", "Starbucks", "starbucks"]）
  final bool autoLearn; // 是否自动学习（从匹配中自动生成）
  final bool caseSensitive; // 是否区分大小写（默认false）

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
    this.matchType = 'exact',
    this.matchPosition,
    this.minConfidence = 0.8,
    this.counterparty,
    this.aliases = const [],
    this.autoLearn = false,
    this.caseSensitive = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryRule.fromMap(Map<String, dynamic> map) {
    // 解析别名列表
    List<String> aliasesList = [];
    if (map['aliases'] != null && (map['aliases'] as String).isNotEmpty) {
      try {
        aliasesList = List<String>.from(jsonDecode(map['aliases'] as String));
      } catch (e) {
        aliasesList = [];
      }
    }

    return CategoryRule(
      id: map['id'] as int?,
      keyword: map['keyword'] as String,
      categoryId: map['category_id'] as int,
      priority: map['priority'] as int? ?? 0,
      isActive: (map['is_active'] as int) == 1,
      matchCount: map['match_count'] as int? ?? 0,
      source: map['source'] as String? ?? 'user',
      matchType: map['match_type'] as String? ?? 'exact',
      matchPosition: map['match_position'] as String?,
      minConfidence: (map['min_confidence'] as num?)?.toDouble() ?? 0.8,
      counterparty: map['counterparty'] as String?,
      aliases: aliasesList,
      autoLearn: (map['auto_learn'] as int?) == 1,
      caseSensitive: (map['case_sensitive'] as int?) == 1,
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
      'match_type': matchType,
      'match_position': matchPosition,
      'min_confidence': minConfidence,
      'counterparty': counterparty,
      'aliases': jsonEncode(aliases),
      'auto_learn': autoLearn ? 1 : 0,
      'case_sensitive': caseSensitive ? 1 : 0,
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
    String? matchType,
    String? matchPosition,
    double? minConfidence,
    String? counterparty,
    List<String>? aliases,
    bool? autoLearn,
    bool? caseSensitive,
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
      matchType: matchType ?? this.matchType,
      matchPosition: matchPosition ?? this.matchPosition,
      minConfidence: minConfidence ?? this.minConfidence,
      counterparty: counterparty ?? this.counterparty,
      aliases: aliases ?? this.aliases,
      autoLearn: autoLearn ?? this.autoLearn,
      caseSensitive: caseSensitive ?? this.caseSensitive,
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
