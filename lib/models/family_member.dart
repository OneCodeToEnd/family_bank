/// 家庭成员模型
class FamilyMember {
  final int? id;
  final int familyGroupId;
  final String name;
  final String? avatar;
  final String? role;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMember({
    this.id,
    required this.familyGroupId,
    required this.name,
    this.avatar,
    this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int?,
      familyGroupId: map['family_group_id'] as int,
      name: map['name'] as String,
      avatar: map['avatar'] as String?,
      role: map['role'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'family_group_id': familyGroupId,
      'name': name,
      'avatar': avatar,
      'role': role,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  FamilyMember copyWith({
    int? id,
    int? familyGroupId,
    String? name,
    String? avatar,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyGroupId: familyGroupId ?? this.familyGroupId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'FamilyMember(id: $id, name: $name, role: $role, familyGroupId: $familyGroupId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FamilyMember &&
        other.id == id &&
        other.familyGroupId == familyGroupId &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ familyGroupId.hashCode ^ name.hashCode ^ role.hashCode;
  }
}
