import 'package:sqflite/sqflite.dart';
import '../../models/category_rule.dart';
import '../../constants/db_constants.dart';

/// 分类规则数据库服务
class CategoryRuleDbService {
  final Database _db;

  CategoryRuleDbService(this._db);

  /// 创建规则
  Future<int> create(CategoryRule rule) async {
    return await _db.insert(
      DbConstants.tableCategoryRules,
      rule.toMap(),
    );
  }

  /// 更新规则
  Future<int> update(CategoryRule rule) async {
    return await _db.update(
      DbConstants.tableCategoryRules,
      rule.toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [rule.id],
    );
  }

  /// 删除规则
  Future<int> delete(int id) async {
    return await _db.delete(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID查询规则
  Future<CategoryRule?> findById(int id) async {
    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return CategoryRule.fromMap(results.first);
  }

  /// 查询所有规则
  Future<List<CategoryRule>> findAll({bool activeOnly = false}) async {
    final where = activeOnly ? '${DbConstants.columnRuleIsActive} = 1' : null;

    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: where,
      orderBy: '${DbConstants.columnRulePriority} DESC, ${DbConstants.columnCreatedAt} DESC',
    );

    return results.map((map) => CategoryRule.fromMap(map)).toList();
  }

  /// 根据分类ID查询规则
  Future<List<CategoryRule>> findByCategoryId(int categoryId) async {
    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleCategoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DbConstants.columnRulePriority} DESC',
    );

    return results.map((map) => CategoryRule.fromMap(map)).toList();
  }

  /// 根据匹配类型查询规则
  Future<List<CategoryRule>> findByMatchType(String matchType) async {
    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleMatchType} = ?',
      whereArgs: [matchType],
      orderBy: '${DbConstants.columnRulePriority} DESC, ${DbConstants.columnRuleMatchCount} DESC',
    );

    return results.map((map) => CategoryRule.fromMap(map)).toList();
  }

  /// 根据交易对方查询规则
  Future<CategoryRule?> findByCounterparty(String counterparty) async {
    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleCounterparty} = ? AND ${DbConstants.columnRuleIsActive} = 1',
      whereArgs: [counterparty],
      orderBy: '${DbConstants.columnRulePriority} DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CategoryRule.fromMap(results.first);
  }

  /// 根据关键词查询规则
  Future<CategoryRule?> findByKeyword(String keyword) async {
    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleKeyword} = ?',
      whereArgs: [keyword],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CategoryRule.fromMap(results.first);
  }

  /// 增加规则的匹配次数
  Future<void> incrementMatchCount(int ruleId) async {
    await _db.rawUpdate('''
      UPDATE ${DbConstants.tableCategoryRules}
      SET ${DbConstants.columnRuleMatchCount} = ${DbConstants.columnRuleMatchCount} + 1,
          ${DbConstants.columnUpdatedAt} = ?
      WHERE ${DbConstants.columnId} = ?
    ''', [DateTime.now().millisecondsSinceEpoch, ruleId]);
  }

  /// 更新规则优先级
  Future<void> updatePriority(int ruleId, int priority) async {
    await _db.update(
      DbConstants.tableCategoryRules,
      {
        DbConstants.columnRulePriority: priority,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [ruleId],
    );
  }

  /// 切换规则启用状态
  Future<void> toggleActive(int ruleId) async {
    final rule = await findById(ruleId);
    if (rule != null) {
      await _db.update(
        DbConstants.tableCategoryRules,
        {
          DbConstants.columnRuleIsActive: rule.isActive ? 0 : 1,
          DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [ruleId],
      );
    }
  }

  /// 查找相似规则（用于学习时避免重复）
  Future<CategoryRule?> findSimilarRule({
    required String keyword,
    required int categoryId,
    String? counterparty,
  }) async {
    String where;
    List<dynamic> whereArgs;

    if (counterparty != null) {
      where = '${DbConstants.columnRuleCounterparty} = ? AND ${DbConstants.columnRuleCategoryId} = ?';
      whereArgs = [counterparty, categoryId];
    } else {
      where = '${DbConstants.columnRuleKeyword} = ? AND ${DbConstants.columnRuleCategoryId} = ?';
      whereArgs = [keyword, categoryId];
    }

    final results = await _db.query(
      DbConstants.tableCategoryRules,
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (results.isEmpty) return null;
    return CategoryRule.fromMap(results.first);
  }

  /// 批量删除自动学习的低效规则
  Future<int> cleanupIneffectiveRules({int minMatchCount = 1}) async {
    return await _db.delete(
      DbConstants.tableCategoryRules,
      where: '${DbConstants.columnRuleAutoLearn} = 1 AND ${DbConstants.columnRuleMatchCount} < ?',
      whereArgs: [minMatchCount],
    );
  }

  /// 获取规则统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    final result = await _db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN ${DbConstants.columnRuleIsActive} = 1 THEN 1 ELSE 0 END) as active,
        SUM(CASE WHEN ${DbConstants.columnRuleSource} = 'user' THEN 1 ELSE 0 END) as user_created,
        SUM(CASE WHEN ${DbConstants.columnRuleSource} = 'learned' THEN 1 ELSE 0 END) as auto_learned,
        SUM(${DbConstants.columnRuleMatchCount}) as total_matches
      FROM ${DbConstants.tableCategoryRules}
    ''');

    return result.first;
  }
}
