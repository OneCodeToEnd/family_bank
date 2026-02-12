import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_stat_node.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/category_icon_utils.dart';
import 'transaction_item_widget.dart';
import 'transaction_detail_sheet.dart';
import '../screens/budget/annual_budget_form_screen.dart';

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

        // 预算信息（仅一级分类显示）
        if (widget.level == 0 && widget.node.budgetAmount != null)
          _buildBudgetInfo(),

        // 预算进度条（仅一级分类显示）
        if (widget.level == 0 && widget.node.budgetAmount != null)
          _buildBudgetProgress(),

        // 设置预算按钮（一级分类且无预算）
        if (widget.level == 0 && widget.node.budgetAmount == null)
          _buildSetBudgetButton(),

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
      builder: (context) => TransactionDetailSheet(
        transaction: transaction,
        onCategoryUpdated: () {
          // 分类更新后刷新流水列表
          _refreshTransactions();
        },
      ),
    );
  }

  /// 刷新流水列表
  Future<void> _refreshTransactions() async {
    // 清空缓存，强制重新加载
    setState(() {
      _transactions = null;
    });

    // 重新加载该分类的流水
    await _loadTransactions();

    // 触发父组件刷新，更新统计数据
    widget.onUpdate();
  }

  /// 构建预算信息行
  Widget _buildBudgetInfo() {
    final budgetAmount = widget.node.budgetAmount!;
    final remaining = budgetAmount - widget.node.amount;
    final isExceeded = remaining < 0;

    // 根据屏幕宽度调整字体大小
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final fontSize = isSmallScreen ? 11.0 : 12.0;

    // 确定时间范围文案
    String timeRangeText = '月';
    final provider = context.read<TransactionProvider>();
    if (provider.filterStartDate != null && provider.filterEndDate != null) {
      final daysDiff = provider.filterEndDate!.difference(provider.filterStartDate!).inDays + 1;
      if (daysDiff <= 31) {
        timeRangeText = '月';
      } else if (daysDiff <= 92) {
        timeRangeText = '季';
      } else if (daysDiff <= 366) {
        timeRangeText = '年';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '预算 ¥${budgetAmount.toStringAsFixed(0)}/$timeRangeText',
            style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
          ),
          Row(
            children: [
              Text(
                isExceeded
                    ? '超支 ¥${(-remaining).toStringAsFixed(0)}'
                    : '剩余 ¥${remaining.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: fontSize,
                  color: isExceeded ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isExceeded) ...[
                const SizedBox(width: 4),
                const Icon(Icons.warning_amber, size: 14, color: Colors.red),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 构建预算进度条
  Widget _buildBudgetProgress() {
    final percent = widget.node.budgetUsagePercent ?? 0;
    final status = widget.node.budgetStatus ?? BudgetStatus.normal;

    Color progressColor;
    switch (status) {
      case BudgetStatus.normal:
        progressColor = Colors.green;
        break;
      case BudgetStatus.warning:
        progressColor = Colors.orange;
        break;
      case BudgetStatus.exceeded:
        progressColor = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percent / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: progressColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设置预算按钮
  Widget _buildSetBudgetButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 44, right: 16, top: 4, bottom: 4),
      child: TextButton.icon(
        onPressed: () {
          _navigateToBudgetForm();
        },
        icon: Icon(Icons.add_circle_outline, size: 16, color: Colors.grey[600]),
        label: Text(
          '设置预算',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          minimumSize: const Size(0, 32),
        ),
      ),
    );
  }

  /// 导航到预算设置页面
  void _navigateToBudgetForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnualBudgetFormScreen(
          initialCategoryId: widget.node.category.id,
        ),
      ),
    );

    // 如果设置了预算，刷新统计数据
    if (result == true && mounted) {
      widget.onUpdate();
    }
  }
}
