import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/agent_memory.dart';
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
  final List<AgentMemory> memories;
  final http.Client _client;
  final List<AgentTool> _tools;

  static const int _maxIterations = 20;
  static const Duration _timeout = Duration(seconds: 60);

  static const String _systemPrompt = '''你是一个家庭记账应用的智能数据分析助手。
你可以通过工具查询数据库来回答用户关于收支、账户、分类等方面的问题。

工作流程：
1. 用 get_tables 了解有哪些表
2. 用 get_table_schema 了解表结构
3. 用 execute_sql 执行查询获取数据
4. 基于查询结果给出分析和回答

重要字段约定：
- transactions.amount 始终为正数
- transactions.type 区分收支：'income'=收入，'expense'=支出
- transactions.transaction_time 为毫秒时间戳（millisecondsSinceEpoch），这是交易时间字段的真实列名
- categories 支持多级分类，通过 parentId 关联父分类
- 计算净收支时：收入总额 - 支出总额

时间查询要求：
- 涉及时间范围查询时，必须使用下方"当前时间"区域提供的精确时间戳
- 不要自行计算时间戳，直接引用提供的值
- 时间字段是 transaction_time（不是 date）

回答要求：
- 用中文回答
- 数据要准确，必要时展示具体数字
- 金额保留两位小数

当用户说"记住"、"以后"、"请注意"等表达时，调用 save_memory 工具保存信息。''';

  OpenAIAgentService({
    required this.apiKey,
    required this.baseUrl,
    required this.modelName,
    this.memories = const [],
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

  /// 构建包含当前时间和记忆的完整 System Prompt
  String get _fullSystemPrompt {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
    final yearStart = DateTime(now.year, 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final last3MonthStart = DateTime(now.year, now.month - 2, 1);

    final timeInfo = '## 当前时间（直接使用以下时间戳，不要自行计算）\n'
        '- 日期：${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
        '- 当前毫秒时间戳：${now.millisecondsSinceEpoch}\n'
        '- 本月起始时间戳：${monthStart.millisecondsSinceEpoch}\n'
        '- 本月结束时间戳：${monthEnd.millisecondsSinceEpoch}\n'
        '- 上月起始时间戳：${lastMonthStart.millisecondsSinceEpoch}\n'
        '- 最近三个月起始时间戳：${last3MonthStart.millisecondsSinceEpoch}\n'
        '- 本年起始时间戳：${yearStart.millisecondsSinceEpoch}';

    var prompt = '$_systemPrompt\n\n$timeInfo';

    if (memories.isNotEmpty) {
      final memoryLines = memories.map((m) {
        final prefix = switch (m.type) {
          'like' => '[赞]',
          'dislike' => '[踩]',
          _ => '[记忆]',
        };
        return '- $prefix ${m.content}';
      }).join('\n');

      prompt += '\n\n## 用户偏好和记忆\n以下是从历史交互中积累的信息，请参考：\n$memoryLines';
    }

    return prompt;
  }

  @override
  Future<void> chat({
    required List<ChatMessage> history,
    required String userMessage,
    required OnMessageCallback onMessage,
  }) async {
    // 构建消息历史
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _fullSystemPrompt},
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

  @override
  Future<FeedbackSummary?> summarizeFeedback({
    required String feedbackType,
    required String context,
  }) async {
    final feedbackDesc = feedbackType == 'like'
        ? '用户对以下回答点了"赞"，表示认可。请总结这次成功的回答模式，提炼出关键要点（如：查询思路、回答风格、数据呈现方式等），用一句话概括，以便未来遇到类似问题时参考。'
        : '用户对以下回答点了"踩"，表示不满意。请分析回答中可能存在的问题（如：查询逻辑错误、回答不够简洁、数据不准确等），用一句话概括改进方向，以便未来避免类似问题。';

    final prompt = '''$feedbackDesc

请以 JSON 格式返回，包含两个字段：
- "content": 总结内容，不超过100字
- "related_query": 对用户核心问题的简短概括（不超过30字），需要综合多轮对话理解用户真正想问什么

只返回 JSON，不要包含其他内容。示例：
{"content": "总结内容", "related_query": "问题概括"}''';

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': prompt},
      {'role': 'user', 'content': context},
    ];

    try {
      final body = {
        'model': modelName,
        'messages': messages,
        'temperature': 0.3,
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final raw = data['choices'][0]['message']['content'] as String? ?? '';
        return _parseFeedbackSummary(raw);
      }
      AppLogger.e('summarizeFeedback API error: ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.e('summarizeFeedback failed', error: e);
      return null;
    }
  }

  /// 解析 LLM 返回的 JSON 反馈总结
  FeedbackSummary? _parseFeedbackSummary(String raw) {
    try {
      // 尝试提取 JSON（兼容 LLM 可能包裹 markdown 代码块的情况）
      var jsonStr = raw.trim();
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(0)!;
      }
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return FeedbackSummary(
        content: map['content'] as String? ?? '',
        relatedQuery: map['related_query'] as String? ?? '',
      );
    } catch (e) {
      AppLogger.w('Failed to parse feedback summary JSON, using raw text', error: e);
      return FeedbackSummary(content: raw.trim(), relatedQuery: '');
    }
  }

  @override
  Future<String?> generateTitle({
    required String firstUserMessage,
    required String firstAssistantReply,
  }) async {
    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': '根据以下对话内容，生成一个简短的中文标题（不超过15个字，不要标点符号）',
      },
      {
        'role': 'user',
        'content': '用户：$firstUserMessage\n助手：$firstAssistantReply',
      },
    ];

    try {
      final body = {
        'model': modelName,
        'messages': messages,
        'temperature': 0.3,
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String?;
      }
      AppLogger.e('generateTitle API error: ${response.statusCode}');
      return null;
    } catch (e) {
      AppLogger.e('generateTitle failed', error: e);
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
