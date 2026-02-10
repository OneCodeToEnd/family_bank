import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/sync/backup_metadata.dart';
import '../../models/sync/sync_status.dart';
import '../../models/sync/sync_comparison.dart';
import '../database/database_service.dart';
import '../backup/backup_service.dart';
import 'webdav_client.dart';
import 'webdav_config_service.dart';
import 'sync_state_manager.dart';

/// 同步结果
class SyncResult {
  final bool success;
  final String message;
  final SyncAction action;
  final BackupMetadata? localMetadata;
  final BackupMetadata? remoteMetadata;

  const SyncResult({
    required this.success,
    required this.message,
    required this.action,
    this.localMetadata,
    this.remoteMetadata,
  });
}

/// 核心同步服务
///
/// 负责协调各个组件完成数据同步
class SyncService {
  final WebDAVConfigService _configService;
  final SyncStateManager _stateManager;
  final BackupService _backupService;
  final DatabaseService _dbService;
  final Logger _logger = Logger();

  SyncService({
    WebDAVConfigService? configService,
    SyncStateManager? stateManager,
    BackupService? backupService,
    DatabaseService? dbService,
  })  : _configService = configService ?? WebDAVConfigService(),
        _stateManager = stateManager ?? SyncStateManager(),
        _backupService = backupService ?? BackupService(),
        _dbService = dbService ?? DatabaseService();

  /// 主同步入口
  Future<SyncResult> sync() async {
    _logger.i('[SyncService] 开始同步');

    try {
      // 1. 检查是否可以开始同步
      if (!await _canStartSync()) {
        return SyncResult(
          success: false,
          message: '当前无法同步',
          action: SyncAction.none,
        );
      }

      // 2. 保存同步状态
      await _stateManager.saveSyncState(const SyncStatus(
        state: SyncState.checking,
      ));

      // 3. 检查网络连接
      if (!await _checkNetwork()) {
        _logger.w('[SyncService] 网络不可用');
        return SyncResult(
          success: false,
          message: '网络不可用',
          action: SyncAction.none,
        );
      }

      // 4. 获取配置并连接 WebDAV
      final config = await _configService.loadConfig();
      if (config == null) {
        throw SyncException('WebDAV 配置不存在');
      }

      final client = WebDAVClient(config);

      // 5. 获取远程备份列表和元数据（添加超时保护）
      final remoteBackups = await client.listBackupsWithMetadata()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              _logger.w('[SyncService] 获取远程备份列表超时');
              throw SyncException('获取远程备份列表超时，请检查网络连接');
            },
          );

      // 6. 比较本地和远程版本
      final comparison = await _compareVersions(remoteBackups);

      // 7. 根据比较结果执行操作
      switch (comparison.action) {
        case SyncAction.upload:
          _logger.i('[SyncService] 本地更新，上传到服务器');
          return await _uploadBackup(client);

        case SyncAction.download:
          _logger.i('[SyncService] 远程更新，下载并恢复');
          return await _downloadAndRestore(client, comparison);

        case SyncAction.conflict:
          _logger.w('[SyncService] 检测到冲突');
          return SyncResult(
            success: false,
            message: comparison.conflictReason ?? '检测到冲突',
            action: SyncAction.conflict,
            localMetadata: comparison.localMetadata,
            remoteMetadata: comparison.remoteMetadata,
          );

        case SyncAction.none:
          _logger.i('[SyncService] 已是最新');
          return SyncResult(
            success: true,
            message: '已是最新',
            action: SyncAction.none,
          );
      }
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 同步失败', error: e, stackTrace: stackTrace);
      await _stateManager.saveSyncState(SyncStatus(
        state: SyncState.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  /// 检查是否可以开始同步
  Future<bool> _canStartSync() async {
    // 检查是否已经在同步
    final currentState = await _stateManager.loadSyncState();
    if (currentState != null &&
        (currentState.state == SyncState.uploading ||
            currentState.state == SyncState.downloading)) {
      _logger.w('[SyncService] 已经在同步中');
      return false;
    }

    return true;
  }

  /// 检查网络连接
  Future<bool> _checkNetwork() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      _logger.e('[SyncService] 网络检查失败', error: e);
      return false;
    }
  }

