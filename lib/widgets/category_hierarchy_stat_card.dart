import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_stat_node.dart';
import '../providers/transaction_provider.dart';
import 'category_stat_node_widget.dart';

/// 分类层级统计卡片
/// 显示分类树形统计，支持收入/支出切换
class CategoryHierarchyStatCard extends StatefulWidget {
  const CategoryHierarchyStatCard({super.key});

  @override
  State<CategoryHierarchyStatCard> createState() => _CategoryHierarchyStatCardState();
}

class _CategoryHierarchyStatCardState extends State<CategoryHierarchyStatCard> {
  String _selectedType = 'expense'; // income/expense

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // 监听筛选条件变化，自动重新加载
        return Card(
          margin: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏和类型切换
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '分类统计',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 类型切换按钮
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          _buildTypeButton('支出', 'expense'),
                          _buildTypeButton('收入', 'income'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // 内容区域 - 使用 FutureBuilder 实时加载
              FutureBuilder<List<CategoryStatNode>>(
                key: ValueKey('${transactionProvider.filterAccountId}_${transactionProvider.filterStartDate}_${transactionProvider.filterEndDate}_$_selectedType'),
                future: transactionProvider.getCategoryHierarchyStats(type: _selectedType),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              '加载失败: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {}); // 触发重建
                              },
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final statNodes = snapshot.data;
                  if (statNodes == null || statNodes.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '暂无数据',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return _buildStatTree(statNodes);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        if (_selectedType != type) {
          setState(() {
            _selectedType = type;
          });
          // FutureBuilder 会自动重新加载
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildStatTree(List<CategoryStatNode> statNodes) {
    // 计算总金额
    final totalAmount = statNodes.fold<double>(
      0,
      (sum, node) => sum + node.amount,
    );

    return Column(
      children: statNodes.map((node) {
        return CategoryStatNodeWidget(
          key: ValueKey(node.category.id),
          node: node,
          level: 0,
          totalAmount: totalAmount,
          onUpdate: () {
            // 触发父组件重建，重新加载统计数据
            setState(() {});
          },
        );
      }).toList(),
    );
  }
}
