import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/counterparty_suggestion.dart';
import '../database/transaction_db_service.dart';
import '../database/ai_model_db_service.dart';
import '../http/logging_http_client.dart';
import '../../utils/app_logger.dart';

/// 对手方智能匹配服务
/// 负责识别相似的对手方并生成分组建议
/// 支持基于规则和基于 LLM 两种方式
class CounterpartyMatchingService {
  final TransactionDbService _transactionDbService = TransactionDbService();
  final AIModelDbService _aiModelDbService = AIModelDbService();
  final http.Client _httpClient = LoggingHttpClient(
    http.Client(),
    serviceName: 'counterparty_grouping',
    apiProvider: 'ai',
  );

  // 相似度阈值（0-1），超过此值才会建议分组
  static const double suggestionThreshold = 0.8;

  // 最小分组成员数
  static const int minGroupSize = 2;

  /// 生成分组建议（使用 LLM）
  /// 这是主要的推荐方法，优先使用 AI 进行智能分析
  Future<List<CounterpartySuggestion>> generateSuggestionsWithAI() async {
    try {
      AppLogger.i('[CounterpartyMatchingService] 开始使用 LLM 生成分组建议');

      // 1. 获取活跃的 AI 模型配置
      final aiModel = await _aiModelDbService.getActiveModel();
      if (aiModel == null) {
        AppLogger.w('[CounterpartyMatchingService] 未配置 AI 模型，回退到基于规则的方法');
        return await generateSuggestions();
      }

      // 2. 获取所有对手方
      final counterparties = await _transactionDbService.getCounterparties(limit: 200);
      if (counterparties.length < minGroupSize) {
        AppLogger.d('[CounterpartyMatchingService] 对手方数量不足');
        return [];
      }

      // 3. 构建 prompt
      final prompt = _buildGroupingPrompt(counterparties);

      // 4. 调用 LLM
      final response = await _callLLM(aiModel, prompt);
      if (response == null) {
        AppLogger.w('[CounterpartyMatchingService] LLM 调用失败，回退到基于规则的方法');
        return await generateSuggestions();
      }

      // 5. 解析 LLM 响应
      final suggestions = _parseLLMResponse(response);
      AppLogger.i('[CounterpartyMatchingService] LLM 生成 ${suggestions.length} 个分组建议');

      return suggestions;
    } catch (e, stackTrace) {
      AppLogger.e('[CounterpartyMatchingService] LLM 生成建议失败', error: e, stackTrace: stackTrace);
      // 回退到基于规则的方法
      return await generateSuggestions();
    }
  }

  /// 构建对手方分组的 prompt
  String _buildGroupingPrompt(List<String> counterparties) {
    return '''你是一个智能财务助手，需要帮助用户整理对手方（交易对象）数据。

用户有以下对手方列表：
${counterparties.map((c) => '- $c').join('\n')}

请分析这些对手方，识别出属于同一商家/品牌的不同分店或变体，并给出分组建议。

要求：
1. 识别同一品牌的不同分店（如"沃尔玛福田店"和"沃尔玛南山店"应该归为"沃尔玛"）
2. 识别同一商家的不同写法（如"星巴克"和"Starbucks"）
3. 每个分组至少要有2个成员
4. 给出分组的置信度（0-1之间）
5. 说明分组的原因

请以 JSON 格式返回结果，格式如下：
{
  "suggestions": [
    {
      "main_counterparty": "主对手方名称",
      "sub_counterparties": ["子对手方1", "子对手方2"],
      "confidence_score": 0.95,
      "reason": "分组原因说明"
    }
  ]
}

只返回 JSON，不要有其他文字。''';
  }

  /// 调用 LLM API
  Future<String?> _callLLM(dynamic aiModel, String prompt) async {
    try {
      final provider = aiModel.provider as String;
      final modelName = aiModel.modelName as String;
      final apiKey = aiModel.decryptedApiKey as String;
      final baseUrl = aiModel.baseUrl as String?;

      if (provider == 'qwen') {
        return await _callQwenAPI(apiKey, modelName, prompt, baseUrl);
      } else if (provider == 'deepseek') {
        return await _callDeepseekAPI(apiKey, modelName, prompt, baseUrl);
      } else {
        AppLogger.w('[CounterpartyMatchingService] 不支持的 AI 提供商: $provider');
        return null;
      }
    } catch (e) {
      AppLogger.e('[CounterpartyMatchingService] 调用 LLM 失败', error: e);
      return null;
    }
  }

