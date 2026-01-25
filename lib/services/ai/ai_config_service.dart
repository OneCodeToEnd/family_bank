import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/ai_classification_config.dart';
import '../../models/ai_provider.dart';
import '../../constants/db_constants.dart';
import '../../constants/ai_model_constants.dart';
import '../database/database_service.dart';
import '../ai_model_config_service.dart';
import '../../utils/app_logger.dart';

/// AI 配置服务
///
/// 注意：此服务现在从新的 AIModelConfigService 读取配置，
/// 以确保模型管理界面的更新能够立即生效
class AIConfigService {
  final DatabaseService _dbService = DatabaseService();
  final AIModelConfigService _modelConfigService = AIModelConfigService();

  /// 获取数据库实例（每次调用时获取）
  Future<Database> get _db async => await _dbService.database;

  /// 保存配置到 app_settings 表
  Future<void> saveConfig(AIClassificationConfig config) async {
    final db = await _db;

    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [
      'ai_classification_config',
      jsonEncode(config.toJson(encrypt: true)), // API Key 自动加密
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  /// 从 app_settings 表读取配置
  ///
  /// 优先从新的 AIModelConfigService 读取激活的模型配置，
  /// 如果没有激活的模型，则回退到旧的配置系统
  Future<AIClassificationConfig> loadConfig() async {
    try {
      // 1. 尝试从新系统加载激活的模型
      await _modelConfigService.initialize();
      final activeModel = await _modelConfigService.getActiveModel();

      if (activeModel != null) {
        // 从激活的模型创建配置
        final apiKey = _modelConfigService.getDecryptedApiKey(activeModel);

        // 将 provider 字符串转换为 AIProvider 枚举
        AIProvider provider;
        switch (activeModel.provider) {
          case AIModelConstants.providerDeepSeek:
            provider = AIProvider.deepseek;
            break;
          case AIModelConstants.providerQwen:
            provider = AIProvider.qwen;
            break;
          default:
            provider = AIProvider.deepseek;
        }

        // 从旧系统加载其他配置（如提示词、阈值等）
        final oldConfig = await _loadLegacyConfig();

        return oldConfig.copyWith(
          enabled: true,
          provider: provider,
          apiKey: apiKey,
          modelId: activeModel.modelName,
        );
      }
    } catch (e) {
      AppLogger.w('Failed to load config from new model system, falling back to legacy', error: e);
    }

    // 2. 回退到旧系统
    return await _loadLegacyConfig();
  }

  /// 从旧的 app_settings 表读取配置
  Future<AIClassificationConfig> _loadLegacyConfig() async {
    final db = await _db;

    final result = await db.query(
      DbConstants.tableAppSettings,
      where: '${DbConstants.columnSettingKey} = ?',
      whereArgs: ['ai_classification_config'],
    );

    if (result.isEmpty) {
      return AIClassificationConfig(); // 返回默认配置
    }

    try {
      final json = jsonDecode(result.first[DbConstants.columnSettingValue] as String)
          as Map<String, dynamic>;
      return AIClassificationConfig.fromJson(json); // API Key 自动解密
    } catch (e) {
      AppLogger.e('Failed to load AI config', error: e);
      return AIClassificationConfig();
    }
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    final db = await _db;

    await db.delete(
      DbConstants.tableAppSettings,
      where: '${DbConstants.columnSettingKey} = ?',
      whereArgs: ['ai_classification_config'],
    );
  }

  /// 更新单个字段
  Future<void> updateField(String field, dynamic value) async {
    final config = await loadConfig();

    AIClassificationConfig updated;
    switch (field) {
      case 'enabled':
        updated = config.copyWith(enabled: value as bool);
        break;
      case 'provider':
        updated = config.copyWith(provider: value as AIProvider);
        break;
      case 'api_key':
        updated = config.copyWith(apiKey: value as String);
        break;
      case 'model_id':
        updated = config.copyWith(modelId: value as String);
        break;
      case 'confidence_threshold':
        updated = config.copyWith(confidenceThreshold: value as double);
        break;
      case 'auto_learn':
        updated = config.copyWith(autoLearn: value as bool);
        break;
      default:
        return;
    }

    await saveConfig(updated);
  }

  /// 检查是否已配置
  Future<bool> isConfigured() async {
    final config = await loadConfig();
    return config.enabled &&
        config.apiKey.isNotEmpty &&
        config.modelId.isNotEmpty;
  }
}
