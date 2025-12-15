import 'package:sqflite/sqflite.dart';
import '../../models/account.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 账户数据库操作服务
class AccountDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建账户
  Future<int> createAccount(Account account) async {
    final db = await _dbService.database;
    return await db.insert(
      DbConstants.tableAccounts,
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有账户
  Future<List<Account>> getAllAccounts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAccounts,
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  /// 获取所有未隐藏的账户
  Future<List<Account>> getVisibleAccounts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAccounts,
      where: '${DbConstants.columnAccountIsHidden} = ?',
      whereArgs: [0],
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  /// 根据ID获取账户
  Future<Account?> getAccountById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAccounts,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  /// 根据成员ID获取账户列表
  Future<List<Account>> getAccountsByMemberId(int memberId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAccounts,
      where: '${DbConstants.columnAccountMemberId} = ?',
      whereArgs: [memberId],
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  /// 根据账户类型获取账户列表
  Future<List<Account>> getAccountsByType(String type) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableAccounts,
      where: '${DbConstants.columnAccountType} = ?',
      whereArgs: [type],
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  /// 更新账户
  Future<int> updateAccount(Account account) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableAccounts,
      account.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [account.id],
    );
  }

  /// 删除账户（级联删除所有账单）
  Future<int> deleteAccount(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableAccounts,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 切换账户隐藏状态
  Future<int> toggleAccountVisibility(int id, bool isHidden) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableAccounts,
      {
        DbConstants.columnAccountIsHidden: isHidden ? 1 : 0,
        DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 获取成员的账户数量
  Future<int> getAccountCountByMemberId(int memberId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableAccounts} WHERE ${DbConstants.columnAccountMemberId} = ?',
      [memberId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 检查账户名称是否已存在（同一成员下）
  Future<bool> isAccountNameExists(int memberId, String name, {int? excludeId}) async {
    final db = await _dbService.database;
    String whereClause = '${DbConstants.columnAccountMemberId} = ? AND ${DbConstants.columnAccountName} = ?';
    List<dynamic> whereArgs = [memberId, name];

    if (excludeId != null) {
      whereClause += ' AND ${DbConstants.columnId} != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      DbConstants.tableAccounts,
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// 批量创建账户
  Future<List<int>> createAccountsBatch(List<Account> accounts) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var account in accounts) {
      batch.insert(
        DbConstants.tableAccounts,
        account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }

  /// 获取家庭组的所有账户（通过成员关联）
  Future<List<Map<String, dynamic>>> getAccountsWithMemberInfo(int familyGroupId) async {
    final db = await _dbService.database;

    // 联表查询：账户 JOIN 家庭成员
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT
        a.*,
        m.${DbConstants.columnMemberName} as member_name,
        m.${DbConstants.columnMemberRole} as member_role
      FROM ${DbConstants.tableAccounts} a
      INNER JOIN ${DbConstants.tableFamilyMembers} m
        ON a.${DbConstants.columnAccountMemberId} = m.${DbConstants.columnId}
      WHERE m.${DbConstants.columnMemberFamilyGroupId} = ?
      ORDER BY a.${DbConstants.columnCreatedAt} ASC
    ''', [familyGroupId]);

    return results;
  }

  /// 获取账户统计信息
  Future<Map<String, dynamic>> getAccountStatistics(int accountId) async {
    final db = await _dbService.database;

    // 统计该账户的交易数量和总金额
    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as transaction_count,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'income' THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_income,
        SUM(CASE WHEN ${DbConstants.columnTransactionType} = 'expense' THEN ${DbConstants.columnTransactionAmount} ELSE 0 END) as total_expense
      FROM ${DbConstants.tableTransactions}
      WHERE ${DbConstants.columnTransactionAccountId} = ?
    ''', [accountId]);

    if (result.isEmpty) {
      return {
        'transaction_count': 0,
        'total_income': 0.0,
        'total_expense': 0.0,
        'balance': 0.0,
      };
    }

    final data = result.first;
    final totalIncome = (data['total_income'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (data['total_expense'] as num?)?.toDouble() ?? 0.0;

    return {
      'transaction_count': data['transaction_count'] ?? 0,
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }
}
