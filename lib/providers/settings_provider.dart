import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database/database_service.dart';
import '../constants/db_constants.dart';

/// 设置状态管理
class SettingsProvider with ChangeNotifier {
  // 设置键常量
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultAccountId = 'default_account_id';
  static const String _keyDefaultCategoryId = 'default_category_id';
  static const String _keyAutoBackup = 'auto_backup';
  static const String _keyMigrated = 'settings_migrated_to_db';

  final DatabaseService _dbService = DatabaseService();

  // 设置数据
  ThemeMode _themeMode = ThemeMode.system;
  int? _defaultAccountId;
  int? _defaultCategoryId;
  bool _autoBackup = false;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  ThemeMode get themeMode => _themeMode;
  int? get defaultAccountId => _defaultAccountId;
  int? get defaultCategoryId => _defaultCategoryId;
  bool get autoBackup => _autoBackup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 初始化 - 从数据库加载设置
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // 首次运行时从 SharedPreferences 迁移数据
      await _migrateFromSharedPreferences();

      final db = await _dbService.database;

      // 加载主题模式
      final themeModeResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyThemeMode],
      );
      if (themeModeResult.isNotEmpty) {
        final themeModeString = themeModeResult.first[DbConstants.columnSettingValue] as String;
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }

      // 加载默认账户ID
      final accountResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyDefaultAccountId],
      );
      if (accountResult.isNotEmpty) {
        _defaultAccountId = int.tryParse(
          accountResult.first[DbConstants.columnSettingValue] as String,
        );
      }

      // 加载默认分类ID
      final categoryResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyDefaultCategoryId],
      );
      if (categoryResult.isNotEmpty) {
        _defaultCategoryId = int.tryParse(
          categoryResult.first[DbConstants.columnSettingValue] as String,
        );
      }

      // 加载自动备份开关
      final backupResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyAutoBackup],
      );
      if (backupResult.isNotEmpty) {
        _autoBackup = backupResult.first[DbConstants.columnSettingValue] == '1';
      }

      _clearError();
    } catch (e) {
      _setError('加载设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 从 SharedPreferences 迁移数据到数据库（一次性操作）
  Future<void> _migrateFromSharedPreferences() async {
    try {
      final db = await _dbService.database;

      // 检查是否已经迁移过
      final migratedResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyMigrated],
      );

      if (migratedResult.isNotEmpty) {
        return; // 已经迁移过
      }

      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // 迁移主题模式
      final themeModeString = prefs.getString(_keyThemeMode);
      if (themeModeString != null) {
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyThemeMode, themeModeString, now]);
      }

      // 迁移默认账户ID
      final defaultAccountId = prefs.getInt(_keyDefaultAccountId);
      if (defaultAccountId != null) {
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyDefaultAccountId, defaultAccountId.toString(), now]);
      }

      // 迁移默认分类ID
      final defaultCategoryId = prefs.getInt(_keyDefaultCategoryId);
      if (defaultCategoryId != null) {
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyDefaultCategoryId, defaultCategoryId.toString(), now]);
      }

      // 迁移自动备份开关
      final autoBackup = prefs.getBool(_keyAutoBackup);
      if (autoBackup != null) {
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyAutoBackup, autoBackup ? '1' : '0', now]);
      }

      // 标记为已迁移
      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [_keyMigrated, '1', now]);
    } catch (e) {
      // 迁移失败不影响正常使用
      debugPrint('Settings migration failed: $e');
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _setLoading(true);
    try {
      final db = await _dbService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [_keyThemeMode, mode.toString(), now]);

      _themeMode = mode;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('保存主题设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置默认账户
  Future<void> setDefaultAccount(int? accountId) async {
    _setLoading(true);
    try {
      final db = await _dbService.database;

      if (accountId != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyDefaultAccountId, accountId.toString(), now]);
      } else {
        await db.delete(
          DbConstants.tableAppSettings,
          where: '${DbConstants.columnSettingKey} = ?',
          whereArgs: [_keyDefaultAccountId],
        );
      }

      _defaultAccountId = accountId;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('保存默认账户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置默认分类
  Future<void> setDefaultCategory(int? categoryId) async {
    _setLoading(true);
    try {
      final db = await _dbService.database;

      if (categoryId != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.rawInsert('''
          INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
            (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
          VALUES (?, ?, ?)
        ''', [_keyDefaultCategoryId, categoryId.toString(), now]);
      } else {
        await db.delete(
          DbConstants.tableAppSettings,
          where: '${DbConstants.columnSettingKey} = ?',
          whereArgs: [_keyDefaultCategoryId],
        );
      }

      _defaultCategoryId = categoryId;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('保存默认分类失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置自动备份开关
  Future<void> setAutoBackup(bool enable) async {
    _setLoading(true);
    try {
      final db = await _dbService.database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [_keyAutoBackup, enable ? '1' : '0', now]);

      _autoBackup = enable;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('保存自动备份设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 重置所有设置
  Future<void> resetAllSettings() async {
    _setLoading(true);
    try {
      final db = await _dbService.database;

      await db.delete(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} IN (?, ?, ?, ?)',
        whereArgs: [
          _keyThemeMode,
          _keyDefaultAccountId,
          _keyDefaultCategoryId,
          _keyAutoBackup,
        ],
      );

      _themeMode = ThemeMode.system;
      _defaultAccountId = null;
      _defaultCategoryId = null;
      _autoBackup = false;

      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('重置设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== 辅助方法 ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

}