  /// 调用 Qwen API
  Future<String?> _callQwenAPI(String apiKey, String modelName, String prompt, String? baseUrl) async {
    final url = baseUrl ?? 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': modelName,
        'input': {
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        },
        'parameters': {
          'result_format': 'message',
        }
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['output']['choices'][0]['message']['content'] as String?;
    } else {
      AppLogger.w('[CounterpartyMatchingService] Qwen API 返回错误: ${response.statusCode}');
      return null;
    }
  }

  /// 调用 DeepSeek API
  Future<String?> _callDeepseekAPI(String apiKey, String modelName, String prompt, String? baseUrl) async {
    final url = baseUrl ?? 'https://api.deepseek.com/v1/chat/completions';

    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] as String?;
    } else {
      AppLogger.w('[CounterpartyMatchingService] DeepSeek API 返回错误: ${response.statusCode}');
      return null;
    }
  }

  /// 解析 LLM 响应
  List<CounterpartySuggestion> _parseLLMResponse(String response) {
    try {
      // 提取 JSON 部分（LLM 可能返回额外的文字）
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        AppLogger.w('[CounterpartyMatchingService] 无法从响应中提取 JSON');
        return [];
      }

      final jsonStr = jsonMatch.group(0)!;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final suggestionsData = data['suggestions'] as List?;

      if (suggestionsData == null) {
        AppLogger.w('[CounterpartyMatchingService] 响应中没有 suggestions 字段');
        return [];
      }

      final suggestions = <CounterpartySuggestion>[];
      for (var item in suggestionsData) {
        try {
          final suggestion = CounterpartySuggestion(
            mainCounterparty: item['main_counterparty'] as String,
            subCounterparties: List<String>.from(item['sub_counterparties'] as List),
            confidenceScore: (item['confidence_score'] as num).toDouble(),
            reason: item['reason'] as String,
          );

          // 验证分组有效性
          if (suggestion.subCounterparties.length >= minGroupSize) {
            suggestions.add(suggestion);
          }
        } catch (e) {
          AppLogger.w('[CounterpartyMatchingService] 解析单个建议失败', error: e);
        }
      }

      return suggestions;
    } catch (e) {
      AppLogger.e('[CounterpartyMatchingService] 解析 LLM 响应失败', error: e);
      return [];
    }
  }

  /// 生成分组建议（基于规则）
  /// 作为 LLM 方法的备选方案
  /// 分析所有对手方，识别相似的对手方并生成分组建议
  Future<List<CounterpartySuggestion>> generateSuggestions() async {
    try {
      AppLogger.i('[CounterpartyMatchingService] 开始生成分组建议');

      // 1. 获取所有唯一对手方
      final counterparties = await _transactionDbService.getCounterparties(limit: 1000);

      if (counterparties.length < minGroupSize) {
        AppLogger.d('[CounterpartyMatchingService] 对手方数量不足，无法生成建议');
        return [];
      }

      // 2. 按相似度分组
      final Map<String, List<String>> groups = {};
      final Set<String> processed = {};

      for (int i = 0; i < counterparties.length; i++) {
        final current = counterparties[i];
        if (processed.contains(current)) continue;

        final keyword = extractKeyword(current);
        if (keyword.isEmpty) continue;

        // 查找相似的对手方
        final similarCounterparties = <String>[current];
        processed.add(current);

        for (int j = i + 1; j < counterparties.length; j++) {
          final other = counterparties[j];
          if (processed.contains(other)) continue;

          final similarity = calculateSimilarity(current, other);
          if (similarity >= suggestionThreshold) {
            similarCounterparties.add(other);
            processed.add(other);
          }
        }

        // 如果找到多个相似对手方，创建分组
        if (similarCounterparties.length >= minGroupSize) {
          groups[keyword] = similarCounterparties;
        }
      }

      // 3. 转换为建议列表
      final suggestions = <CounterpartySuggestion>[];
      for (var entry in groups.entries) {
        final avgConfidence = _calculateGroupConfidence(entry.value);
        suggestions.add(CounterpartySuggestion(
          mainCounterparty: entry.key,
          subCounterparties: entry.value,
          confidenceScore: avgConfidence,
          reason: '发现 ${entry.value.length} 个相似对手方',
        ));
      }

      // 4. 按置信度排序
      suggestions.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

      AppLogger.i('[CounterpartyMatchingService] 生成 ${suggestions.length} 个分组建议');
      return suggestions;
    } catch (e, stackTrace) {
      AppLogger.e('[CounterpartyMatchingService] 生成建议失败', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// 提取关键词
  /// 去除常见后缀和地区信息，提取核心品牌名
  String extractKeyword(String counterparty) {
    if (counterparty.isEmpty) return '';

    String keyword = counterparty;

    // 1. 去除常见后缀
    final suffixes = [
      '分店', '店', '专卖店', '旗舰店', '超市', '商场',
      '购物中心', '便利店', '连锁店', '直营店', '加盟店',
      '门店', '商店', '零售店', '体验店', '形象店',
    ];

    for (var suffix in suffixes) {
      if (keyword.endsWith(suffix)) {
        keyword = keyword.substring(0, keyword.length - suffix.length);
      }
    }

    // 2. 去除括号内容（通常是地区或补充信息）
    keyword = keyword.replaceAll(RegExp(r'[（(].*?[)）]'), '');

    // 3. 去除常见地区词汇
    final locationPatterns = [
      '市', '区', '县', '镇', '街道', '社区', '路', '街', '巷',
      '福田', '宝安', '南山', '罗湖', '龙岗', '龙华', '坪山', '盐田', '光明', '大鹏',
      '东', '西', '南', '北', '中', '新', '老',
    ];

    for (var pattern in locationPatterns) {
      keyword = keyword.replaceAll(pattern, '');
    }

    // 4. 去除数字和特殊字符
    keyword = keyword.replaceAll(RegExp(r'[0-9\-_#\s]+'), '');

    // 5. 去除多余空格
    keyword = keyword.trim();

    return keyword;
  }

  /// 计算相似度
  /// 返回0-1之间的相似度分数
  double calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;

    // 提取关键词
    final keywordA = extractKeyword(a);
    final keywordB = extractKeyword(b);

    if (keywordA.isEmpty || keywordB.isEmpty) return 0.0;

    // 1. 精确匹配（权重1.0）
    if (keywordA == keywordB) return 1.0;

    // 2. 包含关系（权重0.85）
    if (keywordA.contains(keywordB) || keywordB.contains(keywordA)) {
      return 0.85;
    }

    // 3. 编辑距离（权重0.7）
    final distance = _levenshteinDistance(keywordA, keywordB);
    final maxLen = max(keywordA.length, keywordB.length);
    if (maxLen == 0) return 0.0;

    final editSimilarity = 1.0 - (distance / maxLen);
    return editSimilarity * 0.7;
  }

  /// 计算分组的平均置信度
  double _calculateGroupConfidence(List<String> counterparties) {
    if (counterparties.length < 2) return 1.0;

    double totalSimilarity = 0.0;
    int comparisons = 0;

    for (int i = 0; i < counterparties.length; i++) {
      for (int j = i + 1; j < counterparties.length; j++) {
        totalSimilarity += calculateSimilarity(counterparties[i], counterparties[j]);
        comparisons++;
      }
    }

    return comparisons > 0 ? totalSimilarity / comparisons : 0.0;
  }

  /// 计算编辑距离（Levenshtein Distance）
  /// 用于衡量两个字符串的相似程度
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // 创建距离矩阵
    final List<List<int>> matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // 初始化第一行和第一列
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // 计算距离
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = min(
          min(
            matrix[i - 1][j] + 1, // 删除
            matrix[i][j - 1] + 1, // 插入
          ),
          matrix[i - 1][j - 1] + cost, // 替换
        );
      }
    }

    return matrix[len1][len2];
  }

  /// 查找与指定对手方相似的其他对手方
  Future<List<String>> findSimilarCounterparties(
    String counterparty, {
    double threshold = 0.7,
  }) async {
    try {
      final allCounterparties = await _transactionDbService.getCounterparties(limit: 1000);
      final similar = <String>[];

      for (var other in allCounterparties) {
        if (other == counterparty) continue;

        final similarity = calculateSimilarity(counterparty, other);
        if (similarity >= threshold) {
          similar.add(other);
        }
      }

      return similar;
    } catch (e) {
      AppLogger.e('[CounterpartyMatchingService] 查找相似对手方失败', error: e);
      return [];
    }
  }
}
