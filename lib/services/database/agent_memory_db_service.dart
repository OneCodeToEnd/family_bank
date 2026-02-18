import '../../models/agent_memory.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// Agent 记忆数据库服务
class AgentMemoryDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 保存记忆
  Future<void> save(AgentMemory memory) async {
    final db = await _dbService.database;
    await db.insert(
      DbConstants.tableAgentMemories,
      memory.toMap(),
    );
  }

  /// 获取最近 N 条记忆（用于注入 System Prompt）
  Future<List<AgentMemory>> getRecent({int limit = 20}) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbConstants.tableAgentMemories,
      orderBy: '${DbConstants.columnCreatedAt} DESC',
      limit: limit,
    );
    return maps.map((m) => AgentMemory.fromMap(m)).toList();
  }

  /// 获取所有记忆（管理页面用）
  Future<List<AgentMemory>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbConstants.tableAgentMemories,
      orderBy: '${DbConstants.columnCreatedAt} DESC',
    );
    return maps.map((m) => AgentMemory.fromMap(m)).toList();
  }

  /// 删除单条记忆
  Future<void> delete(int id) async {
    final db = await _dbService.database;
    await db.delete(
      DbConstants.tableAgentMemories,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 清空全部记忆
  Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete(DbConstants.tableAgentMemories);
  }
}
