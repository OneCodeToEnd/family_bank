import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../../models/sync/sync_status.dart';
import '../../constants/db_constants.dart';
import '../database/database_service.dart';

/// 同步状态管理器
///
/// 管理同步状态的持久化和恢复
/// 状态存储在 app_settings 表中
class SyncStateManager {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger();

  static const String _statusKey = 'webdav_sync_status';

  /// 获取数据库实例
  Future<Database> get _db async => await _dbService.database;

  /// 保存同步状态
  Future<void> saveSyncState(SyncStatus status) async {
    try {
      final db = await _db;

      _logger.d('[SyncStateManager] 保存同步状态: ${status.state}');

      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [
        _statusKey,
        jsonEncode(status.toJson()),
        DateTime.now().millisecondsSinceEpoch,
      ]);

      _logger.d('[SyncStateManager] 同步状态保存成功');
    } catch (e, stackTrace) {
      _logger.e('[SyncStateManager] 保存同步状态失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 加载同步状态
  Future<SyncStatus?> loadSyncState() async {
    try {
      final db = await _db;

      _logger.d('[SyncStateManager] 加载同步状态');

      final results = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_statusKey],
        limit: 1,
      );

      if (results.isEmpty) {
        _logger.d('[SyncStateManager] 未找到同步状态');
        return null;
      }

      final jsonString = results.first[DbConstants.columnSettingValue] as String;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final status = SyncStatus.fromJson(json);

      _logger.d('[SyncStateManager] 同步状态加载成功: ${status.state}');
      return status;
    } catch (e, stackTrace) {
      _logger.e('[SyncStateManager] 加载同步状态失败',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 清除同步状态
  Future<void> clearSyncState() async {
    try {
      final db = await _db;

      _logger.i('[SyncStateManager] 清除同步状态');

      await db.delete(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_statusKey],
      );

      _logger.i('[SyncStateManager] 同步状态清除成功');
    } catch (e, stackTrace) {
      _logger.e('[SyncStateManager] 清除同步状态失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 更新同步进度
  Future<void> updateProgress(double progress) async {
    try {
      final currentStatus = await loadSyncState();
      if (currentStatus != null) {
        final updatedStatus = currentStatus.copyWith(progress: progress);
        await saveSyncState(updatedStatus);
      }
    } catch (e, stackTrace) {
      _logger.e('[SyncStateManager] 更新进度失败',
          error: e, stackTrace: stackTrace);
    }
  }

  /// 更新同步状态（仅状态）
  Future<void> updateState(SyncState state) async {
    try {
      final currentStatus = await loadSyncState();
      final updatedStatus = (currentStatus ?? const SyncStatus()).copyWith(
        state: state,
        lastSyncTime: state == SyncState.success ? DateTime.now() : null,
      );
      await saveSyncState(updatedStatus);
    } catch (e, stackTrace) {
      _logger.e('[SyncStateManager] 更新状态失败',
          error: e, stackTrace: stackTrace);
    }
  }
}
