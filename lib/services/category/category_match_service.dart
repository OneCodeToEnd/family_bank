import 'package:sqflite/sqflite.dart';
import '../../models/transaction.dart' as models;
import '../../models/category.dart';
import '../../models/category_rule.dart';
import '../../models/category_match_result.dart';
import '../../models/category_suggestion.dart';
import '../database/database_service.dart';
import '../database/category_rule_db_service.dart';
import '../database/transaction_db_service.dart';

/// 分类匹配服务
/// 负责为交易自动匹配合适的分类
class CategoryMatchService {
  final DatabaseService _dbService = DatabaseService();
  CategoryRuleDbService? _ruleDbService;
  TransactionDbService? _transactionDbService;
  Database? _db;

  Future<void> _init() async {
    if (_db != null) return; // 已经初始化

    _db = await _dbService.database;
    _ruleDbService = CategoryRuleDbService(_db!);
    _transactionDbService = TransactionDbService();
  }

  /// 为交易匹配分类
  Future<CategoryMatchResult> matchCategory(models.Transaction transaction) async {
    await _init(); // 确保已初始化

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

    // 4. 无法匹配，返回需要用户确认的结果
    return CategoryMatchResult(
      confidence: 0.0,
      matchType: 'manual',
      needsConfirmation: true,
      alternatives: await _getSuggestedCategories(transaction),
    );
  }

  /// 批量匹配（导入时使用）
  Future<List<CategoryMatchResult>> matchBatch(
    List<models.Transaction> transactions,
  ) async {
    return Future.wait(
      transactions.map((t) => matchCategory(t)),
    );
  }

  /// 精确匹配策略
  Future<CategoryMatchResult?> _exactMatch(models.Transaction transaction) async {
    // 1. 优先匹配交易对方
    if (transaction.counterparty != null &&
        transaction.counterparty!.isNotEmpty) {
      final rule = await _ruleDbService!.findByCounterparty(
        transaction.counterparty!,
      );
      if (rule != null && rule.isActive) {
        await _ruleDbService!.incrementMatchCount(rule.id!);
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
      final rules = await _ruleDbService!.findByMatchType('exact');
      for (final rule in rules.where((r) => r.isActive)) {
        final keyword =
            rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
        final desc = rule.caseSensitive
            ? transaction.description!
            : transaction.description!.toLowerCase();

        // 检查主关键词
        if (desc.contains(keyword)) {
          await _ruleDbService!.incrementMatchCount(rule.id!);
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
          final aliasToMatch =
              rule.caseSensitive ? alias : alias.toLowerCase();
          if (desc.contains(aliasToMatch)) {
            await _ruleDbService!.incrementMatchCount(rule.id!);
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

  /// 部分匹配策略
  Future<CategoryMatchResult?> _partialMatch(models.Transaction transaction) async {
    if (transaction.description == null) return null;

    final description = transaction.description!;
    final rules = await _ruleDbService!.findByMatchType('partial');
    final matches = <({CategoryRule rule, double confidence})>[];

    for (final rule in rules.where((r) => r.isActive)) {
      bool isMatch = false;
      final keyword =
          rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
      final desc =
          rule.caseSensitive ? description : description.toLowerCase();

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
          final aliasToMatch =
              rule.caseSensitive ? alias : alias.toLowerCase();
          if (desc.contains(aliasToMatch)) {
            final confidence =
                _calculateConfidence(rule) * 0.95; // 别名匹配稍微降低置信度
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

    await _ruleDbService!.incrementMatchCount(bestMatch.rule.id!);

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

  /// 历史学习匹配
  Future<CategoryMatchResult?> _historicalMatch(models.Transaction transaction) async {
    if (transaction.description == null) return null;

    // 查找相似的已确认交易
    final similarTransactions = await _transactionDbService!.findSimilar(
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
    final bestCategory = categoryVotes.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    // 计算置信度（基于投票比例）
    final confidence = bestCategory.value / confirmedTransactions.length;

    if (confidence < 0.5) return null;

    return CategoryMatchResult(
      categoryId: bestCategory.key,
      confidence: confidence * 0.8, // 历史匹配的置信度打8折
      matchType: 'historical',
      matchedRule:
          '历史相似交易 (${bestCategory.value}/${confirmedTransactions.length})',
      needsConfirmation: confidence < 0.7,
    );
  }

  /// 计算置信度
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

  /// 构建备选分类列表
  Future<List<CategorySuggestion>> _buildAlternatives(
    List<({CategoryRule rule, double confidence})> matches,
  ) async {
    final suggestions = <CategorySuggestion>[];

    for (final match in matches) {
      final category = await _getCategoryById(match.rule.categoryId);
      if (category != null) {
        suggestions.add(
          CategorySuggestion(
            categoryId: category.id!,
            categoryName: category.name,
            confidence: match.confidence,
            reason: '匹配规则: ${match.rule.keyword}',
          ),
        );
      }
    }

    return suggestions;
  }

  /// 获取建议的分类（当无法匹配时）
  Future<List<CategorySuggestion>> _getSuggestedCategories(
    models.Transaction transaction,
  ) async {
    // 基于交易类型返回常用分类
    final categories = await _getFrequentCategories(transaction.type);
    return categories
        .take(5)
        .map((c) => CategorySuggestion(
              categoryId: c.id!,
              categoryName: c.name,
              confidence: 0.3,
              reason: '常用分类',
            ))
        .toList();
  }

  /// 获取常用分类
  Future<List<Category>> _getFrequentCategories(String type) async {
    // 查询该类型下使用最频繁的分类
    final result = await _db!.rawQuery('''
      SELECT c.*, COUNT(t.id) as usage_count
      FROM categories c
      LEFT JOIN transactions t ON c.id = t.category_id
      WHERE c.type = ? AND c.is_hidden = 0
      GROUP BY c.id
      ORDER BY usage_count DESC, c.sort_order ASC
      LIMIT 10
    ''', [type]);

    return result.map((map) => Category.fromMap(map)).toList();
  }

  /// 根据ID获取分类
  Future<Category?> _getCategoryById(int categoryId) async {
    final result = await _db!.query(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );

    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }
}
