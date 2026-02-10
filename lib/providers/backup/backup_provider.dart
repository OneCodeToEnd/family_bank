import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../models/backup/backup_info.dart';
import '../../models/backup/backup_settings.dart';
import '../../models/sync/backup_metadata.dart';
import '../../models/sync/sync_comparison.dart';
import '../../models/sync/webdav_config.dart';
import '../../services/backup/backup_service.dart';
import '../../services/backup/export_import_service.dart';
import '../../services/backup/auto_backup_service.dart';
import '../../services/sync/webdav_client.dart';
import '../../services/sync/webdav_config_service.dart';
import '../../services/database/database_service.dart';
import '../../constants/db_constants.dart';
import '../../utils/app_logger.dart';

/// 备份状态管理
class BackupProvider with ChangeNotifier {
  final _backupService = BackupService();
  final _exportImportService = ExportImportService();
  final _autoBackupService = AutoBackupService();
  final _configService = WebDAVConfigService();
  final _databaseService = DatabaseService();

  List<BackupInfo> _backups = [];
  BackupSettings _settings = BackupSettings();
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastCloudSyncTime;

  List<BackupInfo> get backups => _backups;
  BackupSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastCloudSyncTime => _lastCloudSyncTime;

  /// 初始化
  Future<void> initialize() async {
    try {
      AppLogger.i('[BackupProvider] 初始化备份管理');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 加载备份列表
      await loadBackups();

      // 加载设置
      await loadSettings();

      // 加载最后同步时间
      await _loadLastCloudSyncTime();

      // 检查并执行自动备份
      await _autoBackupService.checkAndBackup();

      _isLoading = false;
      notifyListeners();

      AppLogger.i('[BackupProvider] 初始化完成');
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 初始化失败', error: e, stackTrace: stackTrace);
      _errorMessage = '初始化失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载备份列表
  Future<void> loadBackups() async {
    try {
      _backups = await _backupService.listBackups();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 加载备份列表失败', error: e, stackTrace: stackTrace);
      _errorMessage = '加载备份列表失败：${e.toString()}';
      notifyListeners();
    }
  }

  /// 加载设置
  Future<void> loadSettings() async {
    try {
      _settings = await _autoBackupService.getSettings();
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 加载设置失败', error: e, stackTrace: stackTrace);
    }
  }

  /// 创建备份
  Future<bool> createBackup() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final backupInfo = await _autoBackupService.backupNow();

      // 重新加载备份列表
      await loadBackups();

      // 重新加载设置（更新最后备份时间）
      await loadSettings();

      _isLoading = false;
      notifyListeners();

      AppLogger.i('[BackupProvider] 备份创建成功: ${backupInfo.fileName}');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 创建备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '创建备份失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 导出备份
  Future<bool> exportBackup() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _exportImportService.exportBackup();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 导出备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '导出备份失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 导出指定备份
  Future<bool> exportExistingBackup(BackupInfo backupInfo) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _exportImportService.exportExistingBackup(backupInfo);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 导出备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '导出备份失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 导入备份
  Future<bool> importBackup() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _exportImportService.importBackup();

      if (success) {
        // 重新加载备份列表
        await loadBackups();
      }

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 导入备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '导入备份失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 恢复备份
  Future<bool> restoreBackup(BackupInfo backupInfo) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _backupService.restoreBackup(backupInfo.filePath);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 恢复备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '恢复备份失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 删除备份
  Future<bool> deleteBackup(BackupInfo backupInfo) async {
    try {
      await _backupService.deleteBackup(backupInfo.filePath);

      // 重新加载备份列表
      await loadBackups();

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 删除备份失败', error: e, stackTrace: stackTrace);
      _errorMessage = '删除备份失败：${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 更新设置
  Future<bool> updateSettings(BackupSettings newSettings) async {
    try {
      await _autoBackupService.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();

      AppLogger.i('[BackupProvider] 设置已更新');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 更新设置失败', error: e, stackTrace: stackTrace);
      _errorMessage = '更新设置失败：${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// 清除错误消息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 获取云端备份列表
  Future<List<RemoteBackupWithMetadata>> getCloudBackups() async {
    try {
      AppLogger.i('[BackupProvider] 获取云端备份列表');

      // 检查 WebDAV 配置
      final config = await _ensureWebDAVConfig();

      // 获取云端备份列表
      final client = WebDAVClient(config);
      final backups = await client.listBackupsWithMetadata();

      AppLogger.i('[BackupProvider] 找到 ${backups.length} 个云端备份');
      return backups;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 获取云端备份列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 确保 WebDAV 配置存在
  Future<WebDAVConfig> _ensureWebDAVConfig() async {
    final config = await _configService.loadConfig();
    if (config == null) {
      throw Exception('WebDAV 未配置');
    }
    return config;
  }

  /// 流式计算文件哈希（避免大文件内存溢出）
  Future<String> _calculateFileHash(File file) async {
    final stream = file.openRead();
    final hash = await sha256.bind(stream).first;
    return hash.toString();
  }

  /// 保存最后同步时间到持久化存储
  Future<void> _saveLastCloudSyncTime() async {
    if (_lastCloudSyncTime == null) return;

    try {
      final db = await _databaseService.database;
      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [
        'last_cloud_sync_time',
        _lastCloudSyncTime!.millisecondsSinceEpoch.toString(),
        DateTime.now().millisecondsSinceEpoch,
      ]);
      AppLogger.d('[BackupProvider] 最后同步时间已保存');
    } catch (e) {
      AppLogger.w('[BackupProvider] 保存最后同步时间失败', error: e);
    }
  }

  /// 加载最后同步时间
  Future<void> _loadLastCloudSyncTime() async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: ['last_cloud_sync_time'],
        limit: 1,
      );

      if (results.isNotEmpty) {
        final timestamp = int.tryParse(results.first[DbConstants.columnSettingValue] as String? ?? '');
        if (timestamp != null) {
          _lastCloudSyncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          AppLogger.d('[BackupProvider] 最后同步时间已加载: $_lastCloudSyncTime');
        }
      }
    } catch (e) {
      AppLogger.w('[BackupProvider] 加载最后同步时间失败', error: e);
    }
  }

  /// 从云端恢复备份
  Future<bool> restoreFromCloud(RemoteBackupWithMetadata remoteBackup) async {
    File? tempFile;
    try {
      AppLogger.i('[BackupProvider] 从云端恢复备份: ${remoteBackup.name}');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. 检查 WebDAV 配置
      final config = await _ensureWebDAVConfig();

      // 2. 下载备份文件到临时位置
      final backupDir = await _backupService.getBackupDirectory();
      final tempPath = '${backupDir.path}/temp_cloud_restore_${DateTime.now().millisecondsSinceEpoch}.db';

      final client = WebDAVClient(config);
      tempFile = await client.downloadBackupWithProgress(
        remoteBackup.path,
        tempPath,
        null,
      );

      // 3. 验证文件完整性（使用流式哈希计算避免内存溢出）
      final downloadedHash = await _calculateFileHash(tempFile);

      if (downloadedHash != remoteBackup.metadata.dataHash) {
        throw Exception('文件完整性验证失败');
      }

      // 4. 恢复备份
      await _backupService.restoreBackup(tempPath);

      // 5. 更新最后同步时间并持久化
      _lastCloudSyncTime = DateTime.now();
      await _saveLastCloudSyncTime();

      _isLoading = false;
      notifyListeners();

      AppLogger.i('[BackupProvider] 从云端恢复成功');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 从云端恢复失败', error: e, stackTrace: stackTrace);
      _errorMessage = '从云端恢复失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    } finally {
      // 确保临时文件被清理
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
          AppLogger.d('[BackupProvider] 临时文件已清理: ${tempFile.path}');
        } catch (e) {
          AppLogger.w('[BackupProvider] 清理临时文件失败', error: e);
        }
      }
    }
  }

  /// 上传备份到云端
  Future<bool> uploadToCloud(BackupInfo backup) async {
    try {
      AppLogger.i('[BackupProvider] 上传备份到云端: ${backup.fileName}');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. 检查 WebDAV 配置
      final config = await _ensureWebDAVConfig();

      // 2. 生成元数据
      final metadata = await _generateBackupMetadata(backup);

      // 3. 创建 WebDAV 客户端并确保目录存在
      final client = WebDAVClient(config);
      await client.ensureRemoteDirectory();

      // 4. 先上传元数据（如果失败，不会留下孤儿文件）
      await client.uploadMetadata(metadata);

      // 5. 再上传备份文件
      final backupFile = File(backup.filePath);
      try {
        await client.uploadBackupWithProgress(backupFile, null);
      } catch (e) {
        // 备份文件上传失败，尝试删除已上传的元数据
        AppLogger.w('[BackupProvider] 备份文件上传失败，尝试清理元数据');
        try {
          final normalizedPath = _normalizeRemotePath(config.remotePath);
          final metadataPath = '$normalizedPath/backup_${metadata.backupId}.json';
          await client.deleteBackup(metadataPath);
        } catch (cleanupError) {
          AppLogger.w('[BackupProvider] 清理元数据失败', error: cleanupError);
        }
        rethrow;
      }

      // 6. 更新最后同步时间并持久化
      _lastCloudSyncTime = DateTime.now();
      await _saveLastCloudSyncTime();

      _isLoading = false;
      notifyListeners();

      AppLogger.i('[BackupProvider] 上传到云端成功');
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 上传到云端失败', error: e, stackTrace: stackTrace);
      _errorMessage = '上传到云端失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 标准化远程路径（与 WebDAVClient 保持一致）
  String _normalizeRemotePath(String path) {
    String normalized = path.trim();
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  /// 上传当前数据到云端
  Future<bool> uploadCurrentDataToCloud() async {
    try {
      AppLogger.i('[BackupProvider] 上传当前数据到云端');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // 1. 创建备份
      final backupInfo = await _autoBackupService.backupNow();

      // 2. 重新加载备份列表
      await loadBackups();

      // 3. 重新加载设置（更新最后备份时间）
      await loadSettings();

      // 4. 上传到云端（uploadToCloud 会管理自己的 loading 状态）
      _isLoading = false;
      notifyListeners();

      return await uploadToCloud(backupInfo);
    } catch (e, stackTrace) {
      AppLogger.e('[BackupProvider] 上传当前数据到云端失败', error: e, stackTrace: stackTrace);
      _errorMessage = '上传当前数据到云端失败：${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 生成备份元数据
  Future<BackupMetadata> _generateBackupMetadata(BackupInfo backup) async {
    // 获取设备信息
    final deviceId = await _getDeviceId();

    // 获取应用版本
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    // 计算数据哈希（使用流式计算避免内存溢出）
    final backupFile = File(backup.filePath);
    final dataHash = await _calculateFileHash(backupFile);

    // 获取交易数量
    final transactionCount = await _getTransactionCount();

    return BackupMetadata(
      backupId: backup.id,
      deviceId: deviceId,
      createdAt: backup.createdAt,
      baseBackupId: null,
      transactionCount: transactionCount,
      dataHash: dataHash,
      fileSize: backup.fileSize,
      appVersion: appVersion,
    );
  }

  /// 获取设备标识（统一格式，限制长度）
  Future<String> _getDeviceId() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String deviceId = 'Unknown';

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceId = '${androidInfo.brand} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceId = '${iosInfo.name} (${iosInfo.model})';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        deviceId = '${macInfo.computerName} (macOS)';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        deviceId = '${windowsInfo.computerName} (Windows)';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        deviceId = '${linuxInfo.name} (Linux)';
      }

      // 清理设备名称：移除特殊字符，限制长度
      deviceId = _sanitizeDeviceName(deviceId);

      return deviceId;
    } catch (e) {
      AppLogger.w('[BackupProvider] 获取设备信息失败', error: e);
      return 'Unknown Device';
    }
  }

  /// 清理设备名称
  String _sanitizeDeviceName(String name) {
    // 移除控制字符和特殊字符
    String sanitized = name.replaceAll(RegExp(r'[^\x20-\x7E\u4e00-\u9fa5]'), '');

    // 限制长度为 50 个字符
    if (sanitized.length > 50) {
      sanitized = '${sanitized.substring(0, 47)}...';
    }

    return sanitized.trim();
  }

  /// 获取交易数量
  Future<int> _getTransactionCount() async {
    try {
      final db = await _databaseService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbConstants.tableTransactions}',
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      AppLogger.w('[BackupProvider] 获取交易数量失败', error: e);
      return 0;
    }
  }
}
