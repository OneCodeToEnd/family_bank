import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';

/// 总览统计卡片
/// 显示收支平衡、总收入、总支出等统计信息
class OverviewCard extends StatelessWidget {
  const OverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();

    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('overview_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getStatistics(),
      builder: (context, snapshot) {
        // 加载状态
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: SizedBox(
              height: 280, // 固定高度，避免抖动
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // 无数据状态
        final stats = snapshot.data;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        // 解析数据
        final totalIncome = stats['total_income'] as double? ?? 0.0;
        final totalExpense = stats['total_expense'] as double? ?? 0.0;
        final balance = stats['balance'] as double? ?? 0.0;
        final incomeCount = stats['income_count'] as int? ?? 0;
        final expenseCount = stats['expense_count'] as int? ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 收支平衡
                _buildBalanceSection(context, balance),
                const SizedBox(height: 16),

                // 收入支出对比
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '总收入',
                        '¥${totalIncome.toStringAsFixed(2)}',
                        '$incomeCount 笔',
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        '总支出',
                        '¥${totalExpense.toStringAsFixed(2)}',
                        '$expenseCount 笔',
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建收支平衡部分
  Widget _buildBalanceSection(BuildContext context, double balance) {
    return Builder(
      builder: (context) {
        final appColors = context.appColors;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: balance >= 0
                  ? [appColors.successColor.withValues(alpha: 0.8), appColors.successColor]
                  : [Theme.of(context).colorScheme.error.withValues(alpha: 0.8), Theme.of(context).colorScheme.error],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                '收支平衡',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '¥${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    String label,
    String amount,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
