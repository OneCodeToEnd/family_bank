import '../../../models/chat_message.dart';
import '../../ai_model_config_service.dart';
import '../../database/agent_memory_db_service.dart';
import '../../../utils/app_logger.dart';
import 'openai_agent_service.dart';

/// Agent 消息回调，用于逐步更新 UI
typedef OnMessageCallback = void Function(ChatMessage message);

/// 反馈总结结果
class FeedbackSummary {
  final String content;
  final String relatedQuery;

  const FeedbackSummary({required this.content, required this.relatedQuery});
}

/// AI Agent 服务抽象接口
abstract class AIAgentService {
  /// 发送聊天消息，通过回调逐步返回中间结果
  Future<void> chat({
    required List<ChatMessage> history,
    required String userMessage,
    required OnMessageCallback onMessage,
  });

  /// 总结用户反馈为可存储的记忆
  /// [feedbackType] 'like' 或 'dislike'
  /// [context] 包含完整推理链的上下文文本
  /// 返回包含记忆内容和问题摘要的结构化结果，失败返回 null
  Future<FeedbackSummary?> summarizeFeedback({
    required String feedbackType,
    required String context,
  });

  /// 根据首轮对话生成会话标题
  Future<String?> generateTitle({
    required String firstUserMessage,
    required String firstAssistantReply,
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

    // 加载记忆
    final memories = await AgentMemoryDbService().getRecent();

    return OpenAIAgentService(
      apiKey: apiKey,
      baseUrl: baseUrl,
      modelName: modelName,
      memories: memories,
    );
  }
}
