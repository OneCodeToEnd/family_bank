import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/transaction.dart' as model;
import 'transaction_form_screen.dart';

/// 账单详情页面
class TransactionDetailScreen extends StatelessWidget {
  final model.Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '编辑',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TransactionFormScreen(transaction: transaction),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: Consumer4<TransactionProvider, AccountProvider, CategoryProvider, FamilyProvider>(
        builder: (context, transactionProvider, accountProvider, categoryProvider, familyProvider, child) {
          final account = accountProvider.getAccountById(transaction.accountId);
          final category = transaction.categoryId != null
              ? categoryProvider.getCategoryById(transaction.categoryId!)
              : null;
          final member = account != null
              ? familyProvider.getMemberById(account.familyMemberId)
              : null;

          final isIncome = transaction.type == 'income';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 金额卡片
              Card(
                color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 48,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isIncome ? '收入' : '支出',
                        style: TextStyle(
                          fontSize: 16,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 详细信息卡片
              Card(
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.description,
                      label: '描述',
                      value: transaction.description ?? '无描述',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.category,
                      label: '分类',
                      value: category != null
                          ? _getCategoryPath(category, categoryProvider)
                          : '未分类',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.account_balance_wallet,
                      label: '账户',
                      value: account?.name ?? '未知账户',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.person,
                      label: '成员',
                      value: member?.name ?? '未知',
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.calendar_today,
                      label: '日期',
                      value: DateFormat('yyyy年MM月dd日 EEEE')
                          .format(transaction.transactionTime),
                    ),
                    const Divider(height: 1),
                    _buildInfoTile(
                      icon: Icons.access_time,
                      label: '时间',
                      value: DateFormat('HH:mm').format(transaction.transactionTime),
                    ),
                    if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                      const Divider(height: 1),
                      _buildInfoTile(
                        icon: Icons.note,
                        label: '备注',
                        value: transaction.notes!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 元数据卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '元数据',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMetaRow('来源', _getImportSourceText(transaction.importSource)),
                      const SizedBox(height: 8),
                      _buildMetaRow('状态', transaction.isConfirmed ? '已确认' : '待确认'),
                      const SizedBox(height: 8),
                      _buildMetaRow('创建时间', DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)),
                      const SizedBox(height: 8),
                      _buildMetaRow('更新时间', DateFormat('yyyy-MM-dd HH:mm').format(transaction.updatedAt)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// 获取分类路径
  String _getCategoryPath(category, CategoryProvider provider) {
    final path = <String>[];
    var current = category;

    while (current != null) {
      path.insert(0, current.name);
      if (current.parentId != null) {
        current = provider.getCategoryById(current.parentId!);
      } else {
        current = null;
      }
    }

    return path.join(' > ');
  }

  /// 获取导入来源文本
  String _getImportSourceText(String source) {
    switch (source) {
      case 'manual':
        return '手动添加';
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

  /// 确认删除
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条账单吗？此操作无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // 关闭对话框

              final success = await context.read<TransactionProvider>()
                  .deleteTransaction(transaction.id!);

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context); // 返回列表页
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('账单已删除')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('删除失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
