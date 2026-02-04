/// 备份设置模型
class BackupSettings {
  final bool autoBackupEnabled;
  final int backupIntervalDays;
  final int keepBackupCount;
  final DateTime? lastBackupTime;
  final String? lastBackupPath;

  BackupSettings({
    this.autoBackupEnabled = false,
    this.backupIntervalDays = 1,
    this.keepBackupCount = 7,
    this.lastBackupTime,
    this.lastBackupPath,
  });

  BackupSettings copyWith({
    bool? autoBackupEnabled,
    int? backupIntervalDays,
    int? keepBackupCount,
    DateTime? lastBackupTime,
    String? lastBackupPath,
  }) {
    return BackupSettings(
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      backupIntervalDays: backupIntervalDays ?? this.backupIntervalDays,
      keepBackupCount: keepBackupCount ?? this.keepBackupCount,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoBackupEnabled': autoBackupEnabled,
      'backupIntervalDays': backupIntervalDays,
      'keepBackupCount': keepBackupCount,
      'lastBackupTime': lastBackupTime?.millisecondsSinceEpoch,
      'lastBackupPath': lastBackupPath,
    };
  }

  factory BackupSettings.fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      autoBackupEnabled: json['autoBackupEnabled'] ?? false,
      backupIntervalDays: json['backupIntervalDays'] ?? 1,
      keepBackupCount: json['keepBackupCount'] ?? 7,
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastBackupTime'])
          : null,
      lastBackupPath: json['lastBackupPath'],
    );
  }
}
