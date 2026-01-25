import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/category_match_result.dart';
import '../../models/ai_model.dart';
import '../../models/ai_provider.dart';
import '../../models/ai_classification_config.dart';
import '../http/logging_http_client.dart';
import 'ai_classifier_service.dart';
import 'model_list_parser.dart';
import '../../utils/app_logger.dart';
class QwenClassifierService with AIClassifierServiceMixin
    implements AIClassifierService {
  static const String _chatUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static const String _modelsUrl =
      'https://dashscope.aliyuncs.com/api/v1/models';

  final String apiKey;
  final String modelId;
  final AIClassificationConfig config;
  final http.Client _client;
  final Duration timeout;

  QwenClassifierService(
    this.apiKey,
    this.modelId,
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ??
            LoggingHttpClient(
              http.Client(),
              serviceName: 'qwen_classifier',
              apiProvider: 'qwen',
            );

  @override
  AIProvider get provider => AIProvider.qwen;

  @override
  String get currentModel => modelId;

  @override
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final response = await _client
          .get(
            Uri.parse(_modelsUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final models = ModelListParser.parseModelList(
          response.bodyBytes,
          modelFilter: ModelListParser.isQwenModel,
        );

        if (models != null && models.isNotEmpty) {
          AppLogger.i('Fetched ${models.length} Qwen models from API');
          return models;
        }

        AppLogger.w('No Qwen models found in API response');
      } else {
        AppLogger.w('Qwen API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.e('Failed to fetch Qwen models: $e');
    }

    // 返回默认模型列表作为后备
    AppLogger.i('Using default Qwen model list');
    return _getDefaultModels();
  }

  List<AIModel> _getDefaultModels() {
    return [
      AIModel(
        id: 'qwen-turbo',
        name: 'Qwen Turbo',
        description: '快速通用模型',
        inputPrice: 0.002,
        outputPrice: 0.006,
      ),
      AIModel(
        id: 'qwen-plus',
        name: 'Qwen Plus',
        description: '高性能模型',
        inputPrice: 0.008,
        outputPrice: 0.024,
      ),
      AIModel(
        id: 'qwen-max',
        name: 'Qwen Max',
        description: '最强性能模型',
        inputPrice: 0.04,
        outputPrice: 0.12,
      ),
    ];
  }

  @override
  Future<CategoryMatchResult?> classify(
    Transaction transaction,
    List<Category> availableCategories,
  ) async {
    try {
      final messages = _buildMessages(transaction, availableCategories);

      final response = await _client
          .post(
            Uri.parse(_chatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'X-DashScope-SSE': 'disable',
            },
            body: jsonEncode({
              'model': modelId,
              'input': {
                'messages': messages,
              },
              'parameters': {
                'temperature': 0.1,
                'max_tokens': 200,
                'result_format': 'message',
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseResponse(result);
      } else {
        AppLogger.w('Qwen API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      AppLogger.w('Qwen classification failed', error: e);
    }

    return null;
  }

  @override
  Future<List<CategoryMatchResult?>> classifyBatch(
    List<Transaction> transactions,
    List<Category> availableCategories,
  ) async {
    const batchSize = 3;
    final results = <CategoryMatchResult?>[];

    for (var i = 0; i < transactions.length; i += batchSize) {
      final batch = transactions.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((t) => classify(t, availableCategories)),
      );
      results.addAll(batchResults);

      if (i + batchSize < transactions.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _client
          .post(
            Uri.parse(_chatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'X-DashScope-SSE': 'disable',
            },
            body: jsonEncode({
              'model': modelId,
              'input': {
                'messages': [
                  {'role': 'user', 'content': '你好'}
                ],
              },
              'parameters': {
                'max_tokens': 10,
              },
            }),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, String>> _buildMessages(
    Transaction transaction,
    List<Category> categories,
  ) {
    final categoryList = categories.map((c) {
      final parts = [c.name];
      if (c.parentId != null) {
        final parent = categories.firstWhere(
          (p) => p.id == c.parentId,
          orElse: () => c,
        );
        if (parent != c) parts.insert(0, parent.name);
      }
      return '  ${c.id}: ${parts.join(' > ')}';
    }).join('\n');

    // 使用配置的提示词
    final systemPrompt = config.systemPrompt;
    final userPrompt = config.buildUserPrompt(
      transaction: transaction,
      categoryList: categoryList,
    );

    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];
  }

  CategoryMatchResult? _parseResponse(Map<String, dynamic> response) {
    try {
      final output = response['output'] as Map<String, dynamic>;
      final content = output['choices'][0]['message']['content'] as String;

      // 尝试提取 JSON（通义千问可能会在 JSON 前后添加说明文字）
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch == null) {
        AppLogger.w('No JSON found in Qwen response');
        return null;
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      return CategoryMatchResult(
        categoryId: data['categoryId'] as int,
        confidence: (data['confidence'] as num).toDouble(),
        matchType: 'ai',
        matchedRule: 'AI分类: ${data['reason'] ?? '通义千问'}',
        needsConfirmation: (data['confidence'] as num) < 0.8,
      );
    } catch (e) {
      AppLogger.e('Failed to parse Qwen response: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> extractBillSummary(
    String fileContent,
    String fileType,
  ) async {
    try {
      final messages = _buildSummaryExtractionMessages(fileContent, fileType);

      final response = await _client
          .post(
            Uri.parse(_chatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
              'X-DashScope-SSE': 'disable',
            },
            body: jsonEncode({
              'model': modelId,
              'input': {
                'messages': messages,
              },
              'parameters': {
                'temperature': 0.1,
                'max_tokens': 500,
                'result_format': 'message',
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseSummaryResponse(result);
      } else {
        AppLogger.w('Qwen API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to extract bill summary: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.w('Qwen bill summary extraction failed', error: e);
      rethrow;
    }
  }

  List<Map<String, String>> _buildSummaryExtractionMessages(
    String fileContent,
    String fileType,
  ) {
    // 使用父类的共享方法
    return buildSummaryExtractionMessages(fileContent, fileType);
  }

  Map<String, dynamic> _parseSummaryResponse(Map<String, dynamic> response) {
    try {
      final output = response['output'] as Map<String, dynamic>;
      final content = output['choices'][0]['message']['content'] as String;

      // 尝试提取 JSON（通义千问可能会在 JSON 前后添加说明文字或代码块标记）
      String jsonStr = content.trim();

      // 移除可能的 markdown 代码块标记
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      // 尝试提取 JSON 对象
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch == null) {
        AppLogger.w('No JSON found in Qwen summary response: $content');
        throw Exception('No valid JSON found in response');
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      // 验证必需字段
      final requiredFields = [
        'totalCount',
        'incomeCount',
        'expenseCount',
        'totalIncome',
        'totalExpense',
        'netAmount',
      ];

      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          throw Exception('Missing required field: $field');
        }
      }

      return data;
    } catch (e) {
      AppLogger.e('Failed to parse Qwen summary response: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
