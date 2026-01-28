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
      'successCount': successCount,
      'duplicateCount': duplicateCount,
      'duplicateHashes': duplicateHashes,
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
    String? counterparty,
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

    if (counterparty != null && counterparty.isNotEmpty) {
      whereClause += ' AND ${DbConstants.columnTransactionCounterparty} = ?';
      whereArgs.add(counterparty);
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

  /// 获取首页统计数据（当年和当月）
  Future<Map<String, dynamic>> getHomePageStatistics() async {
    final db = await _dbService.database;
    final now = DateTime.now();

    // 当年开始时间（1月1日 00:00:00）
    final yearStart = DateTime(now.year, 1, 1).millisecondsSinceEpoch;

    // 当月开始时间（本月1日 00:00:00）
    final monthStart = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

    // 当前时间
    final currentTime = now.millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT
        -- 全部数据统计
        COUNT(*) as total_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'income' THEN 1 ELSE 0 END) as income_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'expense' THEN 1 ELSE 0 END) as expense_count,

        -- 当年统计（1月1日至今）
        SUM(CASE
          WHEN ${DbConstants.columnTransactionType} = 'income'
            AND ${DbConstants.columnTransactionTime} >= ?
            AND ${DbConstants.columnTransactionTime} <= ?
          THEN ${DbConstants.columnTransactionAmount}
          ELSE 0
        END) as year_income,
        SUM(CASE
          WHEN ${DbConstants.columnTransactionType} = 'expense'
            AND ${DbConstants.columnTransactionTime} >= ?
            AND ${DbConstants.columnTransactionTime} <= ?
          THEN ${DbConstants.columnTransactionAmount}
          ELSE 0
        END) as year_expense,

        -- 当月统计（本月1日至今）
        SUM(CASE
          WHEN ${DbConstants.columnTransactionType} = 'income'
            AND ${DbConstants.columnTransactionTime} >= ?
            AND ${DbConstants.columnTransactionTime} <= ?
          THEN ${DbConstants.columnTransactionAmount}
          ELSE 0
        END) as month_income,
        SUM(CASE
          WHEN ${DbConstants.columnTransactionType} = 'expense'
            AND ${DbConstants.columnTransactionTime} >= ?
            AND ${DbConstants.columnTransactionTime} <= ?
          THEN ${DbConstants.columnTransactionAmount}
          ELSE 0
        END) as month_expense

      FROM ${DbConstants.tableTransactions}
    ''', [
      yearStart, currentTime,   // year_income params
      yearStart, currentTime,   // year_expense params
      monthStart, currentTime,  // month_income params
      monthStart, currentTime,  // month_expense params
    ]);

    if (result.isEmpty) {
      return {
        'total_count': 0,
        'income_count': 0,
        'expense_count': 0,
        'year_income': 0.0,
        'year_expense': 0.0,
        'month_income': 0.0,
        'month_expense': 0.0,
      };
    }

    final data = result.first;
    return {
      'total_count': data['total_count'] ?? 0,
      'income_count': data['income_count'] ?? 0,
      'expense_count': data['expense_count'] ?? 0,
      'year_income': (data['year_income'] as num?)?.toDouble() ?? 0.0,
      'year_expense': (data['year_expense'] as num?)?.toDouble() ?? 0.0,
      'month_income': (data['month_income'] as num?)?.toDouble() ?? 0.0,
      'month_expense': (data['month_expense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// 获取分类支出排行
  Future<List<Map<String, dynamic>>> getCategoryExpenseRanking({
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
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

    if (accountId != null) {
      whereClause += ' AND t.${DbConstants.columnTransactionAccountId} = ?';
      whereArgs.add(accountId);
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

  /// 获取历史交易对手方列表（按最近使用排序）
  Future<List<String>> getCounterparties({int limit = 50}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT ${DbConstants.columnTransactionCounterparty} as counterparty,
             MAX(${DbConstants.columnTransactionTime}) as last_used
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionCounterparty} IS NOT NULL
        AND ${DbConstants.columnTransactionCounterparty} != ''
      GROUP BY ${DbConstants.columnTransactionCounterparty}
      ORDER BY last_used DESC
      LIMIT ?
    ''', [limit]);

    return maps.map((m) => m['counterparty'] as String).toList();
  }

  /// 搜索交易对手方（用于自动补全）
  Future<List<String>> searchCounterparties(String keyword) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT ${DbConstants.columnTransactionCounterparty} as counterparty,
             MAX(${DbConstants.columnTransactionTime}) as last_used
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionCounterparty} LIKE ?
      GROUP BY ${DbConstants.columnTransactionCounterparty}
      ORDER BY last_used DESC
      LIMIT 20
    ''', ['%$keyword%']);

    return maps.map((m) => m['counterparty'] as String).toList();
  }

  /// 获取与某对手方的交易统计
  Future<Map<String, dynamic>> getCounterpartyStatistics(
      String counterparty) async {
    final db = await _dbService.database;
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as transaction_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'income'
            THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_income,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'expense'
            THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_expense,
        MIN(${DbConstants.columnTransactionTime}) as first_transaction,
        MAX(${DbConstants.columnTransactionTime}) as last_transaction
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionCounterparty} = ?
    ''', [counterparty]);

    if (result.isEmpty) {
      return {
        'transaction_count': 0,
        'total_income': 0.0,
        'total_expense': 0.0,
      };
    }
    return result.first;
  }

  /// 获取对手方排行（按交易金额）
  Future<List<Map<String, dynamic>>> getCounterpartyRanking({
    required String type,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT
        ${DbConstants.columnTransactionCounterparty} as counterparty,
        COUNT(*) as transaction_count,
        SUM(${DbConstants.columnTransactionAmount}) as total_amount
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionType} = ?
        AND ${DbConstants.columnTransactionCounterparty} IS NOT NULL
        AND ${DbConstants.columnTransactionCounterparty} != ''
      GROUP BY ${DbConstants.columnTransactionCounterparty}
      ORDER BY total_amount DESC
      LIMIT ?
    ''', [type, limit]);
  }

  /// 查找相似交易（用于历史学习匹配）
  Future<List<model.Transaction>> findSimilar({
    required String description,
    required double amount,
    required String type,
    int limit = 10,
  }) async {
    final db = await _dbService.database;

    // 使用简单的LIKE匹配查找相似描述
    // 同时考虑金额范围（±20%）和交易类型
    final amountLower = amount * 0.8;
    final amountUpper = amount * 1.2;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: '''
        ${DbConstants.columnTransactionDescription} LIKE ?
        AND ${DbConstants.columnTransactionType} = ?
        AND ${DbConstants.columnTransactionAmount} BETWEEN ? AND ?
        AND ${DbConstants.columnTransactionCategoryId} IS NOT NULL
        AND ${DbConstants.columnTransactionIsConfirmed} = 1
      ''',
      whereArgs: ['%$description%', type, amountLower, amountUpper],
      orderBy: '${DbConstants.columnTransactionTime} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 获取账户支出汇总排行
  Future<List<Map<String, dynamic>>> getAccountExpenseRanking({
    int? startTime,
    int? endTime,
  }) async {
    final db = await _dbService.database;
    final whereConditions = <String>['t.${DbConstants.columnTransactionType} = ?'];
    final whereArgs = <dynamic>['expense'];

    if (startTime != null) {
      whereConditions.add('t.${DbConstants.columnTransactionTime} >= ?');
      whereArgs.add(startTime);
    }
    if (endTime != null) {
      whereConditions.add('t.${DbConstants.columnTransactionTime} <= ?');
      whereArgs.add(endTime);
    }

    return await db.rawQuery('''
      SELECT
        a.${DbConstants.columnId} as account_id,
        a.${DbConstants.columnAccountName} as account_name,
        a.${DbConstants.columnAccountType} as account_type,
        COUNT(t.${DbConstants.columnId}) as transaction_count,
        SUM(t.${DbConstants.columnTransactionAmount}) as total_amount
      FROM ${DbConstants.tableTransactions} t
      INNER JOIN ${DbConstants.tableAccounts} a ON t.${DbConstants.columnTransactionAccountId} = a.${DbConstants.columnId}
      WHERE ${whereConditions.join(' AND ')}
      GROUP BY a.${DbConstants.columnId}
      ORDER BY total_amount DESC
    ''', whereArgs);
  }

  /// 获取前N大单笔支出
  Future<List<model.Transaction>> getTopExpenses({
    int? startTime,
    int? endTime,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    final whereConditions = <String>['${DbConstants.columnTransactionType} = ?'];
    final whereArgs = <dynamic>['expense'];

    if (startTime != null) {
      whereConditions.add('${DbConstants.columnTransactionTime} >= ?');
      whereArgs.add(startTime);
    }
    if (endTime != null) {
      whereConditions.add('${DbConstants.columnTransactionTime} <= ?');
      whereArgs.add(endTime);
    }

    final maps = await db.query(
      DbConstants.tableTransactions,
      where: whereConditions.join(' AND '),
      whereArgs: whereArgs,
      orderBy: '${DbConstants.columnTransactionAmount} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => model.Transaction.fromMap(maps[i]));
  }

  /// 获取账户收支统计（用于对比图）
  Future<List<Map<String, dynamic>>> getAccountIncomeExpenseStats({
    int? startTime,
    int? endTime,
  }) async {
    final db = await _dbService.database;
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    if (startTime != null) {
      whereConditions.add('t.${DbConstants.columnTransactionTime} >= ?');
      whereArgs.add(startTime);
    }
    if (endTime != null) {
      whereConditions.add('t.${DbConstants.columnTransactionTime} <= ?');
      whereArgs.add(endTime);
    }

    final whereClause = whereConditions.isEmpty ? '' : 'WHERE ${whereConditions.join(' AND ')}';

    return await db.rawQuery('''
      SELECT
        a.${DbConstants.columnId} as account_id,
        a.${DbConstants.columnAccountName} as account_name,
        SUM(CASE WHEN t.${DbConstants.columnTransactionType} = 'income' THEN t.${DbConstants.columnTransactionAmount} ELSE 0 END) as total_income,
        SUM(CASE WHEN t.${DbConstants.columnTransactionType} = 'expense' THEN t.${DbConstants.columnTransactionAmount} ELSE 0 END) as total_expense
      FROM ${DbConstants.tableTransactions} t
      INNER JOIN ${DbConstants.tableAccounts} a ON t.${DbConstants.columnTransactionAccountId} = a.${DbConstants.columnId}
      $whereClause
      GROUP BY a.${DbConstants.columnId}
      ORDER BY total_expense DESC
    ''', whereArgs);
  }

  // ==================== 分类层级统计 ====================

  /// 获取指定分类的所有流水（包括子分类）
  Future<List<model.Transaction>> getTransactionsByCategoryHierarchy(
    int categoryId, {
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
    bool includeChildren = true,
  }) async {
    final db = await _dbService.database;

    // 获取所有相关的分类ID
    List<int> categoryIds = [categoryId];
    if (includeChildren) {
      final descendantIds = await _getCategoryDescendantIds(categoryId);
      categoryIds.addAll(descendantIds);
    }

    // 构建查询条件
    String whereClause = '${DbConstants.columnTransactionCategoryId} IN (${categoryIds.join(',')})';
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

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableTransactions,
      where: whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: '${DbConstants.columnTransactionTime} DESC',
    );

    return List.generate(maps.length, (i) {
      return model.Transaction.fromMap(maps[i]);
    });
  }

  /// 获取分类的所有子孙分类ID（递归）
  Future<List<int>> _getCategoryDescendantIds(int categoryId) async {
    final db = await _dbService.database;
    final List<int> descendantIds = [];

    // 获取直接子分类
    final List<Map<String, dynamic>> children = await db.query(
      DbConstants.tableCategories,
      columns: [DbConstants.columnId],
      where: '${DbConstants.columnCategoryParentId} = ?',
      whereArgs: [categoryId],
    );

    for (var child in children) {
      final childId = child[DbConstants.columnId] as int;
      descendantIds.add(childId);

      // 递归获取子分类的子分类
      final grandChildren = await _getCategoryDescendantIds(childId);
      descendantIds.addAll(grandChildren);
    }

    return descendantIds;
  }

  /// 获取分类及其所有子孙分类的交易统计
  Future<Map<String, dynamic>> getCategoryHierarchyStatistics(
    int categoryId, {
    DateTime? startDate,
    DateTime? endDate,
    int? accountId,
  }) async {
    final transactions = await getTransactionsByCategoryHierarchy(
      categoryId,
      startDate: startDate,
      endDate: endDate,
      accountId: accountId,
      includeChildren: true,
    );

    double totalAmount = 0.0;
    for (var transaction in transactions) {
      totalAmount += transaction.amount;
    }

    return {
      'category_id': categoryId,
      'transaction_count': transactions.length,
      'total_amount': totalAmount,
    };
  }
}
