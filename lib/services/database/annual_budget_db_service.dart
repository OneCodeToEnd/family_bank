import 'package:sqflite/sqflite.dart';
import '../../models/annual_budget.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 年度预算数据库操作服务
class AnnualBudgetDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建年度预算
  Future<int> createAnnualBudget(AnnualBudget budget) async {
    final db = await _dbService.database;
    return await db.insert(
      DbConstants.tableAnnualBudgets,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有年度预算
  Future<List<AnnualBudget>> getAllAnnualBudgets() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAnnualBudgets,
      orderBy: '${DbConstants.columnAnnualBudgetYear} DESC, ${DbConstants.columnCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return AnnualBudget.fromMap(maps[i]);
    });
  }

  /// 根据家庭和年份获取年度预算
  Future<List<AnnualBudget>> getAnnualBudgetsByYear(int familyId, int year) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAnnualBudgets,
      where: '${DbConstants.columnAnnualBudgetFamilyId} = ? AND ${DbConstants.columnAnnualBudgetYear} = ?',
      whereArgs: [familyId, year],
      orderBy: '${DbConstants.columnCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return AnnualBudget.fromMap(maps[i]);
    });
  }

  /// 根据ID获取年度预算
  Future<AnnualBudget?> getAnnualBudgetById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAnnualBudgets,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AnnualBudget.fromMap(maps.first);
  }

  /// 根据家庭、分类和年份获取年度预算
  Future<AnnualBudget?> getAnnualBudgetByCategoryAndYear(
    int familyId,
    int categoryId,
    int year,
  ) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAnnualBudgets,
      where: '${DbConstants.columnAnnualBudgetFamilyId} = ? AND ${DbConstants.columnAnnualBudgetCategoryId} = ? AND ${DbConstants.columnAnnualBudgetYear} = ?',
      whereArgs: [familyId, categoryId, year],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AnnualBudget.fromMap(maps.first);
  }

  /// 更新年度预算
  Future<int> updateAnnualBudget(AnnualBudget budget) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableAnnualBudgets,
      budget.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [budget.id],
    );
  }

  /// 删除年度预算
  Future<int> deleteAnnualBudget(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableAnnualBudgets,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 检查预算是否存在
  Future<bool> budgetExists(int familyId, int categoryId, int year) async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableAnnualBudgets,
      where: '${DbConstants.columnAnnualBudgetFamilyId} = ? AND ${DbConstants.columnAnnualBudgetCategoryId} = ? AND ${DbConstants.columnAnnualBudgetYear} = ?',
      whereArgs: [familyId, categoryId, year],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// 获取月度预算统计（单个分类）
  Future<Map<String, dynamic>> getMonthlyBudgetStats(
    int familyId,
    int categoryId,
    int year,
    int month,
  ) async {
    final db = await _dbService.database;

    // 格式化年月为字符串（如 '2026', '01'）
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');

    final result = await db.rawQuery('''\n      SELECT
        ab.${DbConstants.columnId} as id, ab.${DbConstants.columnAnnualBudgetType} as type,
        ab.${DbConstants.columnAnnualBudgetCategoryId} as category_id,
        ab.${DbConstants.columnAnnualBudgetMonthlyAmount} as monthly_amount,
        COALESCE(SUM(t.${DbConstants.columnTransactionAmount}), 0) as spent_amount
      FROM ${DbConstants.tableAnnualBudgets} ab
      LEFT JOIN ${DbConstants.tableTransactions} t
        ON t.${DbConstants.columnTransactionCategoryId} = ab.${DbConstants.columnAnnualBudgetCategoryId}
        AND t.${DbConstants.columnTransactionType} = ab.${DbConstants.columnAnnualBudgetType}
        AND strftime('%Y', datetime(t.${DbConstants.columnTransactionTime} / 1000, 'unixepoch')) = ?
        AND strftime('%m', datetime(t.${DbConstants.columnTransactionTime} / 1000, 'unixepoch')) = ?
      WHERE ab.${DbConstants.columnAnnualBudgetFamilyId} = ?
        AND ab.${DbConstants.columnAnnualBudgetCategoryId} = ?
        AND ab.${DbConstants.columnAnnualBudgetYear} = ?
      GROUP BY ab.${DbConstants.columnId}
    ''', [yearStr, monthStr, familyId, categoryId, year]);

    if (result.isEmpty) {
      return {};
    }

    final data = result.first;
    final monthlyAmount = (data['monthly_amount'] as num?)?.toDouble() ?? 0.0;
    final spentAmount = (data['spent_amount'] as num?)?.toDouble() ?? 0.0;
    final remainingAmount = monthlyAmount - spentAmount;
    final usagePercentage = monthlyAmount > 0 ? (spentAmount / monthlyAmount * 100) : 0.0;

    return {
      'id': data['id'],
      'category_id': data['category_id'],
      'monthly_amount': monthlyAmount,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'usage_percentage': usagePercentage,
    };
  }

  /// 获取所有月度预算统计（所有分类）
  Future<List<Map<String, dynamic>>> getAllMonthlyStats(
    int familyId,
    int year,
    int month,
  ) async {
    final db = await _dbService.database;

    // 格式化年月为字符串
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');

    final result = await db.rawQuery('''\n      SELECT
        ab.${DbConstants.columnId} as id, ab.${DbConstants.columnAnnualBudgetType} as type,
        ab.${DbConstants.columnAnnualBudgetCategoryId} as category_id,
        ab.${DbConstants.columnAnnualBudgetMonthlyAmount} as monthly_amount,
        c.${DbConstants.columnCategoryName} as category_name,
        c.${DbConstants.columnCategoryIcon} as category_icon,
        c.${DbConstants.columnCategoryColor} as category_color,
        COALESCE(SUM(t.${DbConstants.columnTransactionAmount}), 0) as spent_amount
      FROM ${DbConstants.tableAnnualBudgets} ab
      INNER JOIN ${DbConstants.tableCategories} c
        ON ab.${DbConstants.columnAnnualBudgetCategoryId} = c.${DbConstants.columnId}
      LEFT JOIN ${DbConstants.tableTransactions} t
        ON t.${DbConstants.columnTransactionCategoryId} = ab.${DbConstants.columnAnnualBudgetCategoryId}
        AND t.${DbConstants.columnTransactionType} = ab.${DbConstants.columnAnnualBudgetType}
        AND strftime('%Y', datetime(t.${DbConstants.columnTransactionTime} / 1000, 'unixepoch')) = ?
        AND strftime('%m', datetime(t.${DbConstants.columnTransactionTime} / 1000, 'unixepoch')) = ?
      WHERE ab.${DbConstants.columnAnnualBudgetFamilyId} = ?
        AND ab.${DbConstants.columnAnnualBudgetYear} = ?
      GROUP BY ab.${DbConstants.columnId}
      ORDER BY (COALESCE(SUM(t.${DbConstants.columnTransactionAmount}), 0) / ab.${DbConstants.columnAnnualBudgetMonthlyAmount}) DESC
    ''', [yearStr, monthStr, familyId, year]);

    return result.map((data) {
      final monthlyAmount = (data['monthly_amount'] as num?)?.toDouble() ?? 0.0;
      final spentAmount = (data['spent_amount'] as num?)?.toDouble() ?? 0.0;
      final remainingAmount = monthlyAmount - spentAmount;
      final usagePercentage = monthlyAmount > 0 ? (spentAmount / monthlyAmount * 100) : 0.0;

      return {
        'id': data['id'],
        'category_id': data['category_id'],
        'category_name': data['category_name'],
        'category_icon': data['category_icon'],
        'category_color': data['category_color'],
        'monthly_amount': monthlyAmount,
        'spent_amount': spentAmount,
        'remaining_amount': remainingAmount,
        'usage_percentage': usagePercentage,
      };
    }).toList();
  }
}
