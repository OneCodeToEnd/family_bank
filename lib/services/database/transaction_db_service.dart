import 'package:sqflite/sqflite.dart';
import '../../models/transaction.dart' as model;
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 账单流水数据库操作服务
class TransactionDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建账单
  Future<int> createTransaction(model.Transaction transaction) async {
    final db = await _dbService.database;

    // 检查是否存在重复记录
    if (await isDuplicateTransaction(transaction.hash)) {
      throw Exception('Duplicate transaction detected');
    }

    return await db.insert(
      DbConstants.tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量创建账单（去重）
  Future<Map<String, dynamic>> createTransactionsBatch(
    List<model.Transaction> transactions,
  ) async {
    final db = await _dbService.database;
    final batch = db.batch();

    int successCount = 0;
    int duplicateCount = 0;
    List<String> duplicateHashes = [];

    for (var transaction in transactions) {
      // 检查重复
      if (await isDuplicateTransaction(transaction.hash)) {
        duplicateCount++;
        duplicateHashes.add(transaction.hash);
        continue;
      }

      batch.insert(
        DbConstants.tableTransactions,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      successCount++;
    }

    await batch.commit(noResult: true);

    return {
      'success_count': successCount,
      'duplicate_count': duplicateCount,
      'duplicate_hashes': duplicateHashes,
    };
  }

  /// 检查是否存在重复账单
  Future<bool> isDuplicateTransaction(String hash) async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionHash} = ?',
      whereArgs: [hash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// 获取所有账单
  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 根据ID获取账单
  Future<model.Transaction?> getTransactionById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return model.Transaction.fromMap(maps.first);
  }

  /// 根据账户ID获取账单
  Future<List<model.Transaction>> getTransactionsByAccountId(int accountId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionAccountId} = ?',
      whereArgs: [accountId],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 根据分类ID获取账单
  Future<List<model.Transaction>> getTransactionsByCategoryId(int categoryId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionCategoryId} = ?',
      whereArgs: [categoryId],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 根据类型获取账单（收入/支出）
  Future<List<model.Transaction>> getTransactionsByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionType} = ?',
      whereArgs: [type],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 获取未分类的账单
  Future<List<model.Transaction>> getUncategorizedTransactions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionCategoryId} IS NULL',
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 获取未确认的账单
  Future<List<model.Transaction>> getUnconfirmedTransactions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionIsConfirmed} = ?',
      whereArgs: [0],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 根据时间范围获取账单
  Future<List<model.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int? accountId,
    int? categoryId,
    String? type,
  }) async {
    final db = await _dbService.database;

    String whereClause = '${DbConstants.columnTransactionTime} >= ? AND ${DbConstants.columnTransactionTime} <= ?';
    List<dynamic> whereArgs = [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ];

    if (accountId != null) {
      whereClause += ' AND ${DbConstants.columnTransactionAccountId} = ?';
      whereArgs.add(accountId);
    }

    if (categoryId != null) {
      whereClause += ' AND ${DbConstants.columnTransactionCategoryId} = ?';
      whereArgs.add(categoryId);
    }

    if (type != null) {
      whereClause += ' AND ${DbConstants.columnTransactionType} = ?';
      whereArgs.add(type);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 更新账单
  Future<int> updateTransaction(model.Transaction transaction) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableTransactions,
      transaction.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [transaction.id],
    );
  }

  /// 更新账单分类
  Future<int> updateTransactionCategory(int transactionId, int categoryId, {bool isConfirmed = true}) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableTransactions,
      {
        DbConstants.columnTransactionCategoryId: categoryId,
        DbConstants.columnTransactionIsConfirmed: isConfirmed ? 1 : 0,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [transactionId],
    );
  }

  /// 批量更新账单分类
  Future<void> updateTransactionsCategoryBatch(
    List<int> transactionIds,
    int categoryId,
  ) async {
    final db = await _dbService.database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var id in transactionIds) {
      batch.update(
        DbConstants.tableTransactions,
        {
          DbConstants.columnTransactionCategoryId: categoryId,
          DbConstants.columnTransactionIsConfirmed: 1,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// 删除账单
  Future<int> deleteTransaction(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 批量删除账单
  Future<void> deleteTransactionsBatch(List<int> ids) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var id in ids) {
      batch.delete(
        DbConstants.tableTransactions,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  /// 搜索账单（按描述）
  Future<List<model.Transaction>> searchTransactions(String keyword) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '${DbConstants.columnTransactionDescription} LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 获取账单统计（指定时间范围）
  Future<Map<String, dynamic>> getTransactionStatistics({
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    int? categoryId,
  }) async {
    final db = await _dbService.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND ${DbConstants.columnTransactionTime} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND ${DbConstants.columnTransactionTime} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (accountId != null) {
      whereClause += ' AND ${DbConstants.columnTransactionAccountId} = ?';
      whereArgs.add(accountId);
    }

    if (categoryId != null) {
      whereClause += ' AND ${DbConstants.columnTransactionCategoryId} = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'income' THEN 1 ELSE 0 END) as income_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'expense' THEN 1 ELSE 0 END) as expense_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'income' THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_income,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'expense' THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_expense
      FROM ${DbConstants.tableTransactions}
      WHERE $whereClause
    ''', whereArgs);

    if (result.isEmpty) {
      return {
        'total_count': 0,
        'income_count': 0,
        'expense_count': 0,
        'total_income': 0.0,
        'total_expense': 0.0,
        'balance': 0.0,
      };
    }

    final data = result.first;
    final totalIncome = (data['total_income'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (data['total_expense'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_count': data['total_count'] ?? 0,
      'income_count': data['income_count'] ?? 0,
      'expense_count': data['expense_count'] ?? 0,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  /// 获取分类支出排行
  Future<List<Map<String, dynamic>>> getCategoryExpenseRanking({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    final db = await _dbService.database;

    String whereClause = 't.${DbConstants.columnTransactionType} = \'expense\'';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND t.${DbConstants.columnTransactionTime} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND t.${DbConstants.columnTransactionTime} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.rawQuery('''
      SELECT
        c.${DbConstants.columnId} as category_id,
        c.${DbConstants.columnCategoryName} as category_name,
        c.${DbConstants.columnCategoryIcon} as category_icon,
        c.${DbConstants.columnCategoryColor} as category_color,
        COUNT(t.${DbConstants.columnId}) as transaction_count,
        SUM(t.${DbConstants.columnTransactionAmount}) as total_amount
      FROM ${DbConstants.tableTransactions} t
      INNER JOIN ${DbConstants.tableCategories} c
        ON t.${DbConstants.columnTransactionCategoryId} = c.${DbConstants.columnId}
      WHERE $whereClause
      GROUP BY c.${DbConstants.columnId}
      ORDER BY total_amount DESC
      LIMIT ?
    ''', [...whereArgs, limit]);

    return result;
  }

  /// 获取账单趋势（按月统计）
  Future<List<Map<String, dynamic>>> getMonthlyTrend({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    final db = await _dbService.database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += ' AND ${DbConstants.columnTransactionTime} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      whereClause += ' AND ${DbConstants.columnTransactionTime} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    if (type != null) {
      whereClause += ' AND ${DbConstants.columnTransactionType} = ?';
      whereArgs.add(type);
    }

    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', datetime(${DbConstants.columnTransactionTime} / 1000, 'unixepoch')) as month,
        COUNT(*) as count,
        SUM(${DbConstants.columnTransactionAmount}) as total_amount
      FROM ${DbConstants.tableTransactions}
      WHERE $whereClause
      GROUP BY month
      ORDER BY month ASC
    ''', whereArgs);

    return result;
  }
}
