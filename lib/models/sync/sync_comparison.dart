import 'backup_metadata.dart';

/// 同步操作枚举
enum SyncAction {
  none, // 无需操作（已是最新）
  upload, // 上传本地到服务器
  download, // 从服务器下载
  conflict, // 冲突（需要用户选择）
}

/// 版本比较结果模型
///
/// 比较本地和远程版本后的结果
class SyncComparison {
  final SyncAction action; // 需要执行的操作
  final BackupMetadata? localMetadata; // 本地元数据
  final BackupMetadata? remoteMetadata; // 远程元数据
  final String? remoteBackupPath; // 远程备份文件路径
  final String? conflictReason; // 冲突原因

  const SyncComparison({
    required this.action,
    this.localMetadata,
    this.remoteMetadata,
    this.remoteBackupPath,
    this.conflictReason,
  });

  /// 是否有冲突
  bool get hasConflict => action == SyncAction.conflict;

  /// 是否需要同步
  bool get needsSync =>
      action == SyncAction.upload || action == SyncAction.download;

  /// 复制比较结果并修改部分字段
  SyncComparison copyWith({
    SyncAction? action,
    BackupMetadata? localMetadata,
    BackupMetadata? remoteMetadata,
    String? remoteBackupPath,
    String? conflictReason,
  }) {
    return SyncComparison(
      action: action ?? this.action,
      localMetadata: localMetadata ?? this.localMetadata,
      remoteMetadata: remoteMetadata ?? this.remoteMetadata,
      remoteBackupPath: remoteBackupPath ?? this.remoteBackupPath,
      conflictReason: conflictReason ?? this.conflictReason,
    );
  }
}

/// 远程备份信息（包含元数据）
class RemoteBackupWithMetadata {
  final String path; // 远程文件路径
  final String name; // 文件名
  final DateTime modifiedTime; // 修改时间
  final int size; // 文件大小
  final BackupMetadata metadata; // 备份元数据

  const RemoteBackupWithMetadata({
    required this.path,
    required this.name,
    required this.modifiedTime,
    required this.size,
    required this.metadata,
  });
}
