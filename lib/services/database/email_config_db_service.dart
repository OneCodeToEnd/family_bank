import 'package:sqflite/sqflite.dart';
import '../../models/email_config.dart';
import '../../services/encryption/encryption_service.dart';
import 'database_service.dart';

/// 邮箱配置数据库服务
class EmailConfigDbService {
  final DatabaseService _dbService = DatabaseService();
  final EncryptionService _encryptionService = AESEncryptionService('family_bank_email_key');

  static const String tableName = 'email_configs';

  /// 创建邮箱配置表
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        imap_server TEXT NOT NULL,
        imap_port INTEGER NOT NULL,
        password TEXT NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// 创建或更新邮箱配置
  Future<EmailConfig> saveConfig(EmailConfig config) async {
    final db = await _dbService.database;

    // 加密密码
    final encryptedPassword = _encryptionService.encrypt(config.password);

    final now = DateTime.now();

    // 先查询是否存在相同邮箱地址的配置
    final existingByEmail = await db.query(
      tableName,
      where: 'email = ?',
      whereArgs: [config.email],
      limit: 1,
    );

    int id;
    DateTime createdAt;

    if (existingByEmail.isNotEmpty) {
      // 如果存在相同邮箱的配置，更新它
      final existingId = existingByEmail.first['id'] as int;
      createdAt = DateTime.fromMillisecondsSinceEpoch(
        existingByEmail.first['created_at'] as int,
      );

      final updateData = {
        'imap_server': config.imapServer,
        'imap_port': config.imapPort,
        'password': encryptedPassword,
        'is_enabled': 1,
        'updated_at': now.millisecondsSinceEpoch,
      };

      await db.update(
        tableName,
        updateData,
        where: 'id = ?',
        whereArgs: [existingId],
      );
      id = existingId;
    } else {
      // 如果不存在相同邮箱的配置，查询当前启用的配置
      final currentEnabled = await db.query(
        tableName,
        where: 'is_enabled = ?',
        whereArgs: [1],
        limit: 1,
      );

      if (currentEnabled.isNotEmpty) {
        // 如果有启用的配置，更新它（改变邮箱地址）
        final existingId = currentEnabled.first['id'] as int;
        createdAt = DateTime.fromMillisecondsSinceEpoch(
          currentEnabled.first['created_at'] as int,
        );

        final updateData = {
          'email': config.email,
          'imap_server': config.imapServer,
          'imap_port': config.imapPort,
          'password': encryptedPassword,
          'is_enabled': 1,
          'updated_at': now.millisecondsSinceEpoch,
        };

        await db.update(
          tableName,
          updateData,
          where: 'id = ?',
          whereArgs: [existingId],
        );
        id = existingId;
      } else {
        // 如果没有启用的配置，插入新配置
        createdAt = now;

        final insertData = {
          'email': config.email,
          'imap_server': config.imapServer,
          'imap_port': config.imapPort,
          'password': encryptedPassword,
          'is_enabled': 1,
          'created_at': createdAt.millisecondsSinceEpoch,
          'updated_at': now.millisecondsSinceEpoch,
        };

        id = await db.insert(tableName, insertData);
      }
    }

    // 禁用其他所有配置
    await db.update(
      tableName,
      {'is_enabled': 0},
      where: 'id != ?',
      whereArgs: [id],
    );

    return config.copyWith(
      id: id,
      password: encryptedPassword,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// 获取邮箱配置
  Future<EmailConfig?> getConfig() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'is_enabled = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    final config = EmailConfig.fromMap(maps.first);

    // 解密密码
    final decryptedPassword = _encryptionService.decrypt(config.password);

    return config.copyWith(password: decryptedPassword);
  }

  /// 获取所有邮箱配置
  Future<List<EmailConfig>> getAllConfigs() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'created_at DESC',
    );

    final configs = <EmailConfig>[];
    for (final map in maps) {
      final config = EmailConfig.fromMap(map);
      // 解密密码
      final decryptedPassword = _encryptionService.decrypt(config.password);
      configs.add(config.copyWith(password: decryptedPassword));
    }

    return configs;
  }

  /// 删除邮箱配置
  Future<void> deleteConfig(int id) async {
    final db = await _dbService.database;

    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新启用状态
  Future<void> updateEnabled(int id, bool isEnabled) async {
    final db = await _dbService.database;

    await db.update(
      tableName,
      {
        'is_enabled': isEnabled ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查是否已配置邮箱
  Future<bool> hasConfig() async {
    final config = await getConfig();
    return config != null;
  }
}
