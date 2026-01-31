import '../database/database_service.dart';
import '../../constants/db_constants.dart';

/// 引导流程状态管理服务
class OnboardingService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const int _currentOnboardingVersion = 1;

  final DatabaseService _dbService = DatabaseService();

  /// 检查是否已完成引导
  Future<bool> isOnboardingCompleted() async {
    try {
      final db = await _dbService.database;

      // 查询完成状态
      final completedResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyOnboardingCompleted],
      );

      final completed = completedResult.isNotEmpty &&
          completedResult.first[DbConstants.columnSettingValue] == '1';

      if (!completed) return false;

      // 查询版本
      final versionResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyOnboardingVersion],
      );

      final version = versionResult.isNotEmpty
          ? int.tryParse(versionResult.first[DbConstants.columnSettingValue] as String? ?? '0') ?? 0
          : 0;

      // 如果引导版本更新，需要重新引导
      return completed && version >= _currentOnboardingVersion;
    } catch (e) {
      // 如果查询失败，默认返回 false（需要引导）
      return false;
    }
  }

  /// 标记引导已完成
  Future<void> markOnboardingCompleted() async {
    final db = await _dbService.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 保存完成状态
    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [_keyOnboardingCompleted, '1', now]);

    // 保存版本
    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [_keyOnboardingVersion, _currentOnboardingVersion.toString(), now]);
  }

  /// 重置引导状态（用于测试或重新查看引导）
  Future<void> resetOnboarding() async {
    final db = await _dbService.database;

    await db.delete(
      DbConstants.tableAppSettings,
      where: '${DbConstants.columnSettingKey} IN (?, ?)',
      whereArgs: [_keyOnboardingCompleted, _keyOnboardingVersion],
    );
  }
}
