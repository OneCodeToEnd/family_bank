import 'package:sqflite/sqflite.dart';
import '../../models/http_log.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// HTTP 日志数据库操作服务
class HttpLogDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 创建日志记录
  Future<int> createLog(HttpLog log) async {
    final db = await _dbService.database;
    return await db.insert(
      DbConstants.tableHttpLogs,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新日志记录（用于请求完成后更新响应信息）
  Future<int> updateLog(HttpLog log) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableHttpLogs,
      log.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [log.id],
    );
  }

  /// 根据 request_id 查询
  Future<HttpLog?> getLogByRequestId(String requestId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableHttpLogs,
      where: '${DbConstants.columnLogRequestId} = ?',
      whereArgs: [requestId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return HttpLog.fromMap(maps.first);
  }

  /// 查询最近的日志（用于调试）
  Future<List<HttpLog>> getRecentLogs({int limit = 100}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableHttpLogs,
      orderBy: '${DbConstants.columnCreatedAt} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return HttpLog.fromMap(maps[i]);
    });
  }

  /// 根据服务名查询
  Future<List<HttpLog>> getLogsByService(String serviceName, {int limit = 100}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableHttpLogs,
      where: '${DbConstants.columnLogServiceName} = ?',
      whereArgs: [serviceName],
      orderBy: '${DbConstants.columnCreatedAt} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return HttpLog.fromMap(maps[i]);
    });
  }

  /// 查询失败的请求
  Future<List<HttpLog>> getFailedLogs({int limit = 100}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableHttpLogs,
      where: '${DbConstants.columnLogErrorType} IS NOT NULL OR ${DbConstants.columnLogStatusCode} >= 400',
      orderBy: '${DbConstants.columnCreatedAt} DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return HttpLog.fromMap(maps[i]);
    });
  }

  /// 删除指定日期之前的日志（手动清理）
  Future<int> deleteLogsBefore(DateTime date) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableHttpLogs,
      where: '${DbConstants.columnCreatedAt} < ?',
      whereArgs: [date.millisecondsSinceEpoch],
    );
  }

  /// 清空所有日志
  Future<int> deleteAllLogs() async {
    final db = await _dbService.database;
    return await db.delete(DbConstants.tableHttpLogs);
  }

  /// 统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await _dbService.database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) as total_count,
        SUM(CASE WHEN ${DbConstants.columnLogStatusCode} >= 200 AND ${DbConstants.columnLogStatusCode} < 300 THEN 1 ELSE 0 END) as success_count,
        SUM(CASE WHEN ${DbConstants.columnLogStatusCode} >= 400 OR ${DbConstants.columnLogErrorType} IS NOT NULL THEN 1 ELSE 0 END) as error_count,
        AVG(${DbConstants.columnLogDurationMs}) as avg_duration_ms,
        MAX(${DbConstants.columnLogDurationMs}) as max_duration_ms,
        MIN(${DbConstants.columnLogDurationMs}) as min_duration_ms,
        SUM(${DbConstants.columnLogRequestSize}) as total_request_size,
        SUM(${DbConstants.columnLogResponseSize}) as total_response_size
      FROM ${DbConstants.tableHttpLogs}
    ''');

    if (result.isEmpty) {
      return {
        'total_count': 0,
        'success_count': 0,
        'error_count': 0,
        'avg_duration_ms': 0.0,
        'max_duration_ms': 0,
        'min_duration_ms': 0,
        'total_request_size': 0,
        'total_response_size': 0,
      };
    }

    final data = result.first;
    return {
      'total_count': data['total_count'] ?? 0,
      'success_count': data['success_count'] ?? 0,
      'error_count': data['error_count'] ?? 0,
      'avg_duration_ms': (data['avg_duration_ms'] as num?)?.toDouble() ?? 0.0,
      'max_duration_ms': data['max_duration_ms'] ?? 0,
      'min_duration_ms': data['min_duration_ms'] ?? 0,
      'total_request_size': data['total_request_size'] ?? 0,
      'total_response_size': data['total_response_size'] ?? 0,
    };
  }
}
