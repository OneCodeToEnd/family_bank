import 'package:flutter/material.dart';
import '../../../providers/home_provider.dart';
import 'stat_card.dart';
import 'budget_progress_card.dart';

/// 统计区域组件
class StatisticsSection extends StatelessWidget {
  final HomeStatistics? statistics;
  final bool isLoading;

  const StatisticsSection({
    super.key,
    required this.statistics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (statistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无统计数据')),
        ),
      );
    }

    final stats = statistics!.transactionStats;
    final yearIncome = stats['year_income'] as double? ?? 0.0;
    final yearExpense = stats['year_expense'] as double? ?? 0.0;
    final monthIncome = stats['month_income'] as double? ?? 0.0;
    final monthExpense = stats['month_expense'] as double? ?? 0.0;

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final monthStart = DateTime(now.year, now.month, 1);

    return Column(
      children: [
        // 第一行：当年收入和支出
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '当年总收入',
                value: '¥${yearIncome.toStringAsFixed(2)}',
                subtitle: '${now.year}年至今',
                icon: Icons.trending_up,
                color: Colors.green,
                filterType: 'income',
                filterStartDate: yearStart,
                filterEndDate: now,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '当年总支出',
                value: '¥${yearExpense.toStringAsFixed(2)}',
                subtitle: '${now.year}年至今',
                icon: Icons.trending_down,
                color: Colors.red,
                filterType: 'expense',
                filterStartDate: yearStart,
                filterEndDate: now,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第二行：当月收入和支出
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: '当月收入',
                value: '¥${monthIncome.toStringAsFixed(2)}',
                subtitle: '本月至今',
                icon: Icons.arrow_upward,
                color: Colors.green,
                filterType: 'income',
                filterStartDate: monthStart,
                filterEndDate: now,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: '当月支出',
                value: '¥${monthExpense.toStringAsFixed(2)}',
                subtitle: '本月至今',
                icon: Icons.arrow_downward,
                color: Colors.red,
                filterType: 'expense',
                filterStartDate: monthStart,
                filterEndDate: now,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第三行：当年预算进度
        Row(
          children: [
            Expanded(
              child: BudgetProgressCard(
                title: '当年收入预算',
                budgetData: statistics!.yearlyIncomeBudget,
                type: 'income',
                isYearly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BudgetProgressCard(
                title: '当年支出预算',
                budgetData: statistics!.yearlyExpenseBudget,
                type: 'expense',
                isYearly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第四行：当月预算进度
        Row(
          children: [
            Expanded(
              child: BudgetProgressCard(
                title: '当月收入预算',
                budgetData: statistics!.monthlyIncomeBudget,
                type: 'income',
                isYearly: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BudgetProgressCard(
                title: '当月支出预算',
                budgetData: statistics!.monthlyExpenseBudget,
                type: 'expense',
                isYearly: false,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
