import 'package:sqflite/sqflite.dart';
import '../../models/chat_session.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';

/// 会话数据库服务
class ChatSessionDbService {
  final DatabaseService _dbService = DatabaseService();

  /// 保存会话（upsert）
  Future<void> save(ChatSession session) async {
    final db = await _dbService.database;
    await db.insert(
      DbConstants.tableChatSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有会话（不加载消息内容，仅元数据）
  /// 置顶优先，再按 updatedAt 倒序
  Future<List<ChatSession>> getAll() async {
    final db = await _dbService.database;
    // 使用子查询计算消息数量（通过 JSON 数组长度近似）
    final maps = await db.rawQuery('''
      SELECT id, title, is_pinned, created_at, updated_at,
        json_array_length(messages) as message_count
      FROM ${DbConstants.tableChatSessions}
      ORDER BY ${DbConstants.columnSessionIsPinned} DESC,
               ${DbConstants.columnUpdatedAt} DESC
    ''');
    return maps.map((m) => ChatSession.fromMap(m)).toList();
  }

  /// 获取完整会话（含消息）
  Future<ChatSession?> getById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      DbConstants.tableChatSessions,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ChatSession.fromMap(maps.first, loadMessages: true);
  }

  /// 删除单条会话
  Future<void> delete(String id) async {
    final db = await _dbService.database;
    await db.delete(
      DbConstants.tableChatSessions,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 切换置顶状态
  Future<void> togglePin(String id) async {
    final db = await _dbService.database;
    await db.rawUpdate('''
      UPDATE ${DbConstants.tableChatSessions}
      SET ${DbConstants.columnSessionIsPinned} =
        CASE WHEN ${DbConstants.columnSessionIsPinned} = 1 THEN 0 ELSE 1 END
      WHERE ${DbConstants.columnId} = ?
    ''', [id]);
  }

  /// 清空全部会话
  Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete(DbConstants.tableChatSessions);
  }
}
