import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';

/// 流水详情弹窗
/// 显示完整的流水信息
class TransactionDetailSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '流水详情',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 金额（突出显示）
          Center(
            child: Column(
              children: [
                Text(
                  transaction.type == 'income' ? '收入' : '支出',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: transaction.type == 'expense' ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 详细信息
          _buildDetailRow(
            icon: Icons.category,
            label: '分类',
            value: _getCategoryName(context),
          ),
          _buildDetailRow(
            icon: Icons.person_outline,
            label: '交易对手方',
            value: transaction.counterparty ?? '未知',
          ),
          _buildDetailRow(
            icon: Icons.description_outlined,
            label: '描述',
            value: transaction.description ?? '无',
          ),
          _buildDetailRow(
            icon: Icons.access_time,
            label: '交易时间',
            value: DateFormat('yyyy-MM-dd HH:mm:ss').format(transaction.transactionTime),
          ),
          _buildDetailRow(
            icon: Icons.source_outlined,
            label: '来源',
            value: _getImportSourceText(transaction.importSource),
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.note_outlined,
              label: '备注',
              value: transaction.notes!,
            ),
          _buildDetailRow(
            icon: Icons.check_circle_outline,
            label: '状态',
            value: transaction.isConfirmed ? '已确认' : '待确认',
            valueColor: transaction.isConfirmed ? Colors.green : Colors.orange,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(BuildContext context) {
    if (transaction.categoryId == null) {
      return '未分类';
    }

    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.getCategoryById(transaction.categoryId!);
    return category?.name ?? '未知';
  }

  String _getImportSourceText(String source) {
    switch (source) {
      case 'manual':
        return '手动录入';
      case 'alipay':
        return '支付宝导入';
      case 'wechat':
        return '微信导入';
      case 'photo':
        return '照片识别';
      default:
        return source;
    }
  }
}
