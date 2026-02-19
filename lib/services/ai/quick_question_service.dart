import 'dart:convert';
import '../database/database_service.dart';
import '../../constants/db_constants.dart';

/// 常见问题服务
/// 从 app_settings 表读写智能问答的常见问题列表
class QuickQuestionService {
  final DatabaseService _dbService = DatabaseService();

  static const String _settingKey = 'agent_quick_questions';

  /// 获取常见问题列表
  Future<List<String>> getQuestions() async {
    try {
      final db = await _dbService.database;
      final result = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_settingKey],
      );

      if (result.isEmpty) return [];

      final jsonValue =
          result.first[DbConstants.columnSettingValue] as String;
      final List<dynamic> list = jsonDecode(jsonValue);
      return list.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 保存常见问题列表
  Future<void> saveQuestions(List<String> questions) async {
    final db = await _dbService.database;
    final jsonValue = jsonEncode(questions);
    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [
      _settingKey,
      jsonValue,
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  /// 添加一个常见问题
  Future<void> addQuestion(String question) async {
    final questions = await getQuestions();
    questions.add(question);
    await saveQuestions(questions);
  }

  /// 删除指定索引的常见问题
  Future<void> removeQuestion(int index) async {
    final questions = await getQuestions();
    if (index >= 0 && index < questions.length) {
      questions.removeAt(index);
      await saveQuestions(questions);
    }
  }

  /// 重新排序常见问题
  Future<void> reorderQuestions(int oldIndex, int newIndex) async {
    final questions = await getQuestions();
    if (newIndex > oldIndex) newIndex--;
    final item = questions.removeAt(oldIndex);
    questions.insert(newIndex, item);
    await saveQuestions(questions);
  }
}
