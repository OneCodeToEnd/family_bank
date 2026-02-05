import 'backup_metadata.dart';

/// 同步状态枚举
enum SyncState {
  idle, // 空闲
  checking, // 检查中
  uploading, // 上传中
  downloading, // 下载中
  restoring, // 恢复中
  success, // 成功
  error, // 错误
  conflict, // 冲突
}

/// 同步状态模型
///
/// 记录当前同步状态和相关信息
/// 持久化到 app_settings 表
class SyncStatus {
  final DateTime? lastSyncTime; // 最后同步时间
  final SyncState state; // 同步状态
  final String? errorMessage; // 错误信息
  final BackupMetadata? localMetadata; // 本地备份元数据
  final BackupMetadata? remoteMetadata; // 远程备份元数据
  final bool hasConflict; // 是否有冲突
  final double? progress; // 同步进度（0.0-1.0）

  const SyncStatus({
    this.lastSyncTime,
    this.state = SyncState.idle,
    this.errorMessage,
    this.localMetadata,
    this.remoteMetadata,
    this.hasConflict = false,
    this.progress,
  });

  /// 从 JSON 创建状态
  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      state: SyncState.values.firstWhere(
        (e) => e.toString() == json['state'],
        orElse: () => SyncState.idle,
      ),
      errorMessage: json['errorMessage'] as String?,
      localMetadata: json['localMetadata'] != null
          ? BackupMetadata.fromJson(
              json['localMetadata'] as Map<String, dynamic>)
          : null,
      remoteMetadata: json['remoteMetadata'] != null
          ? BackupMetadata.fromJson(
              json['remoteMetadata'] as Map<String, dynamic>)
          : null,
      hasConflict: json['hasConflict'] as bool? ?? false,
      progress: json['progress'] as double?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'state': state.toString(),
      'errorMessage': errorMessage,
      'localMetadata': localMetadata?.toJson(),
      'remoteMetadata': remoteMetadata?.toJson(),
      'hasConflict': hasConflict,
      'progress': progress,
    };
  }

  /// 复制状态并修改部分字段
  SyncStatus copyWith({
    DateTime? lastSyncTime,
    SyncState? state,
    String? errorMessage,
    BackupMetadata? localMetadata,
    BackupMetadata? remoteMetadata,
    bool? hasConflict,
    double? progress,
  }) {
    return SyncStatus(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      localMetadata: localMetadata ?? this.localMetadata,
      remoteMetadata: remoteMetadata ?? this.remoteMetadata,
      hasConflict: hasConflict ?? this.hasConflict,
      progress: progress ?? this.progress,
    );
  }
}
