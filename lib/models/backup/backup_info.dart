/// 备份信息模型
class BackupInfo {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime createdAt;
  final BackupType type;
  final bool isEncrypted;

  BackupInfo({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.createdAt,
    required this.type,
    this.isEncrypted = false,
  });

  /// 格式化文件大小
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// 格式化创建时间
  String get createdAtFormatted {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'fileName': fileName,
      'fileSize': fileSize,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'type': type.toString(),
      'isEncrypted': isEncrypted,
    };
  }

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      id: json['id'],
      filePath: json['filePath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      type: BackupType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BackupType.manual,
      ),
      isEncrypted: json['isEncrypted'] ?? false,
    );
  }
}

/// 备份类型
enum BackupType {
  manual, // 手动备份
  auto, // 自动备份
  export, // 导出备份
}
