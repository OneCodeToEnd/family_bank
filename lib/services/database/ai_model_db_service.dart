import 'package:sqflite/sqflite.dart';
import '../../models/ai_model_config.dart';
import '../../constants/db_constants.dart';
import '../encryption/encryption_service.dart';
import 'database_service.dart';

/// AI模型配置数据库服务
class AIModelDbService {
  final DatabaseService _dbService = DatabaseService();
  final EncryptionService _encryptionService =
      AESEncryptionService('family_bank_ai_key');

  /// 保存 AI 模型配置
  Future<void> saveModel(AIModelConfig model) async {
    final db = await _dbService.database;
    await db.insert(
      DbConstants.tableAIModels,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有 AI 模型配置
  Future<List<AIModelConfig>> getAllModels() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAIModels,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return AIModelConfig.fromMap(maps[i]);
    });
  }

  /// 根据 ID 获取模型配置
  Future<AIModelConfig?> getModelById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAIModels,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return AIModelConfig.fromMap(maps.first);
  }

  /// 获取当前激活的模型配置
  Future<AIModelConfig?> getActiveModel() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAIModels,
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return AIModelConfig.fromMap(maps.first);
  }

  /// 设置激活的模型（同时取消其他模型的激活状态）
  Future<void> setActiveModel(String id) async {
    final db = await _dbService.database;

    await db.transaction((txn) async {
      // 取消所有模型的激活状态
      await txn.update(
        DbConstants.tableAIModels,
        {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      );

      // 激活指定模型
      await txn.update(
        DbConstants.tableAIModels,
        {'is_active': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// 更新模型配置
  Future<void> updateModel(AIModelConfig model) async {
    final db = await _dbService.database;
    await db.update(
      DbConstants.tableAIModels,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  /// 删除模型配置
  Future<void> deleteModel(String id) async {
    final db = await _dbService.database;
    await db.delete(
      DbConstants.tableAIModels,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 检查是否存在相同的 provider 和 model_name
  Future<bool> existsModel(String provider, String modelName,
      {String? excludeId}) async {
    final db = await _dbService.database;

    String whereClause = 'provider = ? AND model_name = ?';
    List<dynamic> whereArgs = [provider, modelName];

    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAIModels,
      where: whereClause,
      whereArgs: whereArgs,
    );

    return maps.isNotEmpty;
  }

  /// 解密 API Key
  String decryptApiKey(String encryptedApiKey) {
    return _encryptionService.decrypt(encryptedApiKey);
  }

  /// 加密 API Key
  String encryptApiKey(String apiKey) {
    return _encryptionService.encrypt(apiKey);
  }
}
