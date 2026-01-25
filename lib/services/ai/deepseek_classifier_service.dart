import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/transaction.dart';
import '../../models/category.dart';
import '../../models/category_match_result.dart';
import '../../models/ai_model.dart';
import '../../models/ai_provider.dart';
import '../../models/ai_classification_config.dart';
import '../http/logging_http_client.dart';
import '../../utils/app_logger.dart';
import 'ai_classifier_service.dart';
import 'model_list_parser.dart';

class DeepSeekClassifierService implements AIClassifierService {
  static const String _baseUrl = 'https://api.deepseek.com';

  final String apiKey;
  final String modelId;
  final AIClassificationConfig config;
  final http.Client _client;
  final Duration timeout;

  DeepSeekClassifierService(
    this.apiKey,
    this.modelId,
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ??
            LoggingHttpClient(
              http.Client(),
              serviceName: 'deepseek_classifier',
              apiProvider: 'deepseek',
            );

  @override
  AIProvider get provider => AIProvider.deepseek;

  @override
  String get currentModel => modelId;

  @override
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/v1/models'),
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final models = ModelListParser.parseModelList(
          response.bodyBytes,
          modelFilter: ModelListParser.isChatModel,
        );

        if (models != null && models.isNotEmpty) {
          AppLogger.i('Fetched ${models.length} DeepSeek models from API');
          return models;
        }

        AppLogger.w('No chat models found in API response');
      } else {
        AppLogger.w('DeepSeek API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      AppLogger.w('Failed to fetch DeepSeek models', error: e);
    }

    // 返回默认模型列表作为后备
    AppLogger.i('Using default DeepSeek model list');
    return _getDefaultModels();
  }

  List<AIModel> _getDefaultModels() {
    return [
      AIModel(
        id: 'deepseek-chat',
        name: 'DeepSeek Chat',
        description: '通用对话模型',
        inputPrice: 0.001,
        outputPrice: 0.002,
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
            Uri.parse('$_baseUrl/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': modelId,
              'messages': messages,
              'temperature': 0.1,
              'max_tokens': 200,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseResponse(result);
      } else {
        AppLogger.w('DeepSeek API error: ${response.statusCode}', error: response.body);
      }
    } catch (e) {
      AppLogger.e('DeepSeek classification failed', error: e);
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
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': modelId,
              'messages': [
                {'role': 'user', 'content': '你好'}
              ],
              'max_tokens': 10,
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
      final content = response['choices'][0]['message']['content'] as String;
      final data = jsonDecode(content) as Map<String, dynamic>;

      return CategoryMatchResult(
        categoryId: data['categoryId'] as int,
        confidence: (data['confidence'] as num).toDouble(),
        matchType: 'ai',
        matchedRule: 'AI分类: ${data['reason'] ?? 'DeepSeek'}',
        needsConfirmation: (data['confidence'] as num) < 0.8,
      );
    } catch (e) {
      AppLogger.e('Failed to parse DeepSeek response', error: e);
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
            Uri.parse('$_baseUrl/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': modelId,
              'messages': messages,
              'temperature': 0.1,
              'max_tokens': 500,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        return _parseSummaryResponse(result);
      } else {
        AppLogger.w('DeepSeek API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to extract bill summary: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.w('DeepSeek bill summary extraction failed', error: e);
      rethrow;
    }
  }

  List<Map<String, String>> _buildSummaryExtractionMessages(
    String fileContent,
    String fileType,
  ) {
    final systemPrompt = '''You are a financial data analyst. Extract summary statistics from bill files.
Your task is to analyze the file header/summary section and extract key statistics.
Return ONLY a valid JSON object with the required fields. Do not include any explanation or additional text.''';

    final userPrompt = '''Extract bill summary from the following ${fileType} file header:

$fileContent

Please analyze the file and extract the following information:
1. Total number of transactions
2. Number of income transactions
3. Number of expense transactions
4. Total income amount
5. Total expense amount

IMPORTANT:
- Only count valid transaction records
- Ignore header rows, footer rows, and summary rows
- For Alipay CSV: Look for summary information in the header section (first 24 lines)
- For WeChat XLSX: Look for summary information in the header section (first 17 lines)
- The header often contains total statistics like "交易笔数", "收入笔数", "支出笔数", "收入金额", "支出金额"

Return ONLY a JSON object with this exact structure (use English keys):
{
  "totalCount": <number>,
  "incomeCount": <number>,
  "expenseCount": <number>,
  "totalIncome": <number>,
  "totalExpense": <number>,
  "netAmount": <number>
}

Do not include any explanation or additional text. Return only the JSON object.''';

    return [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userPrompt},
    ];
  }

  Map<String, dynamic> _parseSummaryResponse(Map<String, dynamic> response) {
    try {
      final content = response['choices'][0]['message']['content'] as String;

      // 移除可能的 markdown 代码块标记
      String jsonStr = content.trim();
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
        AppLogger.w('No JSON found in DeepSeek summary response: $content');
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
      AppLogger.e('Failed to parse DeepSeek summary response', error: e);
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
