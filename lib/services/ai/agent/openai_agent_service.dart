import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/chat_message.dart';
import '../../../utils/app_logger.dart';
import '../../http/logging_http_client.dart';
import 'ai_agent_service.dart';
import 'agent_tool.dart';
import 'database_tools.dart';

/// 统一的 OpenAI 兼容 Agent 实现（DeepSeek/Qwen 共用）
class OpenAIAgentService implements AIAgentService {
  final String apiKey;
  final String baseUrl;
  final String modelName;
  final http.Client _client;
  final List<AgentTool> _tools;

  static const int _maxIterations = 10;
  static const Duration _timeout = Duration(seconds: 60);

  static const String _systemPrompt = '''你是一个家庭记账应用的智能数据分析助手。
你可以通过工具查询数据库来回答用户关于收支、账户、分类等方面的问题。

工作流程：
1. 如果用户问题涉及时间（如"这个月"、"最近三个月"、"当年"），先用 get_current_time 获取当前时间
2. 用 get_tables 了解有哪些表
3. 用 get_table_schema 了解表结构
4. 用 execute_sql 执行查询获取数据
5. 基于查询结果给出分析和回答

重要字段约定：
- transactions.amount 始终为正数
- transactions.type 区分收支：'income'=收入，'expense'=支出
- transactions.date 为毫秒时间戳（millisecondsSinceEpoch）
- categories 支持多级分类，通过 parentId 关联父分类
- 计算净收支时：收入总额 - 支出总额

回答要求：
- 用中文回答
- 数据要准确，必要时展示具体数字
- 金额保留两位小数''';

  OpenAIAgentService({
    required this.apiKey,
    required this.baseUrl,
    required this.modelName,
    http.Client? client,
  })  : _client = client ??
            LoggingHttpClient(
              http.Client(),
              serviceName: 'ai_agent',
              apiProvider: 'openai_compatible',
            ),
        _tools = createDatabaseTools();

  /// 构建 API URL
  String get _apiUrl {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    if (base.endsWith('/v1')) {
      return '$base/chat/completions';
    }
    return '$base/v1/chat/completions';
  }

  @override
  Future<void> chat({
    required List<ChatMessage> history,
    required String userMessage,
    required OnMessageCallback onMessage,
  }) async {
    // 构建消息历史
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
    ];

    // 添加历史消息（只取 user 和 assistant）
    for (final msg in history) {
      if (msg.role == ChatRole.user) {
        messages.add({'role': 'user', 'content': msg.content});
      } else if (msg.role == ChatRole.assistant && msg.content.isNotEmpty) {
        messages.add({'role': 'assistant', 'content': msg.content});
      }
    }

    // 添加当前用户消息
    messages.add({'role': 'user', 'content': userMessage});

    // ReAct 循环
    for (var i = 0; i < _maxIterations; i++) {
      final response = await _callApi(messages);
      if (response == null) {
        onMessage(ChatMessage(
          role: ChatRole.assistant,
          content: '请求失败，请检查网络连接和 AI 模型配置。',
        ));
        return;
      }

      final choice = response['choices'][0];
      final message = choice['message'];
      final toolCalls = message['tool_calls'] as List<dynamic>?;

      if (toolCalls != null && toolCalls.isNotEmpty) {
        // 有工具调用
        await _handleToolCalls(messages, toolCalls, onMessage);
      } else {
        // 最终回复
        final content = message['content'] as String? ?? '';
        onMessage(ChatMessage(
          role: ChatRole.assistant,
          content: content,
        ));
        return;
      }
    }

    // 超过最大迭代次数
    onMessage(ChatMessage(
      role: ChatRole.assistant,
      content: '分析步骤过多，已停止。请尝试简化问题。',
    ));
  }

  Future<Map<String, dynamic>?> _callApi(
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final body = {
        'model': modelName,
        'messages': messages,
        'tools': toolsToOpenAIFormat(_tools),
        'temperature': 0.1,
      };

      final response = await _client
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        AppLogger.e('Agent API error: ${response.statusCode}',
            error: response.body);
        return null;
      }
    } catch (e) {
      AppLogger.e('Agent API call failed', error: e);
      return null;
    }
  }

  Future<void> _handleToolCalls(
    List<Map<String, dynamic>> messages,
    List<dynamic> toolCalls,
    OnMessageCallback onMessage,
  ) async {
    // 将 assistant 的 tool_calls 消息加入历史
    messages.add({
      'role': 'assistant',
      'content': null,
      'tool_calls': toolCalls,
    });

    final toolCallInfos = <ToolCallInfo>[];

    for (final tc in toolCalls) {
      final id = tc['id'] as String;
      final function = tc['function'];
      final name = function['name'] as String;
      final argsStr = function['arguments'] as String;

      final info = ToolCallInfo(id: id, name: name, arguments: argsStr);
      toolCallInfos.add(info);

      // 执行工具
      String result;
      try {
        final args = jsonDecode(argsStr) as Map<String, dynamic>;
        final tool = _tools.firstWhere(
          (t) => t.name == name,
          orElse: () => throw Exception('未知工具: $name'),
        );
        result = await tool.execute(args);
      } catch (e) {
        result = '工具执行失败: $e';
      }

      info.result = result;

      // 将工具结果加入消息历史
      messages.add({
        'role': 'tool',
        'tool_call_id': id,
        'content': result,
      });
    }

    // 通知 UI 显示工具调用
    onMessage(ChatMessage(
      role: ChatRole.toolCall,
      content: '',
      toolCalls: toolCallInfos,
    ));
  }

  void dispose() {
    _client.close();
  }
}