  /// 版本比较逻辑
  Future<SyncComparison> _compareVersions(
    List<RemoteBackupWithMetadata> remoteBackups,
  ) async {
    _logger.d('[SyncService] 开始版本比较');

    // 获取本地最新备份（简化版：直接使用当前数据库）
    final localMetadata = await _getLocalMetadata();

    // 获取远程最新备份
    final remoteBackup =
        remoteBackups.isNotEmpty ? remoteBackups.first : null;
    final remoteMetadata = remoteBackup?.metadata;

    // 检查本地是否是空数据库（首次安装或跳过引导）
    final isLocalEmpty = await _isLocalDatabaseEmpty();

    // 处理初始状态
    if (localMetadata == null && remoteMetadata == null) {
      _logger.d('[SyncService] 本地和远程都无备份');
      return const SyncComparison(action: SyncAction.none);
    }

    // 如果本地是空数据库且远程有数据，直接下载
    if (isLocalEmpty && remoteMetadata != null) {
      _logger.d('[SyncService] 本地是空数据库，下载远程数据');
      return SyncComparison(
        action: SyncAction.download,
        remoteMetadata: remoteMetadata,
        remoteBackupPath: remoteBackup?.path,
      );
    }

    if (localMetadata == null) {
      _logger.d('[SyncService] 本地无备份，下载远程');
      return SyncComparison(
        action: SyncAction.download,
        remoteMetadata: remoteMetadata,
        remoteBackupPath: remoteBackup?.path,
      );
    }

    if (remoteMetadata == null) {
      _logger.d('[SyncService] 远程无备份，上传本地');
      return SyncComparison(
        action: SyncAction.upload,
        localMetadata: localMetadata,
      );
    }

    // 检查数据哈希
    if (localMetadata.dataHash == remoteMetadata.dataHash) {
      _logger.d('[SyncService] 数据哈希相同，已同步');
      return const SyncComparison(action: SyncAction.none);
    }

    // 检查是否是同一设备的更新
    if (localMetadata.deviceId == remoteMetadata.deviceId) {
      if (localMetadata.createdAt.isAfter(remoteMetadata.createdAt)) {
        _logger.d('[SyncService] 同一设备，本地更新');
        return SyncComparison(
          action: SyncAction.upload,
          localMetadata: localMetadata,
        );
      } else {
        _logger.d('[SyncService] 同一设备，远程更新');
        return SyncComparison(
          action: SyncAction.download,
          remoteMetadata: remoteMetadata,
          remoteBackupPath: remoteBackup?.path,
        );
      }
    }

    // 不同设备，检查基础版本
    if (localMetadata.baseBackupId == remoteMetadata.backupId) {
      _logger.d('[SyncService] 本地基于远程版本修改');
      return SyncComparison(
        action: SyncAction.upload,
        localMetadata: localMetadata,
      );
    }

    if (remoteMetadata.baseBackupId == localMetadata.backupId) {
      _logger.d('[SyncService] 远程基于本地版本修改');
      return SyncComparison(
        action: SyncAction.download,
        remoteMetadata: remoteMetadata,
        remoteBackupPath: remoteBackup?.path,
      );
    }

    // 真正的冲突
    _logger.w('[SyncService] 检测到冲突');
    return SyncComparison(
      action: SyncAction.conflict,
      localMetadata: localMetadata,
      remoteMetadata: remoteMetadata,
      conflictReason: '两个设备基于不同版本修改',
    );
  }

