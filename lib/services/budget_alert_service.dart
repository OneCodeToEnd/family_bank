import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database/annual_budget_db_service.dart';

/// 预算提醒服务
class BudgetAlertService {
  final AnnualBudgetDbService _budgetDbService = AnnualBudgetDbService();

  /// 检查预算状态并显示提醒
  Future<void> checkBudgetAlerts(
    BuildContext context,
    int familyId,
    int year,
    int month,
  ) async {
    try {
      // 获取所有月度统计
      final stats = await _budgetDbService.getAllMonthlyStats(familyId, year, month);

      // 检查 context 是否仍然有效
      if (!context.mounted) {
        return;
      }

      for (var stat in stats) {
        final usagePercentage = stat['usage_percentage'] as double;
        final categoryId = stat['category_id'] as int;
        final categoryName = stat['category_name'] as String;

        // 检查是否需要提醒
        if (usagePercentage >= 100) {
          await _showAlertIfNeeded(
            context,
            categoryId,
            categoryName,
            usagePercentage,
            AlertType.overspent,
            year,
            month,
          );
        } else if (usagePercentage >= 80) {
          await _showAlertIfNeeded(
            context,
            categoryId,
            categoryName,
            usagePercentage,
            AlertType.warning,
            year,
            month,
          );
        }
      }
    } catch (e) {
      debugPrint('检查预算提醒失败: $e');
    }
  }

  /// 显示提醒（如果本月还未显示过）
  Future<void> _showAlertIfNeeded(
    BuildContext context,
    int categoryId,
    String categoryName,
    double usagePercentage,
    AlertType type,
    int year,
    int month,
  ) async {
    final key = 'budget_alert_${categoryId}_${year}_${month}_${type.name}';
    final prefs = await SharedPreferences.getInstance();

    // 检查是否已经显示过
    final hasShown = prefs.getBool(key) ?? false;
    if (hasShown) {
      return;
    }

    // 检查 context 是否仍然有效
    if (!context.mounted) {
      return;
    }

    // 显示提醒对话框
    await _showAlertDialog(context, categoryName, usagePercentage, type);

    // 标记为已显示
    await prefs.setBool(key, true);
  }

  /// 显示提醒对话框
  Future<void> _showAlertDialog(
    BuildContext context,
    String categoryName,
    double usagePercentage,
    AlertType type,
  ) async {
    final title = type == AlertType.overspent ? '预算超支提醒' : '预算预警';
    final message = type == AlertType.overspent
        ? '「$categoryName」本月预算已超支 ${(usagePercentage - 100).toStringAsFixed(1)}%'
        : '「$categoryName」本月预算已使用 ${usagePercentage.toStringAsFixed(1)}%';

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              type == AlertType.overspent ? Icons.warning : Icons.info,
              color: type == AlertType.overspent ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 清除本月的提醒记录（用于测试或月初重置）
  Future<void> clearMonthlyAlerts(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final pattern = '_${year}_${month}_';

    for (var key in keys) {
      if (key.contains(pattern)) {
        await prefs.remove(key);
      }
    }
  }
}

/// 提醒类型
enum AlertType {
  warning, // 80% 预警
  overspent, // 100% 超支
}
