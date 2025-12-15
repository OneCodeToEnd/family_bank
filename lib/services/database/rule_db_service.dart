import 'package:sqflite/sqflite.dart';
import '../../models/category_rule.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 分类规则数据库操作服务
class RuleDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建规则
  Future<int> createRule(CategoryRule rule) async {
    final db = await _dbService.database;
    return await db.insert(
      DbConstants.tableCategoryRules,
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有规则
  Future<List<CategoryRule>> getAllRules() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      orderBy: '${DbConstants.columnRulePriority} DESC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }

  /// 获取所有启用的规则
  Future<List<CategoryRule>> getActiveRules() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleIsActive} = ?',
      whereArgs: [1],
      orderBy: '${DbConstants.columnRulePriority} DESC, ${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }

  /// 根据ID获取规则
  Future<CategoryRule?> getRuleById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CategoryRule.fromMap(maps.first);
  }

  /// 根据关键词获取规则
  Future<CategoryRule?> getRuleByKeyword(String keyword) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleKeyword} = ? AND ${DbConstants.columnRuleIsActive} = ?',
      whereArgs: [keyword, 1],
      orderBy: '${DbConstants.columnRulePriority} DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CategoryRule.fromMap(maps.first);
  }

  /// 根据分类ID获取规则
  Future<List<CategoryRule>> getRulesByCategoryId(int categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleCategoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DbConstants.columnRulePriority} DESC',
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }

  /// 根据来源获取规则（user/model）
  Future<List<CategoryRule>> getRulesBySource(String source) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleSource} = ?',
      whereArgs: [source],
      orderBy: '${DbConstants.columnRulePriority} DESC',
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }

  /// 更新规则
  Future<int> updateRule(CategoryRule rule) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableCategoryRules,
      rule.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [rule.id],
    );
  }

  /// 更新规则匹配次数
  Future<int> incrementRuleMatchCount(int ruleId) async {
    final db = await _dbService.database;

    // 获取当前匹配次数
    final rule = await getRuleById(ruleId);
    if (rule == null) return 0;

    return await db.update(
      DbConstants.tableCategoryRules,
      {
        DbConstants.columnRuleMatchCount: rule.matchCount + 1,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [ruleId],
    );
  }

  /// 删除规则
  Future<int> deleteRule(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 切换规则启用状态
  Future<int> toggleRuleActive(int id, bool isActive) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableCategoryRules,
      {
        DbConstants.columnRuleIsActive: isActive ? 1 : 0,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 检查关键词是否已存在
  Future<bool> isKeywordExists(String keyword, {int? excludeId}) async {
    final db = await _dbService.database;

    String whereClause = '${DbConstants.columnRuleKeyword} = ?';
    List<dynamic> whereArgs = [keyword];

    if (excludeId != null) {
      whereClause += ' AND ${DbConstants.columnId} != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      DbConstants.tableCategoryRules,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// 匹配账单描述，返回推荐的分类ID列表（按优先级排序）
  Future<List<Map<String, dynamic>>> matchDescription(String description) async {
    // 获取所有启用的规则
    final rules = await getActiveRules();

    List<Map<String, dynamic>> matches = [];

    for (var rule in rules) {
      if (description.contains(rule.keyword)) {
        matches.add({
          'rule': rule,
          'category_id': rule.categoryId,
          'priority': rule.priority,
          'confidence': _calculateConfidence(description, rule.keyword),
        });
      }
    }

    // 按优先级和置信度排序
    matches.sort((a, b) {
      int priorityCompare = (b['priority'] as int).compareTo(a['priority'] as int);
      if (priorityCompare != 0) return priorityCompare;
      return (b['confidence'] as double).compareTo(a['confidence'] as double);
    });

    return matches;
  }

  /// 计算匹配置信度（简单实现）
  double _calculateConfidence(String description, String keyword) {
    // 关键词在描述中的位置越靠前，置信度越高
    final index = description.indexOf(keyword);
    if (index == -1) return 0.0;

    // 关键词长度占描述长度的比例
    final lengthRatio = keyword.length / description.length;

    // 位置权重（越靠前权重越高）
    final positionWeight = 1.0 - (index / description.length);

    // 综合计算置信度
    return (lengthRatio * 0.5 + positionWeight * 0.5).clamp(0.0, 1.0);
  }

  /// 批量创建规则
  Future<List<int>> createRulesBatch(List<CategoryRule> rules) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var rule in rules) {
      batch.insert(
        DbConstants.tableCategoryRules,
        rule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  /// 根据分类删除所有关联规则
  Future<int> deleteRulesByCategoryId(int categoryId) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleCategoryId} = ?',
      whereArgs: [categoryId],
    );
  }

  /// 获取规则统计信息
  Future<Map<String, dynamic>> getRuleStatistics() async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_count,
        SUM(CASE WHEN ${DbConstants.columnRuleIsActive} = 1 THEN 1 ELSE 0 END) as active_count,
        SUM(CASE WHEN ${DbConstants.columnRuleSource} = 'user' THEN 1 ELSE 0 END) as user_count,
        SUM(CASE WHEN ${DbConstants.columnRuleSource} = 'model' THEN 1 ELSE 0 END) as model_count,
        SUM(${DbConstants.columnRuleMatchCount}) as total_matches
      FROM ${DbConstants.tableCategoryRules}
    ''');

    if (result.isEmpty) {
      return {
        'total_count': 0,
        'active_count': 0,
        'user_count': 0,
        'model_count': 0,
        'total_matches': 0,
      };
    }

    return result.first;
  }

  /// 获取最常用的规则（按匹配次数排序）
  Future<List<CategoryRule>> getTopUsedRules({int limit = 10}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleMatchCount} > ?',
      whereArgs: [0],
      orderBy: '${DbConstants.columnRuleMatchCount} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }

  /// 搜索规则（按关键词）
  Future<List<CategoryRule>> searchRules(String keyword) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleKeyword} LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: '${DbConstants.columnRulePriority} DESC',
    );

    return List.generate(maps.length, (i) {
      return CategoryRule.fromMap(maps[i]);
    });
  }
}
