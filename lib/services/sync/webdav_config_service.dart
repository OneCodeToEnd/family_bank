import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import '../../models/sync/webdav_config.dart';
import '../../constants/db_constants.dart';
import '../database/database_service.dart';
import '../encryption/encryption_service.dart';
import 'webdav_client.dart';

/// WebDAV 配置管理服务
///
/// 管理 WebDAV 配置的保存、加载和验证
/// 配置存储在 app_settings 表中，密码使用 AES 加密
class WebDAVConfigService {
  final DatabaseService _dbService = DatabaseService();
  final Logger _logger = Logger();
  final EncryptionService _encryptionService =
      AESEncryptionService('family_bank_webdav_key_v1');

  static const String _configKey = 'webdav_sync_config';

  /// 获取数据库实例
  Future<Database> get _db async => await _dbService.database;

  /// 保存配置到 app_settings 表
  Future<void> saveConfig(WebDAVConfig config) async {
    try {
      final db = await _db;

      _logger.i('[WebDAVConfigService] 保存 WebDAV 配置');

      // 加密密码
      final encryptedPassword = _encryptionService.encrypt(config.password);
      final configWithEncryptedPassword = config.copyWith(
        password: encryptedPassword,
      );

      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [
        _configKey,
        jsonEncode(configWithEncryptedPassword.toJson()),
        DateTime.now().millisecondsSinceEpoch,
      ]);

      _logger.i('[WebDAVConfigService] WebDAV 配置保存成功（密码已加密）');
    } catch (e, stackTrace) {
      _logger.e('[WebDAVConfigService] 保存配置失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 从 app_settings 表加载配置
  Future<WebDAVConfig?> loadConfig() async {
    try {
      final db = await _db;

      _logger.d('[WebDAVConfigService] 加载 WebDAV 配置');

      final results = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_configKey],
        limit: 1,
      );

      if (results.isEmpty) {
        _logger.d('[WebDAVConfigService] 未找到 WebDAV 配置');
        return null;
      }

      final jsonString = results.first[DbConstants.columnSettingValue] as String;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = WebDAVConfig.fromJson(json);

      // 解密密码
      final decryptedPassword = _encryptionService.decrypt(config.password);
      final configWithDecryptedPassword = config.copyWith(
        password: decryptedPassword,
      );

      _logger.i('[WebDAVConfigService] WebDAV 配置加载成功（密码已解密）');
      return configWithDecryptedPassword;
    } catch (e, stackTrace) {
      _logger.e('[WebDAVConfigService] 加载配置失败',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    try {
      final db = await _db;

      _logger.i('[WebDAVConfigService] 删除 WebDAV 配置');

      await db.delete(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_configKey],
      );

      _logger.i('[WebDAVConfigService] WebDAV 配置删除成功');
    } catch (e, stackTrace) {
      _logger.e('[WebDAVConfigService] 删除配置失败',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 测试连接
  Future<bool> testConnection(WebDAVConfig config) async {
    try {
      _logger.i('[WebDAVConfigService] 测试 WebDAV 连接');

      final client = WebDAVClient(config);
      final result = await client.testConnection();

      if (result) {
        _logger.i('[WebDAVConfigService] 连接测试成功');
        // 确保远程目录存在
        await client.ensureRemoteDirectory();
      } else {
        _logger.w('[WebDAVConfigService] 连接测试失败');
      }

      return result;
    } catch (e, stackTrace) {
      _logger.e('[WebDAVConfigService] 测试连接失败',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 验证配置
  bool validateConfig(WebDAVConfig config) {
    if (config.serverUrl.isEmpty) {
      _logger.w('[WebDAVConfigService] 服务器地址为空');
      return false;
    }

    if (config.username.isEmpty) {
      _logger.w('[WebDAVConfigService] 用户名为空');
      return false;
    }

    if (config.password.isEmpty) {
      _logger.w('[WebDAVConfigService] 密码为空');
      return false;
    }

    if (config.remotePath.isEmpty) {
      _logger.w('[WebDAVConfigService] 远程路径为空');
      return false;
    }

    // 验证 URL 格式
    try {
      final uri = Uri.parse(config.serverUrl);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        _logger.w('[WebDAVConfigService] 无效的 URL 格式');
        return false;
      }
    } catch (e) {
      _logger.w('[WebDAVConfigService] URL 解析失败: $e');
      return false;
    }

    return true;
  }
}
