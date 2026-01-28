import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_stat_node.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/category_icon_utils.dart';
import 'transaction_item_widget.dart';
import 'transaction_detail_sheet.dart';

/// 分类统计节点组件
/// 递归渲染分类树，支持展开/收起子分类和流水明细
class CategoryStatNodeWidget extends StatefulWidget {
  final CategoryStatNode node;
  final int level;
  final double totalAmount;
  final VoidCallback onUpdate;

  const CategoryStatNodeWidget({
    super.key,
    required this.node,
    required this.level,
    required this.totalAmount,
    required this.onUpdate,
  });

  @override
  State<CategoryStatNodeWidget> createState() => _CategoryStatNodeWidgetState();
}

class _CategoryStatNodeWidgetState extends State<CategoryStatNodeWidget> {
  bool _isLoadingTransactions = false;
  bool _isExpanded = false; // 在 State 中维护展开状态
  List<Transaction>? _transactions; // 在 State 中维护流水数据

  @override
  Widget build(BuildContext context) {
    final percentage = widget.totalAmount > 0
        ? (widget.node.amount / widget.totalAmount * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类信息行
        _buildCategoryRow(percentage),

        // 子分类列表（如果有且已展开）
        if (_isExpanded && widget.node.children.isNotEmpty)
          ...widget.node.children.map((child) {
            return Padding(
              padding: EdgeInsets.only(left: (widget.level + 1) * 16.0),
              child: CategoryStatNodeWidget(
                key: ValueKey(child.category.id),
                node: child,
                level: widget.level + 1,
                totalAmount: widget.totalAmount,
                onUpdate: widget.onUpdate,
              ),
            );
          }),

        // 流水明细列表（如果是末级分类且已展开）
        if (_isExpanded &&
            widget.node.isLeafNode &&
            _transactions != null)
          _buildTransactionsList(),

        // 加载中提示
        if (_isLoadingTransactions)
          Padding(
            padding: EdgeInsets.only(left: (widget.level + 1) * 16.0),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryRow(double percentage) {
    final hasContent = widget.node.children.isNotEmpty || widget.node.isLeafNode;

    return InkWell(
      onTap: hasContent ? _handleTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.level == 0
              ? Colors.grey.withValues(alpha: 0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 展开/收起图标
            if (hasContent)
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 20,
                color: Colors.grey[600],
              )
            else
              const SizedBox(width: 20),

            const SizedBox(width: 8),

            // 分类图标
            if (widget.node.category.icon != null)
              Icon(
                CategoryIconUtils.getIconData(widget.node.category.icon!),
                size: 18,
                color: CategoryIconUtils.getColor(widget.node.category.color),
              ),

            const SizedBox(width: 8),

            // 分类名称和笔数
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.node.category.name,
                    style: TextStyle(
                      fontSize: widget.level == 0 ? 15 : 14,
                      fontWeight: widget.level == 0
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  if (widget.node.transactionCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${widget.node.transactionCount} 笔 · ${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 金额
            Text(
              '¥${widget.node.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: widget.level == 0 ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: widget.node.category.type == 'expense'
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    final transactions = _transactions!;

    if (transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: (widget.level + 1) * 16.0),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              '暂无流水记录',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: (widget.level + 1) * 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.02),
          border: Border(
            left: BorderSide(
              color: Colors.blue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: transactions.map((transaction) {
            return TransactionItemWidget(
              transaction: transaction,
              onTap: () => _showTransactionDetail(transaction),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    if (widget.node.isLeafNode && !_isExpanded) {
      // 末级分类：加载流水明细
      await _loadTransactions();
    }

    // 切换展开状态
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // 不再调用 widget.onUpdate()，避免触发父组件重建
  }

  Future<void> _loadTransactions() async {
    if (_transactions != null) {
      return; // 已加载过
    }

    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final provider = context.read<TransactionProvider>();
      final transactions = await provider.loadCategoryTransactions(
        widget.node.category.id!,
        includeChildren: false,
      );

      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载流水失败: $e')),
        );
      }
    }
  }

  void _showTransactionDetail(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
  }
}
