import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置状态管理
class SettingsProvider with ChangeNotifier {
  // 设置键常量
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultAccountId = 'default_account_id';
  static const String _keyDefaultCategoryId = 'default_category_id';
  static const String _keyAutoBackup = 'auto_backup';

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

  /// 初始化 - 从本地存储加载设置
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // 加载主题模式
      final themeModeString = prefs.getString(_keyThemeMode);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }

      // 加载其他设置
      _defaultAccountId = prefs.getInt(_keyDefaultAccountId);
      _defaultCategoryId = prefs.getInt(_keyDefaultCategoryId);
      _autoBackup = prefs.getBool(_keyAutoBackup) ?? false;

      _clearError();
    } catch (e) {
      _setError('加载设置失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.toString());
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
      final prefs = await SharedPreferences.getInstance();
      if (accountId != null) {
        await prefs.setInt(_keyDefaultAccountId, accountId);
      } else {
        await prefs.remove(_keyDefaultAccountId);
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
      final prefs = await SharedPreferences.getInstance();
      if (categoryId != null) {
        await prefs.setInt(_keyDefaultCategoryId, categoryId);
      } else {
        await prefs.remove(_keyDefaultCategoryId);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoBackup, enable);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyThemeMode);
      await prefs.remove(_keyDefaultAccountId);
      await prefs.remove(_keyDefaultCategoryId);
      await prefs.remove(_keyAutoBackup);

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
