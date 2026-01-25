import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_model_config.dart';
import '../constants/ai_model_constants.dart';
import '../utils/app_logger.dart';
import 'database/ai_model_db_service.dart';

class AIModelConfigService {
  final AIModelDbService _dbService = AIModelDbService();
  final Uuid _uuid = const Uuid();

  static const String _prefKeyDeepSeekApiKey = 'deepseek_api_key';
  static const String _prefKeyQwenApiKey = 'qwen_api_key';
  static const String _prefKeyMigrated = 'ai_model_config_migrated';

  /// 初始化服务（执行配置迁移）
  Future<void> initialize() async {
    await _migrateFromSharedPreferences();
  }

  /// 从 SharedPreferences 迁移配置到数据库
  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // 检查是否已经迁移过
    final migrated = prefs.getBool(_prefKeyMigrated) ?? false;
    if (migrated) {
      return;
    }

    try {
      // 迁移 DeepSeek 配置
      final deepSeekApiKey = prefs.getString(_prefKeyDeepSeekApiKey);
      if (deepSeekApiKey != null && deepSeekApiKey.isNotEmpty) {
        await _migrateDeepSeekConfig(deepSeekApiKey);
      }

      // 迁移 Qwen 配置
      final qwenApiKey = prefs.getString(_prefKeyQwenApiKey);
      if (qwenApiKey != null && qwenApiKey.isNotEmpty) {
        await _migrateQwenConfig(qwenApiKey);
      }

      // 标记为已迁移
      await prefs.setBool(_prefKeyMigrated, true);
    } catch (e) {
      AppLogger.w('Configuration migration failed', error: e);
      // Migration failure does not affect normal use
    }
  }

  /// 迁移 DeepSeek 配置
  Future<void> _migrateDeepSeekConfig(String apiKey) async {
    final exists = await _dbService.existsModel(
      AIModelConstants.providerDeepSeek,
      AIModelConstants.deepSeekDefaultModel,
    );

    if (!exists) {
      final encryptedApiKey = _dbService.encryptApiKey(apiKey);
      final model = AIModelConfig(
        id: _uuid.v4(),
        name: 'DeepSeek Chat (Migrated)',
        provider: AIModelConstants.providerDeepSeek,
        modelName: AIModelConstants.deepSeekDefaultModel,
        encryptedApiKey: encryptedApiKey,
        baseUrl: AIModelConstants.deepSeekDefaultBaseUrl,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.saveModel(model);
    }
  }

  /// 迁移 Qwen 配置
  Future<void> _migrateQwenConfig(String apiKey) async {
    final exists = await _dbService.existsModel(
      AIModelConstants.providerQwen,
      AIModelConstants.qwenDefaultModel,
    );

    if (!exists) {
      final encryptedApiKey = _dbService.encryptApiKey(apiKey);
      final model = AIModelConfig(
        id: _uuid.v4(),
        name: 'Qwen Turbo (Migrated)',
        provider: AIModelConstants.providerQwen,
        modelName: AIModelConstants.qwenDefaultModel,
        encryptedApiKey: encryptedApiKey,
        baseUrl: AIModelConstants.qwenDefaultBaseUrl,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.saveModel(model);
    }
  }

  /// 创建新的 AI 模型配置
  Future<AIModelConfig> createModel({
    required String name,
    required String provider,
    required String modelName,
    required String apiKey,
    String? baseUrl,
    bool isActive = false,
  }) async {
    // 检查是否已存在相同的配置
    final exists = await _dbService.existsModel(provider, modelName);
    if (exists) {
      throw Exception('Model configuration already exists');
    }

    // 加密 API Key
    final encryptedApiKey = _dbService.encryptApiKey(apiKey);

    // 创建模型配置
    final model = AIModelConfig(
      id: _uuid.v4(),
      name: name,
      provider: provider,
      modelName: modelName,
      encryptedApiKey: encryptedApiKey,
      baseUrl: baseUrl,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 保存到数据库
    await _dbService.saveModel(model);

    // 如果设置为激活，需要取消其他模型的激活状态
    if (isActive) {
      await _dbService.setActiveModel(model.id);
    }

    return model;
  }

  /// 更新 AI 模型配置
  Future<void> updateModel({
    required String id,
    String? name,
    String? apiKey,
    String? baseUrl,
    bool? isActive,
  }) async {
    final model = await _dbService.getModelById(id);
    if (model == null) {
      throw Exception('Model configuration not found');
    }

    // 准备更新的数据
    String? encryptedApiKey;
    if (apiKey != null) {
      encryptedApiKey = _dbService.encryptApiKey(apiKey);
    }

    final updatedModel = model.copyWith(
      name: name,
      encryptedApiKey: encryptedApiKey,
      baseUrl: baseUrl,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    await _dbService.updateModel(updatedModel);

    // 如果设置为激活，需要取消其他模型的激活状态
    if (isActive == true) {
      await _dbService.setActiveModel(id);
    }
  }

  /// 删除 AI 模型配置
  Future<void> deleteModel(String id) async {
    await _dbService.deleteModel(id);
  }

  /// 获取所有模型配置
  Future<List<AIModelConfig>> getAllModels() async {
    return await _dbService.getAllModels();
  }

  /// 获取当前激活的模型配置
  Future<AIModelConfig?> getActiveModel() async {
    return await _dbService.getActiveModel();
  }

  /// 获取当前激活模型的解密后的 API Key
  Future<String?> getActiveApiKey() async {
    final model = await getActiveModel();
    if (model == null) {
      return null;
    }
    return _dbService.decryptApiKey(model.encryptedApiKey);
  }

  /// 设置激活的模型
  Future<void> setActiveModel(String id) async {
    await _dbService.setActiveModel(id);
  }

  /// 获取模型的解密后的 API Key
  String getDecryptedApiKey(AIModelConfig model) {
    return _dbService.decryptApiKey(model.encryptedApiKey);
  }
}
