import 'package:flutter/material.dart';

/// 快捷操作模型
/// 用于首页快捷操作的数据结构
class QuickAction {
  /// 唯一标识符（如 'account_list', 'add_transaction'）
  final String id;

  /// 显示名称（如 '账户管理'）
  final String name;

  /// 显示图标
  final IconData icon;

  /// 目标页面类名或路由标识
  final String routeName;

  /// 排序顺序（0开始）
  final int sortOrder;

  const QuickAction({
    required this.id,
    required this.name,
    required this.icon,
    required this.routeName,
    required this.sortOrder,
  });

  /// 从 JSON 创建（用于从数据库加载）
  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
      ),
      routeName: json['routeName'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  /// 转换为 JSON（用于保存到数据库）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'routeName': routeName,
      'sortOrder': sortOrder,
    };
  }

  /// 复制并修改部分字段
  QuickAction copyWith({
    String? id,
    String? name,
    IconData? icon,
    String? routeName,
    int? sortOrder,
  }) {
    return QuickAction(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      routeName: routeName ?? this.routeName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuickAction(id: $id, name: $name, routeName: $routeName)';
  }
}
