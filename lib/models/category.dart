import 'dart:convert';

/// 分类模型
class Category {
  final int? id;
  final int? parentId;
  final String name;
  final String type; // income/expense
  final String? icon;
  final String? color;
  final bool isSystem;
  final bool isHidden;
  final int sortOrder;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    this.parentId,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.isSystem = false,
    this.isHidden = false,
    this.sortOrder = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// 是否为一级分类
  bool get isTopLevel => parentId == null;

  factory Category.fromMap(Map<String, dynamic> map) {
    List<String> tagsList = [];
    if (map['tags'] != null) {
      try {
        tagsList = List<String>.from(jsonDecode(map['tags'] as String));
      } catch (e) {
        tagsList = [];
      }
    }

    return Category(
      id: map['id'] as int?,
      parentId: map['parent_id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isSystem: (map['is_system'] as int) == 1,
      isHidden: (map['is_hidden'] as int) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      tags: tagsList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'parent_id': parentId,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'is_system': isSystem ? 1 : 0,
      'is_hidden': isHidden ? 1 : 0,
      'sort_order': sortOrder,
      'tags': jsonEncode(tags),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Category copyWith({
    int? id,
    int? parentId,
    String? name,
    String? type,
    String? icon,
    String? color,
    bool? isSystem,
    bool? isHidden,
    int? sortOrder,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      isHidden: isHidden ?? this.isHidden,
      sortOrder: sortOrder ?? this.sortOrder,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, parentId: $parentId, isSystem: $isSystem)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.parentId == parentId &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ parentId.hashCode ^ name.hashCode ^ type.hashCode;
  }
}
