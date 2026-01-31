import '../../models/ai_model_config.dart';
import '../../models/ai_classification_config.dart';
import '../../models/ai_provider.dart';
import 'ai_classifier_factory.dart';

/// AI模型测试结果
class AIModelTestResult {
  final bool success;
  final String message;
  final String? errorDetails;

  AIModelTestResult({
    required this.success,
    required this.message,
    this.errorDetails,
  });

  factory AIModelTestResult.success() {
    return AIModelTestResult(
      success: true,
      message: '✓ 连接成功',
    );
  }

  factory AIModelTestResult.failure(String error, {String? details}) {
    return AIModelTestResult(
      success: false,
      message: '✗ 连接失败: $error',
      errorDetails: details,
    );
  }
}

/// AI模型测试服务
///
/// 提供统一的AI模型连接测试功能，支持：
/// 1. 从 AIModelConfig 测试（用于模型管理页面）
/// 2. 从临时配置测试（用于AI分类设置页面）
class AIModelTestService {
  /// 测试 AIModelConfig 配置
  ///
  /// 用于AI模型管理页面，测试已保存的模型配置
  Future<AIModelTestResult> testModelConfig(
    AIModelConfig config,
    String decryptedApiKey,
  ) async {
    try {
      // 将 provider 字符串映射到 AIProvider 枚举
      final provider = _mapProviderStringToEnum(config.provider);
      if (provider == null) {
        return AIModelTestResult.failure(
          '不支持的提供商: ${config.provider}',
        );
      }

      // 创建临时配置用于测试
      final tempConfig = AIClassificationConfig(
        enabled: true,
        provider: provider,
        apiKey: decryptedApiKey,
        modelId: config.modelName,
        confidenceThreshold: 0.7,
        autoLearn: false,
      );

      // 使用统一的测试方法
      return await testWithCredentials(
        provider: provider,
        apiKey: decryptedApiKey,
        modelId: config.modelName,
        baseUrl: config.baseUrl,
        config: tempConfig,
      );
    } catch (e) {
      return AIModelTestResult.failure(
        e.toString(),
        details: e.toString(),
      );
    }
  }

  /// 使用临时凭证测试连接
  ///
  /// 用于AI分类设置页面，测试用户输入的配置
  Future<AIModelTestResult> testWithCredentials({
    required AIProvider provider,
    required String apiKey,
    required String modelId,
    String? baseUrl,
    AIClassificationConfig? config,
  }) async {
    if (apiKey.isEmpty) {
      return AIModelTestResult.failure('请先输入 API Key');
    }

    if (modelId.isEmpty) {
      return AIModelTestResult.failure('请先选择模型');
    }

    try {
      // 创建临时配置（如果未提供）
      final testConfig = config ??
          AIClassificationConfig(
            enabled: true,
            provider: provider,
            apiKey: apiKey,
            modelId: modelId,
            confidenceThreshold: 0.7,
            autoLearn: false,
          );

      // 创建分类器服务
      final service = AIClassifierFactory.create(
        provider,
        apiKey,
        modelId,
        testConfig,
      );

      // 执行测试连接
      final success = await service.testConnection();

      if (success) {
        return AIModelTestResult.success();
      } else {
        return AIModelTestResult.failure('请检查 API Key 和模型配置');
      }
    } catch (e) {
      return AIModelTestResult.failure(
        e.toString(),
        details: e.toString(),
      );
    }
  }

  /// 将 provider 字符串映射到 AIProvider 枚举
  AIProvider? _mapProviderStringToEnum(String provider) {
    switch (provider.toLowerCase()) {
      case 'deepseek':
        return AIProvider.deepseek;
      case 'qwen':
        return AIProvider.qwen;
      default:
        return null;
    }
  }
}
