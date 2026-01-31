import 'package:flutter/material.dart';
import '../../../screens/budget/budget_overview_screen.dart';

/// 预算进度卡片组件
class BudgetProgressCard extends StatelessWidget {
  final String title;
  final Map<String, dynamic>? budgetData;
  final String type;
  final bool isYearly;

  const BudgetProgressCard({
    super.key,
    required this.title,
    required this.budgetData,
    required this.type,
    required this.isYearly,
  });

  @override
  Widget build(BuildContext context) {
    final color = type == 'income' ? Colors.green : Colors.red;
    final icon = isYearly
        ? (type == 'income' ? Icons.trending_up : Icons.trending_down)
        : (type == 'income' ? Icons.arrow_upward : Icons.arrow_downward);

    // 检查是否有预算
    final hasBudget = budgetData?['has_budget'] == true;

    if (!hasBudget) {
      // 无预算时显示引导设置
      return Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BudgetOverviewScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '未设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击设置预算',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 有预算时显示进度
    final data = budgetData!;
    final totalBudget = data['total_budget'] as double;
    final totalActual = data['total_actual'] as double;
    final percentage = data['percentage'] as double;

    // 判断是否超预算
    final isOverBudget = totalActual > totalBudget;
    final displayColor = isOverBudget ? Colors.orange : color;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetOverviewScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: displayColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: displayColor,
                    ),
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '¥${totalActual.toStringAsFixed(0)} / ¥${totalBudget.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
