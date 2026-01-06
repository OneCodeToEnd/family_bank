import '../models/transaction.dart';
import '../models/ai_provider.dart';
import '../services/encryption/encryption_service.dart';
import '../utils/app_logger.dart';

/// AI 分类配置模型
class AIClassificationConfig {
  final bool enabled; // 是否启用 AI 分类
  final AIProvider provider; // 选择的提供商
  final String apiKey; // API 密钥（加密存储）
  final String modelId; // 选择的模型 ID
  final double confidenceThreshold; // 置信度阈值
  final bool autoLearn; // 是否从 AI 建议中自动学习
  final String systemPrompt; // 系统提示词（可自定义）
  final String userPromptTemplate; // 用户提示词模板（可自定义）

  const AIClassificationConfig({
    this.enabled = false,
    this.provider = AIProvider.deepseek,
    this.apiKey = '',
    this.modelId = '',
    this.confidenceThreshold = 0.7,
    this.autoLearn = true,
    this.systemPrompt = _defaultSystemPrompt,
    this.userPromptTemplate = _defaultUserPromptTemplate,
  });

  // ==================== 默认提示词 ====================

  static const String _defaultSystemPrompt = '''你是一个专业的账单分类助手。
根据交易信息，从给定的分类列表中选择最合适的分类。
请仔细分析交易描述、对方和金额，给出准确的分类建议。
必须返回JSON格式的结果。''';

  static const String _defaultUserPromptTemplate = '''
交易信息：
- 描述：{{description}}
- 对方：{{counterparty}}
- 金额：{{amount}} 元
- 类型：{{type}}

可选分类：
{{categories}}

请返回JSON格式：
{
  "categoryId": <分类ID>,
  "confidence": <置信度0-1>,
  "reason": "<选择理由>"
}''';

  /// 序列化为 JSON（API Key 需要加密）
  Map<String, dynamic> toJson({bool encrypt = true}) {
    return {
      'enabled': enabled,
      'provider': provider.name,
      'api_key': encrypt ? _encryptApiKey(apiKey) : apiKey,
      'model_id': modelId,
      'confidence_threshold': confidenceThreshold,
      'auto_learn': autoLearn,
      'system_prompt': systemPrompt,
      'user_prompt_template': userPromptTemplate,
    };
  }

  /// 从 JSON 反序列化（API Key 需要解密）
  factory AIClassificationConfig.fromJson(Map<String, dynamic> json) {
    final encryptedKey = json['api_key'] as String? ?? '';

    return AIClassificationConfig(
      enabled: json['enabled'] as bool? ?? false,
      provider: AIProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AIProvider.deepseek,
      ),
      apiKey: encryptedKey.isEmpty ? '' : _decryptApiKey(encryptedKey),
      modelId: json['model_id'] as String? ?? '',
      confidenceThreshold:
          (json['confidence_threshold'] as num?)?.toDouble() ?? 0.7,
      autoLearn: json['auto_learn'] as bool? ?? true,
      systemPrompt: json['system_prompt'] as String? ?? _defaultSystemPrompt,
      userPromptTemplate: json['user_prompt_template'] as String? ??
          _defaultUserPromptTemplate,
    );
  }

  AIClassificationConfig copyWith({
    bool? enabled,
    AIProvider? provider,
    String? apiKey,
    String? modelId,
    double? confidenceThreshold,
    bool? autoLearn,
    String? systemPrompt,
    String? userPromptTemplate,
  }) {
    return AIClassificationConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      modelId: modelId ?? this.modelId,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      autoLearn: autoLearn ?? this.autoLearn,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      userPromptTemplate: userPromptTemplate ?? this.userPromptTemplate,
    );
  }

  /// 重置提示词为默认值
  AIClassificationConfig resetPrompts() {
    return copyWith(
      systemPrompt: _defaultSystemPrompt,
      userPromptTemplate: _defaultUserPromptTemplate,
    );
  }

  /// 构建用户提示词（替换模板变量）
  String buildUserPrompt({
    required Transaction transaction,
    required String categoryList,
  }) {
    return userPromptTemplate
        .replaceAll('{{description}}', transaction.description ?? '无')
        .replaceAll('{{counterparty}}', transaction.counterparty ?? '无')
        .replaceAll('{{amount}}', transaction.amount.toString())
        .replaceAll(
            '{{type}}', transaction.type == 'income' ? '收入' : '支出')
        .replaceAll('{{categories}}', categoryList);
  }

  // ==================== 加密/解密方法 ====================

  /// 加密 API Key（使用跨平台加密服务）
  static String _encryptApiKey(String plainText) {
    if (plainText.isEmpty) return '';

    try {
      final encryptionService = EncryptionServiceFactory.getDefault();
      return encryptionService.encrypt(plainText);
    } catch (e) {
      AppLogger.e('Failed to encrypt API key', error: e);
      return '';
    }
  }

  /// 解密 API Key（使用跨平台加密服务）
  static String _decryptApiKey(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final encryptionService = EncryptionServiceFactory.getDefault();
      return encryptionService.decrypt(encryptedText);
    } catch (e) {
      AppLogger.e('Failed to decrypt API key', error: e);
      return '';
    }
  }
}
