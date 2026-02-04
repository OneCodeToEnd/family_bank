import 'dart:convert';
import '../../models/backup/backup_info.dart';
import '../../models/backup/backup_settings.dart';
import '../../utils/app_logger.dart';
import '../../services/database/database_service.dart';
import '../../constants/db_constants.dart';
import 'backup_service.dart';

/// 自动备份服务
/// 负责定时自动备份和备份设置管理
class AutoBackupService {
  static final AutoBackupService _instance = AutoBackupService._internal();
  factory AutoBackupService() => _instance;
  AutoBackupService._internal();

  final _backupService = BackupService();
  final _dbService = DatabaseService();

  static const String _settingsKey = 'backup_settings';

  /// 获取备份设置
  Future<BackupSettings> getSettings() async {
    try {
      final db = await _dbService.database;

      // 从 app_settings 表查询配置
      final result = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_settingsKey],
      );

      if (result.isEmpty) {
        // 没有配置，返回默认设置
        return BackupSettings();
      }

      // 解析 JSON
      final jsonStr = result.first[DbConstants.columnSettingValue] as String;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BackupSettings.fromJson(json);
    } catch (e, stackTrace) {
      AppLogger.e('[AutoBackupService] 获取备份设置失败', error: e, stackTrace: stackTrace);
      return BackupSettings();
    }
  }

  /// 保存备份设置
  Future<void> saveSettings(BackupSettings settings) async {
    try {
      final db = await _dbService.database;

      // 转换为 JSON 字符串
      final jsonStr = jsonEncode(settings.toJson());

      // 使用 INSERT OR REPLACE 保存到数据库
      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [
        _settingsKey,
        jsonStr,
        DateTime.now().millisecondsSinceEpoch,
      ]);

      AppLogger.d('[AutoBackupService] 备份设置已保存');
    } catch (e, stackTrace) {
      AppLogger.e('[AutoBackupService] 保存备份设置失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 检查并执行自动备份
  /// 返回是否执行了备份
  Future<bool> checkAndBackup() async {
    try {
      final settings = await getSettings();

      if (!settings.autoBackupEnabled) {
        AppLogger.d('[AutoBackupService] 自动备份未启用');
        return false;
      }

      // 检查是否需要备份
      if (!_shouldBackup(settings)) {
        AppLogger.d('[AutoBackupService] 尚未到备份时间');
        return false;
      }

      AppLogger.i('[AutoBackupService] 开始执行自动备份');

      // 执行备份
      final backupInfo = await _backupService.createBackup(
        type: BackupType.auto,
      );

      // 清理旧备份
      await _backupService.cleanOldBackups(
        keepCount: settings.keepBackupCount,
      );

      // 更新最后备份时间
      final newSettings = settings.copyWith(
        lastBackupTime: DateTime.now(),
        lastBackupPath: backupInfo.filePath,
      );
      await saveSettings(newSettings);

      AppLogger.i('[AutoBackupService] 自动备份完成');

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('[AutoBackupService] 自动备份失败', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 判断是否应该执行备份
  bool _shouldBackup(BackupSettings settings) {
    if (settings.lastBackupTime == null) {
      return true;
    }

    final now = DateTime.now();
    final daysSinceLastBackup = now.difference(settings.lastBackupTime!).inDays;

    return daysSinceLastBackup >= settings.backupIntervalDays;
  }

  /// 立即执行备份（忽略时间间隔）
  Future<BackupInfo> backupNow() async {
    try {
      AppLogger.i('[AutoBackupService] 立即执行备份');

      final backupInfo = await _backupService.createBackup(
        type: BackupType.manual,
      );

      // 更新最后备份时间
      final settings = await getSettings();
      final newSettings = settings.copyWith(
        lastBackupTime: DateTime.now(),
        lastBackupPath: backupInfo.filePath,
      );
      await saveSettings(newSettings);

      return backupInfo;
    } catch (e, stackTrace) {
      AppLogger.e('[AutoBackupService] 立即备份失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
