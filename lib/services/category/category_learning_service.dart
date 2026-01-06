import 'package:sqflite/sqflite.dart';
import '../../models/transaction.dart' as models;
import '../../models/category_rule.dart';
import '../../constants/db_constants.dart';
import '../database/database_service.dart';
import '../database/category_rule_db_service.dart';

/// 交易特征
class TransactionFeatures {
  final String? counterparty;
  final String description;
  final bool hasVariableContent;

  TransactionFeatures({
    this.counterparty,
    required this.description,
    required this.hasVariableContent,
  });
}

/// 分类学习服务
/// 负责从用户确认中自动学习规则
class CategoryLearningService {
  final DatabaseService _dbService = DatabaseService();
  CategoryRuleDbService? _ruleDbService;
  Database? _db;

  Future<void> _init() async {
    if (_db != null) return; // 已经初始化

    _db = await _dbService.database;
    _ruleDbService = CategoryRuleDbService(_db!);
  }

  /// 从用户确认中学习规则
  Future<void> learnFromConfirmation(
    models.Transaction transaction,
    int confirmedCategoryId,
  ) async {
    await _init(); // 确保初始化完成

    // 提取交易特征
    final features = _extractFeatures(transaction);

    // 检查是否已有相似规则
    final existingRule = await _findSimilarRule(features, confirmedCategoryId);

    if (existingRule != null) {
      // 更新现有规则的匹配次数和优先级
      await _updateRuleStats(existingRule);
    } else {
      // 创建新规则
      await _createLearnedRule(features, confirmedCategoryId);
    }
  }

  /// 提取交易特征
  TransactionFeatures _extractFeatures(models.Transaction transaction) {
    final description = transaction.description ?? '';
    final counterparty = transaction.counterparty;

    // 检查描述中是否包含变动内容
    final hasVariableContent = _containsVariableContent(description);

    return TransactionFeatures(
      counterparty: counterparty?.isNotEmpty == true ? counterparty : null,
      description: description,
      hasVariableContent: hasVariableContent,
    );
  }

  /// 查找相似规则
  Future<CategoryRule?> _findSimilarRule(
    TransactionFeatures features,
    int categoryId,
  ) async {
    // 优先查找交易对方规则
    if (features.counterparty != null) {
      return await _ruleDbService!.findSimilarRule(
        keyword: features.counterparty!,
        categoryId: categoryId,
        counterparty: features.counterparty,
      );
    }

    // 提取关键词
    final keyword = _extractKeyword(features.description);
    if (keyword != null && keyword.length >= 2) {
      return await _ruleDbService!.findSimilarRule(
        keyword: keyword,
        categoryId: categoryId,
      );
    }

    return null;
  }

  /// 更新规则统计信息
  Future<void> _updateRuleStats(CategoryRule rule) async {
    // 增加匹配次数
    await _ruleDbService!.incrementMatchCount(rule.id!);

    // 根据匹配次数动态调整优先级
    final newPriority = _calculatePriority(rule.matchCount + 1);
    if (newPriority != rule.priority) {
      await _ruleDbService!.updatePriority(rule.id!, newPriority);
    }
  }

  /// 创建学习到的规则
  Future<void> _createLearnedRule(
    TransactionFeatures features,
    int categoryId,
  ) async {
    // 1. 如果有明显的交易对方，优先创建对方规则
    if (features.counterparty != null && features.counterparty!.length >= 2) {
      await _ruleDbService!.create(CategoryRule(
        keyword: features.counterparty!,
        categoryId: categoryId,
        matchType: RuleMatchType.counterparty,
        counterparty: features.counterparty,
        priority: 10,
        source: RuleSource.learned,
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
      final needsPartial = features.hasVariableContent;

      await _ruleDbService!.create(CategoryRule(
        keyword: keyword,
        categoryId: categoryId,
        matchType: needsPartial ? RuleMatchType.partial : RuleMatchType.exact,
        matchPosition:
            needsPartial ? RuleMatchPosition.contains : null, // 部分匹配默认使用contains
        priority: 5,
        source: RuleSource.learned,
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
    final moneySymbols = ['¥', '\$', '€', '£', 'CNY', 'USD', '元'];
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

  /// 根据匹配次数计算优先级
  int _calculatePriority(int matchCount) {
    // 匹配次数越多，优先级越高
    if (matchCount >= 50) return 50;
    if (matchCount >= 20) return 30;
    if (matchCount >= 10) return 20;
    if (matchCount >= 5) return 10;
    return 5;
  }

  /// 批量学习（适用于用户批量确认分类的场景）
  Future<void> learnFromBatch(
    List<models.Transaction> transactions,
    int categoryId,
  ) async {
    for (final transaction in transactions) {
      await learnFromConfirmation(transaction, categoryId);
    }
  }

  /// 清理低效规则
  /// 删除自动学习的、长时间未匹配到的规则
  Future<int> cleanupIneffectiveRules({
    int minMatchCount = 1,
    Duration? inactivityPeriod,
  }) async {
    await _init();

    if (inactivityPeriod != null) {
      // 删除超过指定时间未使用且匹配次数低的规则
      final cutoffTime =
          DateTime.now().subtract(inactivityPeriod).millisecondsSinceEpoch;

      final result = await _db!.delete(
        DbConstants.tableCategoryRules,
        where: '''
          ${DbConstants.columnRuleAutoLearn} = 1
          AND ${DbConstants.columnRuleMatchCount} < ?
          AND ${DbConstants.columnUpdatedAt} < ?
        ''',
        whereArgs: [minMatchCount, cutoffTime],
      );

      return result;
    } else {
      // 仅根据匹配次数清理
      return await _ruleDbService!.cleanupIneffectiveRules(
        minMatchCount: minMatchCount,
      );
    }
  }

  /// 获取学习统计信息
  Future<Map<String, dynamic>> getLearningStatistics() async {
    await _init();

    final stats = await _ruleDbService!.getStatistics();

    return {
      'total_rules': stats['total'] ?? 0,
      'active_rules': stats['active'] ?? 0,
      'learned_rules': stats['auto_learned'] ?? 0,
      'user_rules': stats['user_created'] ?? 0,
      'total_matches': stats['total_matches'] ?? 0,
    };
  }
}
