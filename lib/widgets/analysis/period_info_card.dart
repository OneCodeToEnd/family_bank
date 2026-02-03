import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';

/// 时间段和账户信息展示卡片
class PeriodInfoCard extends StatelessWidget {
  final String selectedPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final int? selectedAccountId;

  const PeriodInfoCard({
    super.key,
    required this.selectedPeriod,
    this.customStartDate,
    this.customEndDate,
    this.selectedAccountId,
  });

  @override
  Widget build(BuildContext context) {
    String periodText;
    switch (selectedPeriod) {
      case 'month':
        periodText = '本月';
        break;
      case 'quarter':
        periodText = '本季度';
        break;
      case 'year':
        periodText = '本年';
        break;
      case 'custom':
        if (customStartDate != null && customEndDate != null) {
          final start = DateFormat('yyyy/MM/dd').format(customStartDate!);
          final end = DateFormat('yyyy/MM/dd').format(customEndDate!);
          periodText = '$start - $end';
        } else {
          periodText = '自定义';
        }
        break;
      default:
        periodText = '全部';
    }

    // 获取账户名称
    String accountText = '全部账户';
    if (selectedAccountId != null) {
      final accountProvider = context.read<AccountProvider>();
      final account = accountProvider.accounts.firstWhere(
        (a) => a.id == selectedAccountId,
        orElse: () => accountProvider.accounts.first,
      );
      accountText = account.name;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(
                  '统计时间段：$periodText',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(
                  '账户：$accountText',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
