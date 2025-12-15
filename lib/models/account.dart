/// 账户模型
class Account {
  final int? id;
  final int familyMemberId;
  final String name;
  final String type;
  final String? icon;
  final bool isHidden;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    this.id,
    required this.familyMemberId,
    required this.name,
    required this.type,
    this.icon,
    this.isHidden = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      familyMemberId: map['family_member_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      isHidden: (map['is_hidden'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'family_member_id': familyMemberId,
      'name': name,
      'type': type,
      'icon': icon,
      'is_hidden': isHidden ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Account copyWith({
    int? id,
    int? familyMemberId,
    String? name,
    String? type,
    String? icon,
    bool? isHidden,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isHidden: isHidden ?? this.isHidden,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Account(id: $id, name: $name, type: $type, familyMemberId: $familyMemberId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Account &&
        other.id == id &&
        other.familyMemberId == familyMemberId &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return id.hashCode ^ familyMemberId.hashCode ^ name.hashCode ^ type.hashCode;
  }
}