  /// 获取本地元数据
  Future<BackupMetadata?> _getLocalMetadata({String? backupId}) async {
    try {
      // 简化版：生成当前数据库的元数据
      final dbPath = await _backupService.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return null;
      }

      final bytes = await dbFile.readAsBytes();
      final dataHash = sha256.convert(bytes).toString();
      final fileSize = bytes.length;

      // 获取交易数量（简化版）
      final db = await _dbService.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions');
      final transactionCount = result.first['count'] as int;

      // 获取设备ID（持久化存储）
      final deviceId = await _getDeviceId();

      // 获取基础备份ID（用于版本追踪）
      final baseBackupId = await _getBaseBackupId();

      return BackupMetadata(
        backupId: backupId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        deviceId: deviceId,
        createdAt: DateTime.now(),
        transactionCount: transactionCount,
        dataHash: dataHash,
        fileSize: fileSize,
        appVersion: '1.0.0', // TODO: 从 package_info_plus 获取
        baseBackupId: baseBackupId,
      );
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 获取本地元数据失败',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 获取设备ID
  Future<String> _getDeviceId() async {
    try {
      final db = await _dbService.database;

      // 从 app_settings 表中获取设备ID
      final result = await db.query(
        'app_settings',
        where: 'setting_key = ?',
        whereArgs: ['device_id'],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final deviceId = result.first['setting_value'] as String;
        _logger.d('[SyncService] 使用已存在的设备ID: $deviceId');
        return deviceId;
      }

      // 生成新的设备ID并保存
      final newDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('app_settings', {
        'setting_key': 'device_id',
        'setting_value': newDeviceId,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });

      _logger.i('[SyncService] 生成新的设备ID: $newDeviceId');
      return newDeviceId;
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 获取设备ID失败', error: e, stackTrace: stackTrace);
      // 降级方案：使用固定前缀 + 时间戳
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// 保存基础备份ID
  ///
  /// 用于追踪本地数据基于哪个远程版本修改
  Future<void> _saveBaseBackupId(String backupId) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'app_settings',
        {
          'setting_key': 'base_backup_id',
          'setting_value': backupId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _logger.d('[SyncService] 保存基础备份ID: $backupId');
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 保存基础备份ID失败',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 获取基础备份ID
  Future<String?> _getBaseBackupId() async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        'app_settings',
        where: 'setting_key = ?',
        whereArgs: ['base_backup_id'],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final baseBackupId = result.first['setting_value'] as String;
        _logger.d('[SyncService] 获取基础备份ID: $baseBackupId');
        return baseBackupId;
      }

      return null;
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 获取基础备份ID失败',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 检查本地数据库是否为空（首次安装或跳过引导）
  Future<bool> _isLocalDatabaseEmpty() async {
    try {
      final db = await _dbService.database;

      // 检查关键表是否有数据
      final tables = [
        'transactions',
        'accounts',
        'family_groups',
        'family_members',
      ];

      for (final table in tables) {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        final count = result.first['count'] as int;
        if (count > 0) {
          _logger.d('[SyncService] 表 $table 有 $count 条数据，本地数据库非空');
          return false;
        }
      }

      _logger.d('[SyncService] 所有关键表都为空，本地数据库为空');
      return true;
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 检查本地数据库是否为空失败',
          error: e, stackTrace: stackTrace);
      // 出错时保守处理，认为非空
      return false;
    }
  }

  /// 上传备份
  Future<SyncResult> _uploadBackup(WebDAVClient client) async {
    try {
      _logger.i('[SyncService] 开始上传备份');

      await _stateManager.saveSyncState(const SyncStatus(
        state: SyncState.uploading,
        progress: 0.0,
      ));

      // 创建备份
      final backup = await _backupService.createBackup();

      // 生成元数据，使用备份的 ID 确保文件名一致
      final metadata = await _getLocalMetadata(backupId: backup.id);
      if (metadata == null) {
        throw SyncException('无法生成备份元数据');
      }

      // 确保远程目录存在
      await client.ensureRemoteDirectory();

      // 上传备份文件
      await client.uploadBackupWithProgress(
        File(backup.filePath),
        (sent, total) async {
          final progress = sent / total;
          await _stateManager.updateProgress(progress);
        },
      );

      // 上传元数据
      await client.uploadMetadata(metadata);

      // 保存基础备份ID，用于后续版本追踪
      await _saveBaseBackupId(metadata.backupId);

      _logger.i('[SyncService] 备份上传成功');

      await _stateManager.saveSyncState(SyncStatus(
        state: SyncState.success,
        lastSyncTime: DateTime.now(),
        localMetadata: metadata,
        remoteMetadata: metadata,
      ));

      return SyncResult(
        success: true,
        message: '同步成功',
        action: SyncAction.upload,
        localMetadata: metadata,
        remoteMetadata: metadata,
      );
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 上传备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 下载并恢复
  Future<SyncResult> _downloadAndRestore(
    WebDAVClient client,
    SyncComparison comparison,
  ) async {
    try {
      _logger.i('[SyncService] 开始下载并恢复备份');

      await _stateManager.saveSyncState(const SyncStatus(
        state: SyncState.downloading,
        progress: 0.0,
      ));

      // 获取临时路径
      final tempDir = await _backupService.getBackupDirectory();
      final tempPath = '${tempDir.path}/temp_download.db';

      // 下载备份文件
      final downloadedFile = await client.downloadBackupWithProgress(
        comparison.remoteBackupPath!,
        tempPath,
        (received, total) async {
          final progress = received / total;
          await _stateManager.updateProgress(progress);
        },
      );

      // 验证文件完整性
      _logger.d('[SyncService] 验证文件完整性');
      await _verifyBackupIntegrity(downloadedFile, comparison.remoteMetadata!);

      // 关闭数据库连接
      _logger.d('[SyncService] 关闭数据库连接');
      await _dbService.close();

      // 恢复备份
      await _stateManager.saveSyncState(const SyncStatus(
        state: SyncState.restoring,
        progress: 0.8,
      ));

      await _backupService.restoreBackup(downloadedFile.path);

      // 重新初始化数据库
      await _dbService.database;

      // 保存基础备份ID，用于后续版本追踪
      await _saveBaseBackupId(comparison.remoteMetadata!.backupId);

      // 删除临时文件
      await downloadedFile.delete();

      _logger.i('[SyncService] 备份恢复成功');

      await _stateManager.saveSyncState(SyncStatus(
        state: SyncState.success,
        lastSyncTime: DateTime.now(),
        localMetadata: comparison.remoteMetadata,
        remoteMetadata: comparison.remoteMetadata,
      ));

      return SyncResult(
        success: true,
        message: '同步成功',
        action: SyncAction.download,
        localMetadata: comparison.remoteMetadata,
        remoteMetadata: comparison.remoteMetadata,
      );
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 下载并恢复失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 验证备份文件完整性
  Future<void> _verifyBackupIntegrity(
    File backupFile,
    BackupMetadata metadata,
  ) async {
    // 验证文件大小
    final actualSize = await backupFile.length();
    if (actualSize != metadata.fileSize) {
      throw SyncException(
          '文件大小不匹配：期望 ${metadata.fileSize}，实际 $actualSize');
    }

    // 验证数据哈希
    final bytes = await backupFile.readAsBytes();
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != metadata.dataHash) {
      throw SyncException('文件哈希不匹配，可能被篡改');
    }

    _logger.d('[SyncService] 文件完整性验证通过');
  }

  /// 使用本地数据解决冲突
  ///
  /// 强制上传本地数据，覆盖远程数据
  Future<SyncResult> resolveConflictWithLocal() async {
    _logger.i('[SyncService] 使用本地数据解决冲突');

    try {
      // 获取配置并连接 WebDAV
      final config = await _configService.loadConfig();
      if (config == null) {
        throw SyncException('WebDAV 配置不存在');
      }

      final client = WebDAVClient(config);

      // 直接上传本地数据，不进行版本比较
      return await _uploadBackup(client);
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 使用本地数据解决冲突失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 使用远程数据解决冲突
  ///
  /// 强制下载远程数据，覆盖本地数据
  Future<SyncResult> resolveConflictWithRemote() async {
    _logger.i('[SyncService] 使用远程数据解决冲突');

    try {
      // 获取配置并连接 WebDAV
      final config = await _configService.loadConfig();
      if (config == null) {
        throw SyncException('WebDAV 配置不存在');
      }

      final client = WebDAVClient(config);

      // 获取远程备份列表
      final remoteBackups = await client.listBackupsWithMetadata();
      if (remoteBackups.isEmpty) {
        throw SyncException('远程没有可用的备份');
      }

      // 使用最新的远程备份
      final latestRemote = remoteBackups.first;
      final comparison = SyncComparison(
        action: SyncAction.download,
        remoteMetadata: latestRemote.metadata,
        remoteBackupPath: latestRemote.path,
      );

      // 直接下载并恢复，不进行版本比较
      return await _downloadAndRestore(client, comparison);
    } catch (e, stackTrace) {
      _logger.e('[SyncService] 使用远程数据解决冲突失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
