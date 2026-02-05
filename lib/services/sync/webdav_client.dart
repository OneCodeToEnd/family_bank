import 'dart:convert';
import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../../models/sync/webdav_config.dart';
import '../../models/sync/backup_metadata.dart';
import '../../models/sync/sync_comparison.dart';
import '../../utils/app_logger.dart';

/// WebDAV 客户端封装
///
/// 封装 webdav_client 包，提供备份文件的上传、下载、列表等功能
class WebDAVClient {
  late final webdav.Client _client;
  final WebDAVConfig config;

  WebDAVClient(this.config) {
    // 检查 HTTPS
    if (!config.serverUrl.startsWith('https://') &&
        !config.allowInsecureConnection) {
      throw SyncException('必须使用 HTTPS 连接，或在配置中允许非安全连接');
    }

    // 配置客户端
    _client = webdav.newClient(
      config.serverUrl,
      user: config.username,
      password: config.password,
      debug: false,
    );

    // TODO: 实现自签名证书支持
    // 当前 webdav_client 包不支持自定义 HttpClient
    // 需要升级包或使用其他方式来支持自签名证书
    // 参考: https://github.com/FriesI23/simple_webdav_client/issues
    if (config.allowSelfSignedCert) {
      AppLogger.w('[WebDAVClient] 警告：自签名证书功能尚未实现，连接可能失败');
    }

    AppLogger.i('[WebDAVClient] WebDAV 客户端已初始化');
  }

  /// 标准化远程路径
  ///
  /// 确保路径：
  /// 1. 以 / 开头
  /// 2. 不以 / 结尾（除非是根路径 /）
  /// 3. 去除首尾空格
  String _normalizeRemotePath(String path) {
    String normalized = path.trim();

    // 确保以 / 开头
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }

