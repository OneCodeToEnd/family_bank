# 流水分类匹配系统设计文档

## 1. 架构概览

### 1.1 设计目标
- 自动为导入的流水匹配合适的分类
- 结合规则匹配和大模型的优势
- 从用户行为中持续学习
- 保证匹配的准确性和可控性

### 1.2 核心策略：分层匹配

```
导入流水
  ↓
┌─────────────────────────────────────┐
│ 1. 精确匹配 (Exact Match)         │
│    - 交易对方 (counterparty)       │
│    - 关键词完全匹配                 │
│    - 置信度: 100%                   │
└─────────────────────────────────────┘
  ↓ 未匹配
┌─────────────────────────────────────┐
│ 2. 部分匹配 (Partial Match)        │
│    - 包含关键词 (contains)          │
│    - 前缀/后缀匹配                  │
│    - 别名匹配                       │
│    - 置信度: 70-90%                 │
└─────────────────────────────────────┘
  ↓ 未匹配
┌─────────────────────────────────────┐
│ 3. 历史学习 (Historical Match)     │
│    - 相似描述的历史交易             │
│    - 相同金额+描述模式              │
│    - 置信度: 50-80%                 │
└─────────────────────────────────────┘
  ↓ 未匹配
┌─────────────────────────────────────┐
│ 4. 大模型匹配 (AI Match) [可选]    │
│    - 语义理解分类                   │
│    - 需要用户开启                   │
│    - 置信度: 60-90%                 │
└─────────────────────────────────────┘
  ↓
┌─────────────────────────────────────┐
│ 5. 用户确认 & 学习                 │
│    - 用户手动选择或确认             │
│    - 自动学习为规则                 │
└─────────────────────────────────────┘
```

## 2. 数据模型设计

### 2.1 扩展 CategoryRule 模型

需要在原有基础上增加以下字段：

```dart
class CategoryRule {
  // 原有字段
  final int? id;
  final String keyword;
  final int categoryId;
  final int priority;
  final bool isActive;
  final int matchCount;
  final String source; // user/model/learned

  // 新增字段
  final String matchType;        // exact/partial/counterparty
  final String? matchPosition;   // contains/prefix/suffix (仅用于partial)
  final double minConfidence;    // 最小置信度阈值 (0-1)
  final String? counterparty;    // 交易对方名称（如果matchType=counterparty）
  final List<String> aliases;    // 别名列表（如：["星巴克", "Starbucks", "starbucks"]）
  final bool autoLearn;          // 是否自动学习（从匹配中自动生成）
  final bool caseSensitive;      // 是否区分大小写（默认false）

  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**匹配类型说明：**
- `exact`: 精确匹配，描述中必须包含完整关键词
- `partial`: 部分匹配，使用简单的字符串包含/前缀/后缀检查
- `counterparty`: 交易对方匹配，优先级最高

### 2.2 数据库表结构更新

更新 `category_rules` 表：

```sql
CREATE TABLE category_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  keyword TEXT NOT NULL,
  category_id INTEGER NOT NULL,
  priority INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  match_count INTEGER DEFAULT 0,
  source TEXT DEFAULT 'user',

  -- V3.0 新增字段
  match_type TEXT DEFAULT 'exact',           -- exact/partial/counterparty
  match_position TEXT,                       -- contains/prefix/suffix (仅partial用)
  min_confidence REAL DEFAULT 0.8,           -- 最小置信度
  counterparty TEXT,                         -- 交易对方
  aliases TEXT,                              -- JSON数组: ["alias1", "alias2"]
  auto_learn INTEGER DEFAULT 0,              -- 是否自动学习 0/1
  case_sensitive INTEGER DEFAULT 0,          -- 是否区分大小写 0/1

  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,

  FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- 新增索引
CREATE INDEX idx_rule_match_type ON category_rules(match_type);
CREATE INDEX idx_rule_counterparty ON category_rules(counterparty);
CREATE INDEX idx_rule_priority ON category_rules(priority DESC);
CREATE INDEX idx_rule_keyword ON category_rules(keyword);
```

### 2.3 匹配结果模型

```dart
/// 分类匹配结果
class CategoryMatchResult {
  final int? categoryId;          // 匹配到的分类ID
  final double confidence;        // 置信度 (0-1)
  final String matchType;         // 匹配类型
  final String? matchedRule;      // 匹配的规则描述
  final int? ruleId;             // 匹配的规则ID
  final bool needsConfirmation;   // 是否需要用户确认
  final List<CategorySuggestion> alternatives; // 备选分类

  const CategoryMatchResult({
    this.categoryId,
    required this.confidence,
    required this.matchType,
    this.matchedRule,
    this.ruleId,
    this.needsConfirmation = false,
    this.alternatives = const [],
  });
}

/// 分类建议
class CategorySuggestion {
  final int categoryId;
  final String categoryName;
  final double confidence;
  final String reason; // 建议原因

  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
    required this.reason,
  });
}
```

## 3. 核心服务实现

### 3.1 CategoryMatchService 架构

```dart
class CategoryMatchService {
  final CategoryRuleDbService _ruleDbService;
  final TransactionDbService _transactionDbService;
  final AIClassifierService? _aiService; // 可选的AI分类服务

