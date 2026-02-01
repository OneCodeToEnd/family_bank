import '../database/database_service.dart';
import '../../constants/db_constants.dart';
import '../../utils/app_logger.dart';

/// 引导流程状态管理服务
class OnboardingService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingVersion = 'onboarding_version';
  static const int _currentOnboardingVersion = 1;

  final DatabaseService _dbService = DatabaseService();

  /// 检查是否已完成引导
  Future<bool> isOnboardingCompleted() async {
    try {
      AppLogger.d('[OnboardingService] 检查引导完成状态');
      final db = await _dbService.database;

      // 查询完成状态
      final completedResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyOnboardingCompleted],
      );

      final completed = completedResult.isNotEmpty &&
          completedResult.first[DbConstants.columnSettingValue] == '1';

      AppLogger.d('[OnboardingService] 引导完成标记: $completed');

      if (!completed) {
        AppLogger.i('[OnboardingService] 引导未完成，需要显示引导页面');
        return false;
      }

      // 查询版本
      final versionResult = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_keyOnboardingVersion],
      );

      final version = versionResult.isNotEmpty
          ? int.tryParse(versionResult.first[DbConstants.columnSettingValue] as String? ?? '0') ?? 0
          : 0;

      AppLogger.d('[OnboardingService] 引导版本: $version (当前版本: $_currentOnboardingVersion)');

      // 如果引导版本更新，需要重新引导
      final needsUpdate = version < _currentOnboardingVersion;
      if (needsUpdate) {
        AppLogger.i('[OnboardingService] 引导版本过旧，需要重新引导');
      } else {
        AppLogger.i('[OnboardingService] ✅ 引导已完成且版本最新');
      }

      return completed && !needsUpdate;
    } catch (e, stackTrace) {
      // 如果查询失败，默认返回 false（需要引导）
      AppLogger.e('[OnboardingService] 检查引导状态失败，默认需要引导', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 标记引导已完成
  Future<void> markOnboardingCompleted() async {
    AppLogger.i('[OnboardingService] 标记引导已完成');

    final db = await _dbService.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 保存完成状态
    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [_keyOnboardingCompleted, '1', now]);

    AppLogger.d('[OnboardingService] 保存完成状态: onboarding_completed = 1');

    // 保存版本
    await db.rawInsert('''
      INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
        (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
      VALUES (?, ?, ?)
    ''', [_keyOnboardingVersion, _currentOnboardingVersion.toString(), now]);

    AppLogger.d('[OnboardingService] 保存引导版本: $_currentOnboardingVersion');
    AppLogger.i('[OnboardingService] ✅ 引导状态已保存');
  }

  /// 重置引导状态（用于测试或重新查看引导）
  Future<void> resetOnboarding() async {
    AppLogger.i('[OnboardingService] 重置引导状态');

    final db = await _dbService.database;

    await db.delete(
      DbConstants.tableAppSettings,
      where: '${DbConstants.columnSettingKey} IN (?, ?)',
      whereArgs: [_keyOnboardingCompleted, _keyOnboardingVersion],
    );

    AppLogger.i('[OnboardingService] ✅ 引导状态已重置');
  }
}