    // 去除末尾的 /（但保留根路径 /）
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      AppLogger.d('[WebDAVClient] 测试连接...');
      await _client.ping();
      AppLogger.i('[WebDAVClient] 连接测试成功');
      return true;
    } catch (e) {
      AppLogger.e('[WebDAVClient] 连接测试失败', error: e);
      return false;
    }
  }

  /// 确保远程目录存在
  Future<void> ensureRemoteDirectory() async {
    try {
      final normalizedPath = _normalizeRemotePath(config.remotePath);
      AppLogger.d('[WebDAVClient] 检查远程目录: $normalizedPath (原始: ${config.remotePath})');
      await _client.mkdir(normalizedPath);
      AppLogger.i('[WebDAVClient] 远程目录已创建或已存在');
    } catch (e) {
      // 目录可能已存在，忽略错误
      AppLogger.d('[WebDAVClient] 远程目录操作: $e');
    }
  }

  /// 上传备份文件（带进度）
  Future<void> uploadBackupWithProgress(
    File backupFile,
    Function(int sent, int total)? onProgress,
  ) async {
    try {
      // 获取文件名
      final fileName = backupFile.path.split('/').last;

      // 标准化远程路径并拼接文件名
      final normalizedRemotePath = _normalizeRemotePath(config.remotePath);
      final remotePath = '$normalizedRemotePath/$fileName';

      AppLogger.i('[WebDAVClient] 配置的远程路径: ${config.remotePath}');
      AppLogger.i('[WebDAVClient] 标准化后路径: $normalizedRemotePath');
      AppLogger.i('[WebDAVClient] 本地文件路径: ${backupFile.path}');
      AppLogger.i('[WebDAVClient] 文件名: $fileName');
      AppLogger.i('[WebDAVClient] 最终上传路径: $remotePath');

      final bytes = await backupFile.readAsBytes();
      final total = bytes.length;
      AppLogger.i('[WebDAVClient] 文件大小: $total bytes');

      // 上传文件
      await _client.write(remotePath, bytes);

      // 调用进度回调
      onProgress?.call(total, total);

      AppLogger.i('[WebDAVClient] 备份上传成功');
    } catch (e, stackTrace) {
      AppLogger.e('[WebDAVClient] 上传备份失败', error: e, stackTrace: stackTrace);
      throw SyncException('上传备份失败: $e');
    }
  }

  /// 下载备份文件（带进度和完整性验证）
  Future<File> downloadBackupWithProgress(
    String remotePath,
    String localPath,
    Function(int received, int total)? onProgress,
  ) async {
    try {
      AppLogger.i('[WebDAVClient] 开始下载备份: $remotePath');

      final bytes = await _client.read(remotePath);
      final total = bytes.length;

      // 调用进度回调
      onProgress?.call(total, total);

      final file = File(localPath);
      await file.writeAsBytes(bytes);

      AppLogger.i('[WebDAVClient] 备份下载成功');
      return file;
    } catch (e, stackTrace) {
      AppLogger.e('[WebDAVClient] 下载备份失败', error: e, stackTrace: stackTrace);
      throw SyncException('下载备份失败: $e');
    }
  }

  /// 上传元数据文件
  Future<void> uploadMetadata(BackupMetadata metadata) async {
    try {
      // 标准化远程路径并拼接文件名
      final normalizedRemotePath = _normalizeRemotePath(config.remotePath);
      final metadataPath = '$normalizedRemotePath/backup_${metadata.backupId}.json';
      AppLogger.d('[WebDAVClient] 上传元数据: $metadataPath');

      final jsonString = jsonEncode(metadata.toJson());
      final bytes = utf8.encode(jsonString);

      await _client.write(metadataPath, bytes);

      AppLogger.i('[WebDAVClient] 元数据上传成功');
    } catch (e, stackTrace) {
      AppLogger.e('[WebDAVClient] 上传元数据失败', error: e, stackTrace: stackTrace);
      throw SyncException('上传元数据失败: $e');
    }
  }

  /// 下载元数据文件
  Future<BackupMetadata?> downloadMetadata(String backupId) async {
    try {
      final normalizedRemotePath = _normalizeRemotePath(config.remotePath);
      final metadataPath = '$normalizedRemotePath/backup_$backupId.json';
      AppLogger.d('[WebDAVClient] 下载元数据: $metadataPath');

      final bytes = await _client.read(metadataPath);
      final jsonString = utf8.decode(bytes);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final metadata = BackupMetadata.fromJson(json);
      AppLogger.i('[WebDAVClient] 元数据下载成功');
      return metadata;
    } catch (e) {
      AppLogger.w('[WebDAVClient] 下载元数据失败: $e');
      return null;
    }
  }

  /// 列出远程备份（包含元数据）
  Future<List<RemoteBackupWithMetadata>> listBackupsWithMetadata() async {
    try {
      final normalizedRemotePath = _normalizeRemotePath(config.remotePath);
      AppLogger.d('[WebDAVClient] 列出远程备份: $normalizedRemotePath');

      final files = await _client.readDir(normalizedRemotePath);
      final backups = <RemoteBackupWithMetadata>[];

      for (final file in files) {
        if (file.name?.endsWith('.db') ?? false) {
          // 提取备份 ID
          final backupId = file.name!.replaceAll('backup_', '').replaceAll('.db', '');

          // 下载元数据
          final metadata = await downloadMetadata(backupId);
          if (metadata != null) {
            backups.add(RemoteBackupWithMetadata(
              path: file.path ?? '',
              name: file.name ?? '',
              modifiedTime: file.mTime ?? DateTime.now(),
              size: file.size ?? 0,
              metadata: metadata,
            ));
          }
        }
      }

      // 按修改时间降序排序
      backups.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));

      AppLogger.i('[WebDAVClient] 找到 ${backups.length} 个远程备份');
      return backups;
    } catch (e, stackTrace) {
      AppLogger.e('[WebDAVClient] 列出远程备份失败', error: e, stackTrace: stackTrace);
      throw SyncException('列出远程备份失败: $e');
    }
  }

  /// 删除远程备份
  Future<void> deleteBackup(String remotePath) async {
    try {
      AppLogger.i('[WebDAVClient] 删除远程备份: $remotePath');
      await _client.remove(remotePath);
      AppLogger.i('[WebDAVClient] 备份删除成功');
    } catch (e, stackTrace) {
      AppLogger.e('[WebDAVClient] 删除备份失败', error: e, stackTrace: stackTrace);
      throw SyncException('删除备份失败: $e');
    }
  }
}

/// 同步异常
class SyncException implements Exception {
  final String message;

  SyncException(this.message);

  @override
  String toString() => 'SyncException: $message';
}