  /// 为交易匹配分类
  Future<CategoryMatchResult> matchCategory(Transaction transaction) async {
    // 1. 精确匹配
    final exactMatch = await _exactMatch(transaction);
    if (exactMatch != null && exactMatch.confidence >= 0.95) {
      return exactMatch;
    }

    // 2. 部分匹配
    final partialMatch = await _partialMatch(transaction);
    if (partialMatch != null && partialMatch.confidence >= 0.80) {
      return partialMatch;
    }

    // 3. 历史学习匹配
    final historicalMatch = await _historicalMatch(transaction);
    if (historicalMatch != null && historicalMatch.confidence >= 0.70) {
      return historicalMatch;
    }

    // 4. AI 匹配（如果启用）
    if (_aiService != null && await _isAiEnabled()) {
      final aiMatch = await _aiMatch(transaction);
      if (aiMatch != null) {
        return aiMatch;
      }
    }

    // 5. 无法匹配，返回需要用户确认的结果
    return CategoryMatchResult(
      confidence: 0.0,
      matchType: 'manual',
      needsConfirmation: true,
      alternatives: await _getSuggestedCategories(transaction),
    );
  }

  /// 批量匹配（导入时使用）
  Future<List<CategoryMatchResult>> matchBatch(
    List<Transaction> transactions,
  ) async {
    return Future.wait(
      transactions.map((t) => matchCategory(t)),
    );
  }

  /// 从用户确认中学习规则
  Future<void> learnFromConfirmation(
    Transaction transaction,
    int confirmedCategoryId,
  ) async {
    // 分析交易特征
    final features = _extractFeatures(transaction);

    // 检查是否已有规则
    final existingRule = await _findSimilarRule(features, confirmedCategoryId);

    if (existingRule != null) {
      // 更新现有规则的匹配次数和优先级
      await _updateRuleStats(existingRule);
    } else {
      // 创建新规则
      await _createLearnedRule(features, confirmedCategoryId);
    }
  }
}
```

### 3.2 精确匹配策略

```dart
Future<CategoryMatchResult?> _exactMatch(Transaction transaction) async {
  // 1. 优先匹配交易对方
  if (transaction.counterparty != null && transaction.counterparty!.isNotEmpty) {
    final rule = await _ruleDbService.findByCounterparty(
      transaction.counterparty!,
    );
    if (rule != null && rule.isActive) {
      await _ruleDbService.incrementMatchCount(rule.id!);
      return CategoryMatchResult(
        categoryId: rule.categoryId,
        confidence: 1.0,
        matchType: 'counterparty',
        matchedRule: '交易对方: ${rule.counterparty}',
        ruleId: rule.id,
      );
    }
  }

  // 2. 精确关键词匹配（包括别名）
  if (transaction.description != null) {
    final rules = await _ruleDbService.findByMatchType('exact');
    for (final rule in rules.where((r) => r.isActive)) {
      // 检查主关键词
      if (transaction.description!.contains(rule.keyword)) {
        await _ruleDbService.incrementMatchCount(rule.id!);
        return CategoryMatchResult(
          categoryId: rule.categoryId,
          confidence: 1.0,
          matchType: 'exact',
          matchedRule: '关键词: ${rule.keyword}',
          ruleId: rule.id,
        );
      }

      // 检查别名
      for (final alias in rule.aliases) {
        if (transaction.description!.contains(alias)) {
          await _ruleDbService.incrementMatchCount(rule.id!);
          return CategoryMatchResult(
            categoryId: rule.categoryId,
            confidence: 0.98,
            matchType: 'exact',
            matchedRule: '别名: $alias',
            ruleId: rule.id,
          );
        }
      }
    }
  }

  return null;
}
```

### 3.3 部分匹配策略

```dart
Future<CategoryMatchResult?> _partialMatch(Transaction transaction) async {
  if (transaction.description == null) return null;

  final description = transaction.description!;
  final rules = await _ruleDbService.findByMatchType('partial');
  final matches = <({CategoryRule rule, double confidence})>[];

  for (final rule in rules.where((r) => r.isActive)) {
    bool isMatch = false;
    final keyword = rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
    final desc = rule.caseSensitive ? description : description.toLowerCase();

    // 根据 matchPosition 进行不同类型的匹配
    switch (rule.matchPosition) {
      case 'contains':
        isMatch = desc.contains(keyword);
        break;
      case 'prefix':
        isMatch = desc.startsWith(keyword);
        break;
      case 'suffix':
        isMatch = desc.endsWith(keyword);
        break;
      default:
        // 默认使用 contains
        isMatch = desc.contains(keyword);
    }

    if (isMatch) {
      // 计算匹配置信度（基于规则优先级和匹配次数）
      final confidence = _calculateConfidence(rule);
      if (confidence >= rule.minConfidence) {
        matches.add((rule: rule, confidence: confidence));
      }
    }

    // 检查别名
    if (!isMatch) {
      for (final alias in rule.aliases) {
        final aliasToMatch = rule.caseSensitive ? alias : alias.toLowerCase();
        if (desc.contains(aliasToMatch)) {
          final confidence = _calculateConfidence(rule) * 0.95; // 别名匹配稍微降低置信度
          if (confidence >= rule.minConfidence) {
            matches.add((rule: rule, confidence: confidence));
            break;
          }
        }
      }
    }
  }

  if (matches.isEmpty) return null;

  // 按置信度排序，取最高的
  matches.sort((a, b) => b.confidence.compareTo(a.confidence));
  final bestMatch = matches.first;

  await _ruleDbService.incrementMatchCount(bestMatch.rule.id!);

  return CategoryMatchResult(
    categoryId: bestMatch.rule.categoryId,
    confidence: bestMatch.confidence,
    matchType: 'partial',
    matchedRule: '部分匹配: ${bestMatch.rule.keyword}',
    ruleId: bestMatch.rule.id,
    needsConfirmation: bestMatch.confidence < 0.85,
    alternatives: matches.length > 1
        ? await _buildAlternatives(matches.skip(1).take(3).toList())
        : [],
  );
}

