import 'package:sqflite/sqflite.dart';
import '../../models/counterparty_group.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';
import '../../utils/app_logger.dart';

/// 对手方分组数据库服务
/// 负责对手方分组的CRUD操作
class CounterpartyGroupDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建分组
  Future<int> createGroup(CounterpartyGroup group) async {
    final db = await _dbService.database;

    try {
      final id = await db.insert(
        DbConstants.tableCounterpartyGroups,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      AppLogger.d('[CounterpartyGroupDbService] 创建分组成功: ${group.mainCounterparty} -> ${group.subCounterparty}');
      return id;
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 创建分组失败', error: e);
      rethrow;
    }
  }

  /// 批量创建分组
  Future<void> batchCreateGroups(List<CounterpartyGroup> groups) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var group in groups) {
      batch.insert(
        DbConstants.tableCounterpartyGroups,
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    try {
      await batch.commit(noResult: true);
      AppLogger.d('[CounterpartyGroupDbService] 批量创建 ${groups.length} 个分组成功');
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 批量创建分组失败', error: e);
      rethrow;
    }
  }

  /// 获取所有分组
  Future<List<CounterpartyGroup>> getAllGroups() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCounterpartyGroups,
      orderBy: '${DbConstants.columnCounterpartyGroupMainCounterparty} ASC, ${DbConstants.columnCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return CounterpartyGroup.fromMap(maps[i]);
    });
  }

  /// 根据主对手方获取所有子对手方
  Future<List<String>> getSubCounterparties(String mainCounterparty) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCounterpartyGroups,
      columns: [DbConstants.columnCounterpartyGroupSubCounterparty],
      where: '${DbConstants.columnCounterpartyGroupMainCounterparty} = ?',
      whereArgs: [mainCounterparty],
    );

    return maps.map((m) => m[DbConstants.columnCounterpartyGroupSubCounterparty] as String).toList();
  }

  /// 根据子对手方查找主对手方
  Future<String?> getMainCounterparty(String subCounterparty) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCounterpartyGroups,
      columns: [DbConstants.columnCounterpartyGroupMainCounterparty],
      where: '${DbConstants.columnCounterpartyGroupSubCounterparty} = ?',
      whereArgs: [subCounterparty],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first[DbConstants.columnCounterpartyGroupMainCounterparty] as String;
  }

  /// 根据主对手方获取所有分组记录
  Future<List<CounterpartyGroup>> getGroupsByMainCounterparty(String mainCounterparty) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableCounterpartyGroups,
      where: '${DbConstants.columnCounterpartyGroupMainCounterparty} = ?',
      whereArgs: [mainCounterparty],
      orderBy: '${DbConstants.columnCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return CounterpartyGroup.fromMap(maps[i]);
    });
  }

  /// 更新分组
  Future<int> updateGroup(CounterpartyGroup group) async {
    final db = await _dbService.database;

    try {
      final count = await db.update(
        DbConstants.tableCounterpartyGroups,
        group.toMap(),
        where: '${DbConstants.columnId} = ?',
        whereArgs: [group.id],
      );
      AppLogger.d('[CounterpartyGroupDbService] 更新分组成功: ID=${group.id}');
      return count;
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 更新分组失败', error: e);
      rethrow;
    }
  }

  /// 删除分组
  Future<int> deleteGroup(int id) async {
    final db = await _dbService.database;

    try {
      final count = await db.delete(
        DbConstants.tableCounterpartyGroups,
        where: '${DbConstants.columnId} = ?',
        whereArgs: [id],
      );
      AppLogger.d('[CounterpartyGroupDbService] 删除分组成功: ID=$id');
      return count;
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 删除分组失败', error: e);
      rethrow;
    }
  }

  /// 删除主对手方的所有分组
  Future<int> deleteGroupsByMainCounterparty(String mainCounterparty) async {
    final db = await _dbService.database;

    try {
      final count = await db.delete(
        DbConstants.tableCounterpartyGroups,
        where: '${DbConstants.columnCounterpartyGroupMainCounterparty} = ?',
        whereArgs: [mainCounterparty],
      );
      AppLogger.d('[CounterpartyGroupDbService] 删除主对手方所有分组: $mainCounterparty, 共 $count 条');
      return count;
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 删除主对手方分组失败', error: e);
      rethrow;
    }
  }

  /// 解除子对手方的分组关联
  Future<int> removeSubFromGroup(String subCounterparty) async {
    final db = await _dbService.database;

    try {
      final count = await db.delete(
        DbConstants.tableCounterpartyGroups,
        where: '${DbConstants.columnCounterpartyGroupSubCounterparty} = ?',
        whereArgs: [subCounterparty],
      );
      AppLogger.d('[CounterpartyGroupDbService] 解除子对手方分组: $subCounterparty');
      return count;
    } catch (e) {
      AppLogger.e('[CounterpartyGroupDbService] 解除分组失败', error: e);
      rethrow;
    }
  }

  /// 获取所有主对手方列表（去重）
  Future<List<String>> getAllMainCounterparties() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT ${DbConstants.columnCounterpartyGroupMainCounterparty} as main_counterparty
      FROM ${DbConstants.tableCounterpartyGroups}
      ORDER BY main_counterparty ASC
    ''');

    return maps.map((m) => m['main_counterparty'] as String).toList();
  }

  /// 检查子对手方是否已分组
  Future<bool> isSubCounterpartyGrouped(String subCounterparty) async {
    final db = await _dbService.database;

    final count = Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM ${DbConstants.tableCounterpartyGroups}
      WHERE ${DbConstants.columnCounterpartyGroupSubCounterparty} = ?
    ''', [subCounterparty]));

    return (count ?? 0) > 0;
  }

  /// 获取分组统计信息
  /// 返回每个主对手方的子对手方数量
  Future<Map<String, int>> getGroupStatistics() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        ${DbConstants.columnCounterpartyGroupMainCounterparty} as main_counterparty,
        COUNT(*) as sub_count
      FROM ${DbConstants.tableCounterpartyGroups}
      GROUP BY ${DbConstants.columnCounterpartyGroupMainCounterparty}
    ''');

    final Map<String, int> statistics = {};
    for (var map in maps) {
      statistics[map['main_counterparty'] as String] = map['sub_count'] as int;
    }

    return statistics;
  }
}
