/// 备份元数据模型
///
/// 包含备份文件的详细信息，用于版本比较和冲突检测
/// 元数据存储为 JSON 文件，与备份文件一起上传
/// 例如：backup_123456.db 对应 backup_123456.json
class BackupMetadata {
  final String backupId; // 备份唯一标识（UUID）
  final String deviceId; // 设备唯一标识
  final DateTime createdAt; // 创建时间
  final String? baseBackupId; // 基于哪个备份创建的
  final int transactionCount; // 交易数量
  final String dataHash; // 数据哈希值（SHA-256）
  final int fileSize; // 文件大小（字节）
  final String appVersion; // 应用版本

  const BackupMetadata({
    required this.backupId,
    required this.deviceId,
    required this.createdAt,
    this.baseBackupId,
    required this.transactionCount,
    required this.dataHash,
    required this.fileSize,
    required this.appVersion,
  });

  /// 从 JSON 创建元数据
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      backupId: json['backupId'] as String,
      deviceId: json['deviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      baseBackupId: json['baseBackupId'] as String?,
      transactionCount: json['transactionCount'] as int,
      dataHash: json['dataHash'] as String,
      fileSize: json['fileSize'] as int,
      appVersion: json['appVersion'] as String,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'baseBackupId': baseBackupId,
      'transactionCount': transactionCount,
      'dataHash': dataHash,
      'fileSize': fileSize,
      'appVersion': appVersion,
    };
  }

  /// 复制元数据并修改部分字段
  BackupMetadata copyWith({
    String? backupId,
    String? deviceId,
    DateTime? createdAt,
    String? baseBackupId,
    int? transactionCount,
    String? dataHash,
    int? fileSize,
    String? appVersion,
  }) {
    return BackupMetadata(
      backupId: backupId ?? this.backupId,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      baseBackupId: baseBackupId ?? this.baseBackupId,
      transactionCount: transactionCount ?? this.transactionCount,
      dataHash: dataHash ?? this.dataHash,
      fileSize: fileSize ?? this.fileSize,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}
