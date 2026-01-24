/// 邮箱配置模型
class EmailConfig {
  final int? id;
  final String email;        // 邮箱地址
  final String imapServer;   // IMAP服务器地址
  final int imapPort;        // IMAP端口
  final String password;     // 邮箱密码/授权码（加密存储）
  final bool isEnabled;      // 是否启用
  final DateTime createdAt;
  final DateTime updatedAt;

  EmailConfig({
    this.id,
    required this.email,
    required this.imapServer,
    required this.imapPort,
    required this.password,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从数据库记录创建
  factory EmailConfig.fromMap(Map<String, dynamic> map) {
    return EmailConfig(
      id: map['id'] as int?,
      email: map['email'] as String,
      imapServer: map['imap_server'] as String,
      imapPort: map['imap_port'] as int,
      password: map['password'] as String,
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'imap_server': imapServer,
      'imap_port': imapPort,
      'password': password,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制并更新部分字段
  EmailConfig copyWith({
    int? id,
    String? email,
    String? imapServer,
    int? imapPort,
    String? password,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailConfig(
      id: id ?? this.id,
      email: email ?? this.email,
      imapServer: imapServer ?? this.imapServer,
      imapPort: imapPort ?? this.imapPort,
      password: password ?? this.password,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
