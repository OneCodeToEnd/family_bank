import 'dart:convert';
import '../services/database/database_service.dart';
import '../constants/db_constants.dart';
import '../constants/quick_action_constants.dart';
import '../models/quick_action.dart';
import '../utils/app_logger.dart';

/// 快捷操作服务
/// 负责快捷操作配置的数据库存储和读取
class QuickActionService {
  final DatabaseService _dbService = DatabaseService();

  // 存储键
  static const String _settingKey = 'quick_actions';

  /// 从数据库加载快捷操作配置
  /// 返回用户配置的快捷操作列表，如果没有配置则返回默认列表
  Future<List<QuickAction>> loadQuickActions() async {
    try {
      final db = await _dbService.database;

      // 从 app_settings 表查询配置
      final result = await db.query(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_settingKey],
      );

      if (result.isEmpty) {
        // 没有配置，返回默认列表
        return QuickActionConstants.getDefaultActions();
      }

      // 解析 JSON 数组
      final jsonValue = result.first[DbConstants.columnSettingValue] as String;
      AppLogger.d('快捷操作配置 JSON: $jsonValue');
      final List<dynamic> actionIds = jsonDecode(jsonValue);
      AppLogger.d('快捷操作 ID 列表: $actionIds');

      // 根据 ID 列表获取 QuickAction 对象
      final actions = actionIds
          .map((id) => QuickActionConstants.getActionById(id as String))
          .whereType<QuickAction>()
          .toList();
      AppLogger.d('解析后的快捷操作数量: ${actions.length}');

      // 如果解析后的列表为空或数量不足，返回默认列表
      if (actions.isEmpty || actions.length < QuickActionConstants.minActions) {
        AppLogger.w('快捷操作数量不足，返回默认列表');
        return QuickActionConstants.getDefaultActions();
      }

      AppLogger.i('成功加载 ${actions.length} 个快捷操作');
      return actions;
    } catch (e) {
      // 发生错误时返回默认列表
      AppLogger.e('加载快捷操作配置失败', error: e);
      return QuickActionConstants.getDefaultActions();
    }
  }

  /// 保存快捷操作配置到数据库
  /// [actions] 要保存的快捷操作列表
  Future<void> saveQuickActions(List<QuickAction> actions) async {
    try {
      final db = await _dbService.database;

      // 提取 ID 列表
      final actionIds = actions.map((action) => action.id).toList();
      AppLogger.d('保存快捷操作 ID 列表: $actionIds (共 ${actionIds.length} 个)');

      // 转换为 JSON 字符串
      final jsonValue = jsonEncode(actionIds);
      AppLogger.d('保存快捷操作 JSON: $jsonValue');

      // 使用 INSERT OR REPLACE 保存到数据库
      await db.rawInsert('''
        INSERT OR REPLACE INTO ${DbConstants.tableAppSettings}
          (${DbConstants.columnSettingKey}, ${DbConstants.columnSettingValue}, ${DbConstants.columnUpdatedAt})
        VALUES (?, ?, ?)
      ''', [
        _settingKey,
        jsonValue,
        DateTime.now().millisecondsSinceEpoch,
      ]);
      AppLogger.i('快捷操作配置保存成功');
    } catch (e) {
      AppLogger.e('保存快捷操作配置失败', error: e);
      rethrow;
    }
  }

  /// 获取默认快捷操作列表
  List<QuickAction> getDefaultActions() {
    return QuickActionConstants.getDefaultActions();
  }

  /// 删除快捷操作配置（恢复为默认）
  Future<void> deleteQuickActions() async {
    try {
      final db = await _dbService.database;

      await db.delete(
        DbConstants.tableAppSettings,
        where: '${DbConstants.columnSettingKey} = ?',
        whereArgs: [_settingKey],
      );
      AppLogger.i('快捷操作配置已删除');
    } catch (e) {
      AppLogger.e('删除快捷操作配置失败', error: e);
      rethrow;
    }
  }
}
