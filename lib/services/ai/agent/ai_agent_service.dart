import '../../../models/chat_message.dart';
import '../../ai_model_config_service.dart';
import '../../../utils/app_logger.dart';
import 'openai_agent_service.dart';

/// Agent 消息回调，用于逐步更新 UI
typedef OnMessageCallback = void Function(ChatMessage message);

/// AI Agent 服务抽象接口
abstract class AIAgentService {
  /// 发送聊天消息，通过回调逐步返回中间结果
  Future<void> chat({
    required List<ChatMessage> history,
    required String userMessage,
    required OnMessageCallback onMessage,
  });
}

/// Agent 工厂
class AIAgentFactory {
  static Future<AIAgentService?> create() async {
    final configService = AIModelConfigService();
    final model = await configService.getActiveModel();
    if (model == null) {
      AppLogger.w('No active AI model configured');
      return null;
    }

    final apiKey = configService.getDecryptedApiKey(model);
    final baseUrl = model.baseUrl ?? '';
    final modelName = model.modelName;

    return OpenAIAgentService(
      apiKey: apiKey,
      baseUrl: baseUrl,
      modelName: modelName,
    );
  }
}
