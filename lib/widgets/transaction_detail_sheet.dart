import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import 'category_selector_dialog.dart';

/// 流水详情弹窗
/// 显示完整的流水信息，支持快速修改分类
class TransactionDetailSheet extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onCategoryUpdated;  // 分类更新后的回调

  const TransactionDetailSheet({
    super.key,
    required this.transaction,
    this.onCategoryUpdated,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  bool _isUpdating = false;

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
                  widget.transaction.type == 'income' ? '收入' : '支出',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '¥${widget.transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: widget.transaction.type == 'expense' ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 详细信息
          _buildCategoryRow(),  // 使用新的分类行（带编辑按钮）
          _buildDetailRow(
            icon: Icons.person_outline,
            label: '交易对手方',
            value: widget.transaction.counterparty ?? '未知',
          ),
          _buildDetailRow(
            icon: Icons.description_outlined,
            label: '描述',
            value: widget.transaction.description ?? '无',
          ),
          _buildDetailRow(
            icon: Icons.access_time,
            label: '交易时间',
            value: DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.transaction.transactionTime),
          ),
          _buildDetailRow(
            icon: Icons.source_outlined,
            label: '来源',
            value: _getImportSourceText(widget.transaction.importSource),
          ),
          if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
            _buildDetailRow(
              icon: Icons.note_outlined,
              label: '备注',
              value: widget.transaction.notes!,
            ),
          _buildDetailRow(
            icon: Icons.check_circle_outline,
            label: '状态',
            value: widget.transaction.isConfirmed ? '已确认' : '待确认',
            valueColor: widget.transaction.isConfirmed ? Colors.green : Colors.orange,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 分类行（带编辑按钮）
  Widget _buildCategoryRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.category, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              '分类',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              _getCategoryName(context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // 编辑按钮
          if (!_isUpdating)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: _showCategorySelector,
              tooltip: '修改分类',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
    if (widget.transaction.categoryId == null) {
      return '未分类';
    }

    final categoryProvider = context.read<CategoryProvider>();
    final category = categoryProvider.getCategoryById(widget.transaction.categoryId!);
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

  /// 显示分类选择对话框
  Future<void> _showCategorySelector() async {
    final selected = await showCategorySelectorDialog(
      context,
      transactionType: widget.transaction.type,
      currentCategoryId: widget.transaction.categoryId,
    );

    // 如果选择了新分类（包括"未分类"）
    if (selected != null || (selected == null && widget.transaction.categoryId != null)) {
      await _updateCategory(selected?.id);
    }
  }

  /// 更新分类
  Future<void> _updateCategory(int? categoryId) async {
    setState(() => _isUpdating = true);

    try {
      final provider = context.read<TransactionProvider>();
      final success = await provider.updateTransactionCategory(
        widget.transaction.id!,
        categoryId ?? 0,  // 0 表示未分类
        isConfirmed: true,
      );

      if (success) {
        // 触发回调，通知父组件刷新
        widget.onCategoryUpdated?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('分类已更新'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // 延迟一下让用户看到成功提示
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('更新失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新分类失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
