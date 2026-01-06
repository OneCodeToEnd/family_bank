import '../../models/ai_provider.dart';
import '../../models/ai_classification_config.dart';
import 'ai_classifier_service.dart';
import 'deepseek_classifier_service.dart';
import 'qwen_classifier_service.dart';

/// AI 分类服务工厂
class AIClassifierFactory {
  static AIClassifierService create(
    AIProvider provider,
    String apiKey,
    String modelId,
    AIClassificationConfig config,
  ) {
    switch (provider) {
      case AIProvider.deepseek:
        return DeepSeekClassifierService(apiKey, modelId, config);
      case AIProvider.qwen:
        return QwenClassifierService(apiKey, modelId, config);
    }
  }
}