double _calculateConfidence(CategoryRule rule) {
  // 基础置信度
  double confidence = 0.75;

  // 优先级加成（优先级越高，置信度越高）
  confidence += (rule.priority / 100).clamp(0.0, 0.1);

  // 匹配次数加成（历史匹配越多，越可信）
  final matchBonus = (rule.matchCount / (rule.matchCount + 10)) * 0.15;
  confidence += matchBonus;

  return confidence.clamp(0.0, 0.95);
}
```

### 3.4 历史学习匹配

```dart
Future<CategoryMatchResult?> _historicalMatch(Transaction transaction) async {
  if (transaction.description == null) return null;

  // 查找相似的已确认交易
  final similarTransactions = await _transactionDbService.findSimilar(
    description: transaction.description!,
    amount: transaction.amount,
    type: transaction.type,
    limit: 10,
  );

  final confirmedTransactions = similarTransactions
      .where((t) => t.isConfirmed && t.categoryId != null)
      .toList();

  if (confirmedTransactions.isEmpty) return null;

  // 统计最常用的分类
  final categoryVotes = <int, int>{};
  for (final t in confirmedTransactions) {
    categoryVotes[t.categoryId!] = (categoryVotes[t.categoryId!] ?? 0) + 1;
  }

  // 找出得票最多的分类
  final bestCategory = categoryVotes.entries
      .reduce((a, b) => a.value > b.value ? a : b);

  // 计算置信度（基于投票比例）
  final confidence = bestCategory.value / confirmedTransactions.length;

  if (confidence < 0.5) return null;

  return CategoryMatchResult(
    categoryId: bestCategory.key,
    confidence: confidence * 0.8, // 历史匹配的置信度打8折
    matchType: 'historical',
    matchedRule: '历史相似交易 (${bestCategory.value}/${confirmedTransactions.length})',
    needsConfirmation: confidence < 0.7,
  );
}
```

### 3.5 规则学习机制

```dart
/// 从用户确认中提取特征并学习规则
Future<void> _createLearnedRule(
  TransactionFeatures features,
  int categoryId,
) async {
  // 1. 如果有明显的交易对方，优先创建对方规则
  if (features.counterparty != null && features.counterparty!.length >= 2) {
    await _ruleDbService.create(CategoryRule(
      keyword: features.counterparty!,
      categoryId: categoryId,
      matchType: 'counterparty',
      counterparty: features.counterparty,
      priority: 10,
      source: 'learned',
      autoLearn: true,
      minConfidence: 0.9,
      caseSensitive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    return;
  }

  // 2. 提取关键词（去除数字、金额等噪音）
  final keyword = _extractKeyword(features.description);
  if (keyword != null && keyword.length >= 2) {
    // 判断是否需要部分匹配（描述中包含变动内容）
    final needsPartial = _containsVariableContent(features.description);

    await _ruleDbService.create(CategoryRule(
      keyword: keyword,
      categoryId: categoryId,
      matchType: needsPartial ? 'partial' : 'exact',
      matchPosition: needsPartial ? 'contains' : null, // 部分匹配默认使用contains
      priority: 5,
      source: 'learned',
      autoLearn: true,
      minConfidence: 0.8,
      caseSensitive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }
}

/// 提取关键词（去噪）
String? _extractKeyword(String description) {
  String clean = description;

  // 移除金额符号和数字（使用简单字符串操作）
  final moneySymbols = ['¥', '\$', '€', '£', 'CNY', 'USD'];
  for (final symbol in moneySymbols) {
    clean = clean.replaceAll(symbol, '');
  }

  // 移除常见的数字模式（年月日、时间等）
  final patterns = [
    // 移除独立的数字
    (RegExp(r'\b\d+\.?\d*\b'), ''),
    // 移除括号及内容
    (RegExp(r'[（(].*?[）)]'), ''),
    (RegExp(r'【.*?】'), ''),
    (RegExp(r'\[.*?\]'), ''),
  ];

  for (final (pattern, replacement) in patterns) {
    clean = clean.replaceAll(pattern, replacement);
  }

  // 清理多余空格
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 如果清理后太短，返回null
  if (clean.length < 2) return null;

  return clean;
}

/// 检查描述中是否包含变动内容（数字、日期等）
bool _containsVariableContent(String description) {
  // 包含数字
  if (RegExp(r'\d').hasMatch(description)) return true;

  // 包含金额符号
  if (description.contains('¥') ||
      description.contains('\$') ||
      description.contains('元')) {
    return true;
  }

  return false;
}
```

## 4. AI 分类服务（可选）

### 4.1 支持的 AI 提供商

**DeepSeek**
- Chat API: `https://api.deepseek.com/v1/chat/completions`
- 模型列表 API: `https://api.deepseek.com/v1/models`
- 特点: 成本低、速度快、中文理解好
- 典型模型: deepseek-chat, deepseek-coder
- 定价: 按模型不同，通常 ¥0.001-0.01/千tokens

**Qwen (通义千问)**
- Chat API: `https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation`
- 模型列表 API: `https://dashscope.aliyuncs.com/api/v1/models`
- 特点: 阿里云提供、国内访问快、中文能力强
- 典型模型: qwen-turbo, qwen-plus, qwen-max
- 定价: 按模型不同，通常 ¥0.002-0.12/千tokens

### 4.2 接口设计

```dart
/// AI 模型信息
class AIModel {
  final String id;                // 模型ID
  final String name;              // 显示名称
  final String? description;      // 描述
  final double? inputPrice;       // 输入价格（每千tokens）
  final double? outputPrice;      // 输出价格（每千tokens）

  const AIModel({
    required this.id,
    required this.name,
    this.description,
    this.inputPrice,
    this.outputPrice,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
      inputPrice: (json['input_price'] as num?)?.toDouble(),
      outputPrice: (json['output_price'] as num?)?.toDouble(),
    );
  }
}

/// AI 分类服务提供商枚举
enum AIProvider {
  deepseek('DeepSeek'),
  qwen('通义千问');

  const AIProvider(this.displayName);
  final String displayName;
}

/// AI 分类服务抽象接口
abstract class AIClassifierService {
  /// 使用AI对交易进行分类
  Future<CategoryMatchResult?> classify(
    Transaction transaction,
    List<Category> availableCategories,
  );

  /// 批量分类（更高效）
  Future<List<CategoryMatchResult?>> classifyBatch(
    List<Transaction> transactions,
    List<Category> availableCategories,
  );

  /// 获取可用的模型列表
  Future<List<AIModel>> getAvailableModels();

  /// 测试 API 连接
  Future<bool> testConnection();

  /// 获取提供商信息
  AIProvider get provider;

  /// 当前使用的模型
  String get currentModel;
}

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
```

### 4.3 DeepSeek 实现

```dart
class DeepSeekClassifierService implements AIClassifierService {
  static const String _baseUrl = 'https://api.deepseek.com';

  final String apiKey;
  final String modelId;
  final AIClassificationConfig config; // 新增：配置对象
  final http.Client _client;
  final Duration timeout;

  DeepSeekClassifierService(
    this.apiKey,
    this.modelId,
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models = (data['data'] as List)
            .map((m) => AIModel(
                  id: m['id'] as String,
                  name: m['id'] as String,
                  description: m['description'] as String?,
                ))
            .toList();

        // 过滤出适合对话的模型（通常包含 'chat' 关键词）
        return models
            .where((m) => m.id.contains('chat') || m.id.contains('turbo'))
            .toList();
      }
    } catch (e) {
      print('Failed to fetch DeepSeek models: $e');
    }

    // 返回默认模型列表作为后备
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
        print('DeepSeek API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DeepSeek classification failed: $e');
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
      print('Failed to parse DeepSeek response: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
```

### 4.4 Qwen (通义千问) 实现

```dart
class QwenClassifierService implements AIClassifierService {
  static const String _chatUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static const String _modelsUrl = 'https://dashscope.aliyuncs.com/api/v1/models';

  final String apiKey;
  final String modelId;
  final AIClassificationConfig config; // 新增：配置对象
  final http.Client _client;
  final Duration timeout;

  QwenClassifierService(
    this.apiKey,
    this.modelId,
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final models = (data['data'] as List)
            .map((m) => AIModel(
                  id: m['model_id'] as String? ?? m['id'] as String,
                  name: m['model_name'] as String? ?? m['id'] as String,
                  description: m['description'] as String?,
                ))
            .toList();

        // 过滤出 qwen 系列对话模型
        return models
            .where((m) => m.id.toLowerCase().startsWith('qwen'))
            .toList();
      }
    } catch (e) {
      print('Failed to fetch Qwen models: $e');
    }

    // 返回默认模型列表作为后备
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
        print('Qwen API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Qwen classification failed: $e');
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
        print('No JSON found in Qwen response');
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
      print('Failed to parse Qwen response: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
```

### 4.5 AI 配置管理

**存储位置：app_settings 表**

在 `app_settings` 表中使用单个 key 存储所有 AI 配置：

```sql
-- app_settings 表存储示例
INSERT INTO app_settings (key, value, updated_at) VALUES (
  'ai_classification_config',
  '{
    "enabled": false,
    "provider": "deepseek",
    "api_key": "<加密后的字符串>",
    "model_id": "deepseek-chat",
    "confidence_threshold": 0.7,
    "auto_learn": true
  }',
  1704883200000
);
```

**AI 配置模型：**

```dart
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// AI 分类配置模型
class AIClassificationConfig {
  final bool enabled;              // 是否启用 AI 分类
  final AIProvider provider;       // 选择的提供商
  final String apiKey;             // API 密钥（加密存储）
  final String modelId;            // 选择的模型 ID
  final double confidenceThreshold; // 置信度阈值
  final bool autoLearn;            // 是否从 AI 建议中自动学习
  final String systemPrompt;       // 系统提示词（可自定义）
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
      confidenceThreshold: (json['confidence_threshold'] as num?)?.toDouble() ?? 0.7,
      autoLearn: json['auto_learn'] as bool? ?? true,
      systemPrompt: json['system_prompt'] as String? ?? _defaultSystemPrompt,
      userPromptTemplate: json['user_prompt_template'] as String? ?? _defaultUserPromptTemplate,
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
        .replaceAll('{{type}}', transaction.type == 'income' ? '收入' : '支出')
        .replaceAll('{{categories}}', categoryList);
  }

  // ==================== 加密/解密方法 ====================

  /// 加密 API Key
  static String _encryptApiKey(String plainText) {
    if (plainText.isEmpty) return '';

    try {
      // 使用设备唯一标识作为加密密钥的一部分
      final key = _getEncryptionKey();
      final iv = encrypt.IV.fromLength(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // 返回格式: iv:encrypted
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Failed to encrypt API key: $e');
      return '';
    }
  }

  /// 解密 API Key
  static String _decryptApiKey(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '';

      final key = _getEncryptionKey();
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Failed to decrypt API key: $e');
      return '';
    }
  }

  /// 获取加密密钥（基于应用标识）
  static encrypt.Key _getEncryptionKey() {
    // 使用应用包名和固定盐值生成密钥
    // 注意：这是简化方案，生产环境建议使用更安全的密钥管理
    const salt = 'family_bank_ai_config_salt_v1';
    final keyString = 'com.example.family_bank.$salt';

    // 生成 32 字节密钥
    final keyBytes = sha256.convert(utf8.encode(keyString)).bytes;
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }
}
```

**配置服务类：**

```dart
/// AI 配置服务
class AIConfigService {
  final Database _db;

  AIConfigService(this._db);

  /// 保存配置到 app_settings 表
  Future<void> saveConfig(AIClassificationConfig config) async {
    await _db.execute('''
      INSERT OR REPLACE INTO app_settings (key, value, updated_at)
      VALUES (?, ?, ?)
    ''', [
      'ai_classification_config',
      jsonEncode(config.toJson(encrypt: true)), // API Key 自动加密
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  /// 从 app_settings 表读取配置
  Future<AIClassificationConfig?> loadConfig() async {
    final result = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['ai_classification_config'],
    );

    if (result.isEmpty) {
      return AIClassificationConfig(); // 返回默认配置
    }

    try {
      final json = jsonDecode(result.first['value'] as String) as Map<String, dynamic>;
      return AIClassificationConfig.fromJson(json); // API Key 自动解密
    } catch (e) {
      print('Failed to load AI config: $e');
      return AIClassificationConfig();
    }
  }

  /// 删除配置
  Future<void> deleteConfig() async {
    await _db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['ai_classification_config'],
    );
  }

  /// 更新单个字段
  Future<void> updateField(String field, dynamic value) async {
    final config = await loadConfig();
    if (config == null) return;

    AIClassificationConfig updated;
    switch (field) {
      case 'enabled':
        updated = config.copyWith(enabled: value as bool);
        break;
      case 'provider':
        updated = config.copyWith(provider: value as AIProvider);
        break;
      case 'api_key':
        updated = config.copyWith(apiKey: value as String);
        break;
      case 'model_id':
        updated = config.copyWith(modelId: value as String);
        break;
      case 'confidence_threshold':
        updated = config.copyWith(confidenceThreshold: value as double);
        break;
      case 'auto_learn':
        updated = config.copyWith(autoLearn: value as bool);
        break;
      default:
        return;
    }

    await saveConfig(updated);
  }

  /// 检查是否已配置
  Future<bool> isConfigured() async {
    final config = await loadConfig();
    return config != null &&
           config.enabled &&
           config.apiKey.isNotEmpty &&
           config.modelId.isNotEmpty;
  }
}
```

**依赖包（添加到 pubspec.yaml）：**

```yaml
dependencies:
  # AES 加密
  encrypt: ^5.0.3

  # SHA256 哈希（crypto 通常已包含）
  crypto: ^3.0.3
```

### 4.6 AI 配置界面

```dart
class AISettingsScreen extends StatefulWidget {
  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  AIClassificationConfig? _config;
  List<AIModel>? _availableModels;
  bool _loadingModels = false;
  bool _testing = false;
  String? _testResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI 分类设置')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 启用开关
          SwitchListTile(
            title: Text('启用 AI 分类'),
            subtitle: Text('使用人工智能自动分类交易'),
            value: _config?.enabled ?? false,
            onChanged: (value) {
              setState(() {
                _config = _config?.copyWith(enabled: value);
              });
            },
          ),

          if (_config?.enabled ?? false) ...[
            Divider(),

            // 选择提供商
            ListTile(
              title: Text('AI 提供商'),
              subtitle: Text(_config?.provider.displayName ?? ''),
              trailing: Icon(Icons.chevron_right),
              onTap: _selectProvider,
            ),

            // API Key 输入
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: '请输入 ${_config?.provider.displayName} 的 API Key',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline),
                    onPressed: _showApiKeyHelp,
                  ),
                ),
                obscureText: true,
                onChanged: (value) {
                  setState(() {
                    _config = _config?.copyWith(apiKey: value);
                    // API Key 改变时，清空模型列表
                    _availableModels = null;
                  });
                },
              ),
            ),

            // 模型选择
            if (_config?.apiKey.isNotEmpty ?? false) ...[
              ListTile(
                title: Text('选择模型'),
                subtitle: _config?.modelId.isEmpty ?? true
                    ? Text('请选择模型')
                    : Text(_config!.modelId),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loadingModels)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: _loadModels,
                        tooltip: '刷新模型列表',
                      ),
                    Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _loadingModels ? null : _selectModel,
              ),
            ],

            // 测试连接
            ElevatedButton.icon(
              onPressed: (_testing || (_config?.modelId.isEmpty ?? true))
                  ? null
                  : _testConnection,
              icon: _testing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.wifi_tethering),
              label: Text('测试连接'),
            ),

            if (_testResult != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testResult!.contains('成功')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),

            Divider(),

            // 置信度阈值
            ListTile(
              title: Text('置信度阈值'),
              subtitle: Text(
                '低于此阈值的分类需要用户确认 (${(_config?.confidenceThreshold ?? 0.7) * 100}%)',
              ),
              trailing: Text('${(_config?.confidenceThreshold ?? 0.7) * 100}%'),
            ),
            Slider(
              value: _config?.confidenceThreshold ?? 0.7,
              min: 0.5,
              max: 0.95,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _config = _config?.copyWith(confidenceThreshold: value);
                });
              },
            ),

            // 自动学习
            SwitchListTile(
              title: Text('自动学习规则'),
              subtitle: Text('从 AI 分类结果中自动学习并创建规则'),
              value: _config?.autoLearn ?? true,
              onChanged: (value) {
                setState(() {
                  _config = _config?.copyWith(autoLearn: value);
                });
              },
            ),

            Divider(),

            // 提示词配置（高级选项）
            ListTile(
              title: Text('提示词配置'),
              subtitle: Text('自定义 AI 分类的提示词'),
              trailing: Icon(Icons.chevron_right),
              onTap: _editPrompts,
            ),

            // 价格说明（动态显示当前选择的模型）
            if (_availableModels != null && _config?.modelId.isNotEmpty == true)
              _buildModelPriceCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildModelPriceCard() {
    final currentModel = _availableModels?.firstWhere(
      (m) => m.id == _config?.modelId,
      orElse: () => AIModel(id: '', name: ''),
    );

    if (currentModel == null || currentModel.id.isEmpty) {
      return SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '当前模型费用',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('模型: ${currentModel.name}'),
            if (currentModel.inputPrice != null)
              Text('• 输入: ¥${currentModel.inputPrice}/千tokens'),
            if (currentModel.outputPrice != null)
              Text('• 输出: ¥${currentModel.outputPrice}/千tokens'),
            SizedBox(height: 4),
            Text(
              '注：实际费用取决于交易描述长度和分类数量',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadModels() async {
    if (_config?.apiKey.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先输入 API Key')),
      );
      return;
    }

    setState(() {
      _loadingModels = true;
    });

    try {
      final service = AIClassifierFactory.create(
        _config!.provider,
        _config!.apiKey,
        'temp', // 临时模型 ID，只用于获取模型列表
      );

      final models = await service.getAvailableModels();

      setState(() {
        _availableModels = models;
        _loadingModels = false;
      });

      if (models.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未找到可用模型')),
        );
      }
    } catch (e) {
      setState(() {
        _loadingModels = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取模型列表失败: $e')),
      );
    }
  }

  Future<void> _selectModel() async {
    if (_availableModels == null) {
      await _loadModels();
      if (_availableModels == null) return;
    }

    final selected = await showDialog<AIModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('选择模型'),
        children: _availableModels!.map((model) {
          return SimpleDialogOption(
            child: ListTile(
              title: Text(model.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.description != null) Text(model.description!),
                  if (model.inputPrice != null)
                    Text(
                      '输入: ¥${model.inputPrice}/千tokens',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              selected: _config?.modelId == model.id,
            ),
            onPressed: () => Navigator.pop(context, model),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _config = _config?.copyWith(modelId: selected.id);
      });
    }
  }
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_config?.apiKey.isEmpty ?? true) {
      setState(() {
        _testResult = '请先输入 API Key';
      });
      return;
    }

    if (_config?.modelId.isEmpty ?? true) {
      setState(() {
        _testResult = '请先选择模型';
      });
      return;
    }

    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final service = AIClassifierFactory.create(
        _config!.provider,
        _config!.apiKey,
        _config!.modelId,
      );

      final success = await service.testConnection();

      setState(() {
        _testResult = success ? '✓ 连接成功' : '✗ 连接失败，请检查 API Key';
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ 连接失败: $e';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  void _selectProvider() {
    // 显示提供商选择对话框
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('选择 AI 提供商'),
        children: AIProvider.values.map((provider) {
          return SimpleDialogOption(
            child: ListTile(
              title: Text(provider.displayName),
              selected: _config?.provider == provider,
            ),
            onPressed: () {
              setState(() {
                _config = _config?.copyWith(
                  provider: provider,
                  modelId: '', // 切换提供商时清空模型选择
                );
                _availableModels = null; // 清空模型列表
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showApiKeyHelp() {
    final provider = _config?.provider;
    String helpText = '';
    String? url;

    switch (provider) {
      case AIProvider.deepseek:
        helpText = '1. 访问 https://platform.deepseek.com\n'
            '2. 注册并登录账号\n'
            '3. 进入 API Keys 页面\n'
            '4. 创建新的 API Key 并复制';
        url = 'https://platform.deepseek.com';
        break;
      case AIProvider.qwen:
        helpText = '1. 访问阿里云控制台\n'
            '2. 开通 DashScope 服务\n'
            '3. 获取 API Key\n'
            '4. 复制到此处';
        url = 'https://dashscope.console.aliyun.com/';
        break;
      default:
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('如何获取 API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(helpText),
            if (url != null) ...[
              SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.open_in_new),
                label: Text('打开官网'),
                onPressed: () {
                  // 打开浏览器
                  // launchUrl(Uri.parse(url));
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 编辑提示词
  Future<void> _editPrompts() async {
    final result = await Navigator.push<AIClassificationConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => AIPromptEditScreen(config: _config!),
      ),
    );

    if (result != null) {
      setState(() {
        _config = result;
      });
    }
  }
}

/// 提示词编辑界面
class AIPromptEditScreen extends StatefulWidget {
  final AIClassificationConfig config;

  const AIPromptEditScreen({required this.config});

  @override
  State<AIPromptEditScreen> createState() => _AIPromptEditScreenState();
}

class _AIPromptEditScreenState extends State<AIPromptEditScreen> {
  late TextEditingController _systemPromptController;
  late TextEditingController _userPromptController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(
      text: widget.config.systemPrompt,
    );
    _userPromptController = TextEditingController(
      text: widget.config.userPromptTemplate,
    );

    _systemPromptController.addListener(_onTextChanged);
    _userPromptController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _isModified = true;
    });
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _userPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('提示词配置'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '帮助',
          ),
          if (_isModified)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _resetToDefault,
              tooltip: '重置为默认',
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // 说明卡片
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        '提示词说明',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('系统提示词定义 AI 的角色和任务'),
                  Text('用户提示词模板定义交易信息的格式'),
                  SizedBox(height: 8),
                  Text(
                    '可用变量：{{description}}, {{counterparty}}, {{amount}}, {{type}}, {{categories}}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // 系统提示词
          Text(
            '系统提示词',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _systemPromptController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: '定义 AI 的角色和任务...',
              border: OutlineInputBorder(),
              helperText: '这部分告诉 AI 它是谁以及要做什么',
            ),
          ),

          SizedBox(height: 24),

          // 用户提示词模板
          Text(
            '用户提示词模板',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _userPromptController,
            maxLines: 15,
            decoration: InputDecoration(
              hintText: '交易信息和分类列表的格式...',
              border: OutlineInputBorder(),
              helperText: '使用 {{变量名}} 格式插入交易信息',
            ),
          ),

          SizedBox(height: 24),

          // 保存按钮
          ElevatedButton(
            onPressed: _isModified ? _save : null,
            child: Text('保存'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final updated = widget.config.copyWith(
      systemPrompt: _systemPromptController.text,
      userPromptTemplate: _userPromptController.text,
    );

    Navigator.pop(context, updated);
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重置提示词'),
        content: Text('确定要重置为默认提示词吗？当前的修改将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _systemPromptController.text =
                    AIClassificationConfig._defaultSystemPrompt;
                _userPromptController.text =
                    AIClassificationConfig._defaultUserPromptTemplate;
              });
              Navigator.pop(context);
            },
            child: Text('重置', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('提示词帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '可用变量：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildVariableItem('{{description}}', '交易描述'),
              _buildVariableItem('{{counterparty}}', '交易对方'),
              _buildVariableItem('{{amount}}', '交易金额'),
              _buildVariableItem('{{type}}', '交易类型（收入/支出）'),
              _buildVariableItem('{{categories}}', '可选分类列表'),
              SizedBox(height: 16),
              Text(
                '提示：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 保持系统提示词简洁明确'),
              Text('• 用户提示词中必须包含 {{categories}}'),
              Text('• 要求返回 JSON 格式以便解析'),
              Text('• 可以添加示例来提高准确性'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableItem(String variable, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              variable,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(description, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
```

## 5. 用户界面集成

### 5.1 导入流程中的分类确认

```dart
// 在导入界面显示匹配结果
class ImportReviewScreen extends StatefulWidget {
  final List<Transaction> importedTransactions;
  final List<CategoryMatchResult> matchResults;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: importedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = importedTransactions[index];
        final matchResult = matchResults[index];

        return TransactionMatchCard(
          transaction: transaction,
          matchResult: matchResult,
          onConfirm: (categoryId) {
            // 确认分类并学习
            _confirmAndLearn(transaction, categoryId);
          },
        );
      },
    );
  }
}
```

### 5.2 置信度可视化

```dart
Widget _buildConfidenceBadge(CategoryMatchResult result) {
  Color color;
  String label;

  if (result.confidence >= 0.9) {
    color = Colors.green;
    label = '高置信';
  } else if (result.confidence >= 0.7) {
    color = Colors.orange;
    label = '中等';
  } else {
    color = Colors.grey;
    label = '需确认';
  }

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label ${(result.confidence * 100).toInt()}%',
      style: TextStyle(color: color, fontSize: 12),
    ),
  );
}
```

## 6. 实施计划

### Phase 1: 基础规则匹配（1-2天）
- [ ] 扩展 CategoryRule 模型和数据库表
- [ ] 实现精确匹配和模糊匹配
- [ ] 实现规则管理界面

### Phase 2: 学习机制（1-2天）
- [ ] 实现历史交易相似度匹配
- [ ] 实现从用户确认中自动学习规则
- [ ] 实现规则优先级自动调整

### Phase 3: AI 集成（可选，2-3天）
- [ ] 设计 AI 分类服务接口
- [ ] 实现 API 调用逻辑
- [ ] 添加 AI 开关和配置界面

### Phase 4: 优化和测试（1-2天）
- [ ] 批量导入性能优化
- [ ] 规则冲突检测和处理
- [ ] 用户体验优化

## 7. 配置选项

在 app_settings 表中添加以下配置：

```dart
// AI 分类相关设置
- `ai_classification_enabled`: bool   // 是否启用AI分类
- `ai_api_endpoint`: string          // API 端点
- `ai_confidence_threshold`: double  // AI 置信度阈值
- `auto_learn_enabled`: bool         // 是否启用自动学习
- `auto_learn_threshold`: int        // 自动学习阈值（相似交易数量）
```

## 8. 性能考虑

### 8.1 匹配策略优化
**✅ 避免使用正则表达式**
- 所有匹配逻辑使用简单字符串操作（contains、startsWith、endsWith）
- 避免正则表达式导致的 CPU 飙升
- 仅在规则学习的预处理阶段使用少量 RegExp 进行文本清理（一次性操作，不影响匹配性能）

**快速匹配路径**
- 按优先级排序规则，高优先级规则优先匹配
- 交易对方匹配优先（最快路径）
- 精确匹配次之，部分匹配最后

### 8.2 缓存策略
- 规则列表缓存（内存中，按 matchType 分组）
- 分类树缓存
- 最近匹配结果缓存（LRU 策略）

### 8.3 批量处理
- 导入时批量匹配，减少数据库查询
- 规则更新批量提交
- 预加载所有活跃规则到内存

### 8.4 索引优化
- 添加必要的数据库索引（keyword, counterparty, priority）
- 定期清理无效规则（match_count = 0 且 auto_learn = 1）

## 9. 隐私和安全

### 9.1 数据保护
- AI 分类是可选功能，默认关闭
- 如果使用云端 AI，需要明确告知用户
- 建议使用本地 AI 模型或私有部署

### 9.2 规则管理
- 用户可以查看、编辑、删除自动学习的规则
- 提供规则导出/导入功能
- 规则冲突时优先使用用户手动创建的规则

## 10. 未来扩展

- 支持多条件组合规则（金额范围 + 关键词）
- 支持时间相关规则（特定日期自动分类为固定支出）
- 分类推荐解释功能（告诉用户为什么推荐这个分类）
- 规则模板市场（用户可以分享和下载规则模板）
