import 'package:flutter/foundation.dart';
import '../../models/backup/backup_info.dart';
import '../../models/backup/backup_settings.dart';
import '../../services/backup/backup_service.dart';
import '../../services/backup/export_import_service.dart';
import '../../services/backup/auto_backup_service.dart';
import '../../utils/app_logger.dart';

/// 备份状态管理
class BackupProvider with ChangeNotifier {
  final _backupService = BackupService();
  final _exportImportService = ExportImportService();
  final _autoBackupService = AutoBackupService();

  List<BackupInfo> _backups = [];
  BackupSettings _settings = BackupSettings();
  bool _isLoading = false;
  String? _errorMessage;

  List<BackupInfo> get backups => _backups;
  BackupSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
}
