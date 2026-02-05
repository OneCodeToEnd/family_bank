/// WebDAV 配置模型
///
/// 存储 WebDAV 服务器连接配置信息
/// 数据存储在 app_settings 表中，密码使用 AES 加密
class WebDAVConfig {
  final String id; // 配置 ID（UUID）
  final String serverUrl; // 服务器地址
  final String username; // 用户名
  final String password; // 密码（存储时加密，使用时解密）
  final String remotePath; // 远程路径
  final bool autoSync; // 是否自动同步
  final int syncInterval; // 同步间隔（分钟）
  final bool syncOnStart; // 启动时同步
  final bool syncOnChange; // 数据变化时同步
  final bool allowSelfSignedCert; // 允许自签名证书
  final bool allowInsecureConnection; // 允许非 HTTPS 连接

  const WebDAVConfig({
    required this.id,
    required this.serverUrl,
    required this.username,
    required this.password,
    required this.remotePath,
    this.autoSync = false,
    this.syncInterval = 60,
    this.syncOnStart = false,
    this.syncOnChange = false,
    this.allowSelfSignedCert = false,
    this.allowInsecureConnection = false,
  });

  /// 从 JSON 创建配置
  factory WebDAVConfig.fromJson(Map<String, dynamic> json) {
    return WebDAVConfig(
      id: json['id'] as String,
      serverUrl: json['serverUrl'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      remotePath: json['remotePath'] as String,
      autoSync: json['autoSync'] as bool? ?? false,
      syncInterval: json['syncInterval'] as int? ?? 60,
      syncOnStart: json['syncOnStart'] as bool? ?? false,
      syncOnChange: json['syncOnChange'] as bool? ?? false,
      allowSelfSignedCert: json['allowSelfSignedCert'] as bool? ?? false,
      allowInsecureConnection:
          json['allowInsecureConnection'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'remotePath': remotePath,
      'autoSync': autoSync,
      'syncInterval': syncInterval,
      'syncOnStart': syncOnStart,
      'syncOnChange': syncOnChange,
      'allowSelfSignedCert': allowSelfSignedCert,
      'allowInsecureConnection': allowInsecureConnection,
    };
  }

  /// 复制配置并修改部分字段
  WebDAVConfig copyWith({
    String? id,
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
    bool? autoSync,
    int? syncInterval,
    bool? syncOnStart,
    bool? syncOnChange,
    bool? allowSelfSignedCert,
    bool? allowInsecureConnection,
  }) {
    return WebDAVConfig(
      id: id ?? this.id,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOnStart: syncOnStart ?? this.syncOnStart,
      syncOnChange: syncOnChange ?? this.syncOnChange,
      allowSelfSignedCert: allowSelfSignedCert ?? this.allowSelfSignedCert,
      allowInsecureConnection:
          allowInsecureConnection ?? this.allowInsecureConnection,
    );
  }
}