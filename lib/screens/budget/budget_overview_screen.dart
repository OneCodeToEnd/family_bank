import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import '../../utils/category_icon_utils.dart';
import 'annual_budget_form_screen.dart';

/// 预算管理概览页面
class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  final Set<int> _expandedCategoryIds = {}; // 展开的父分类ID集合
  bool _isExpenseSectionExpanded = true; // 支出预算区域是否展开
  bool _isIncomeSectionExpanded = true; // 收入预算区域是否展开

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final budgetProvider = context.read<BudgetProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    await budgetProvider.loadBudgets();
    await budgetProvider.loadMonthlyStats();
    await categoryProvider.loadCategories();
    // 默认展开所有一级分类
    _expandAllTopLevel();
  }

  /// 展开所有一级分类
  void _expandAllTopLevel() {
    final categoryProvider = context.read<CategoryProvider>();
    for (var category in categoryProvider.visibleCategories) {
      if (category.parentId == null && _hasChildren(category, categoryProvider.visibleCategories)) {
        setState(() {
          _expandedCategoryIds.add(category.id!);
        });
      }
    }
  }

  /// 判断分类是否有子分类
  bool _hasChildren(Category category, List<Category> allCategories) {
    return allCategories.any((c) => c.parentId == category.id);
  }

  /// 获取子分类
  List<Category> _getChildren(Category parent, List<Category> allCategories) {
    return allCategories.where((c) => c.parentId == parent.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预算管理'),
      ),
      body: Consumer2<BudgetProvider, CategoryProvider>(
        builder: (context, budgetProvider, categoryProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (budgetProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('错误: ${budgetProvider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 年份选择器
              _buildYearSelector(budgetProvider),

              // 预算概览卡片
              _buildSummaryCard(budgetProvider),

              // 当月预算执行情况（树形结构）
              Expanded(
                child: _buildBudgetTree(budgetProvider, categoryProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddBudget(),
        icon: const Icon(Icons.add),
        label: const Text('设置年度预算'),
      ),
    );
  }

  /// 年份选择器
  Widget _buildYearSelector(BudgetProvider provider) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => provider.previousYear(),
            ),
            Text(
              '${provider.currentYear}年预算',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => provider.nextYear(),
            ),
          ],
        ),
      ),
    );
  }

  /// 预算概览卡片
  Widget _buildSummaryCard(BudgetProvider provider) {
    final expenseBudgets = provider.expenseBudgets;
    final incomeBudgets = provider.incomeBudgets;
    final totalExpense = expenseBudgets.fold<double>(0, (sum, b) => sum + b.annualAmount);
    final totalIncome = incomeBudgets.fold<double>(0, (sum, b) => sum + b.annualAmount);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              '支出预算',
              '¥${totalExpense.toStringAsFixed(0)}',
              Icons.arrow_upward,
              Colors.red,
            ),
            _buildSummaryItem(
              '收入预算',
              '¥${totalIncome.toStringAsFixed(0)}',
              Icons.arrow_downward,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 构建预算树
  Widget _buildBudgetTree(BudgetProvider budgetProvider, CategoryProvider categoryProvider) {
    final now = DateTime.now();
    final monthlyStats = budgetProvider.monthlyStats;

    if (monthlyStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有设置预算',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddBudget(),
              icon: const Icon(Icons.add),
              label: const Text('设置年度预算'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '当月执行情况 (${now.year}年${now.month}月)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              // 支出预算树
              ..._buildBudgetTypeSection('expense', budgetProvider, categoryProvider),

              // 收入预算树
              ..._buildBudgetTypeSection('income', budgetProvider, categoryProvider),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建预算类型区域（支出或收入）
  List<Widget> _buildBudgetTypeSection(
    String type,
    BudgetProvider budgetProvider,
    CategoryProvider categoryProvider,
  ) {
    final budgets = type == 'expense' ? budgetProvider.expenseBudgets : budgetProvider.incomeBudgets;

    if (budgets.isEmpty) {
      return [];
    }

    // 获取顶级分类：父分类本身有预算，或其子分类有预算
    final topLevelCategories = categoryProvider.visibleCategories
        .where((c) => c.parentId == null && c.type == type)
        .where((c) {
          // 父分类本身有预算
          if (budgets.any((b) => b.categoryId == c.id)) {
            return true;
          }
          // 或者其任意子分类有预算
          final children = _getChildren(c, categoryProvider.visibleCategories);
          return children.any((child) => budgets.any((b) => b.categoryId == child.id));
        })
        .toList();

    if (topLevelCategories.isEmpty) {
      return [];
    }

    return [
      // 类型标题（可折叠）
      InkWell(
        onTap: () {
          setState(() {
            if (type == 'expense') {
              _isExpenseSectionExpanded = !_isExpenseSectionExpanded;
            } else {
              _isIncomeSectionExpanded = !_isIncomeSectionExpanded;
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, type == 'expense' ? 8 : 16, 8, 8),
          child: Row(
            children: [
              Icon(
                (type == 'expense' ? _isExpenseSectionExpanded : _isIncomeSectionExpanded)
                    ? Icons.expand_more
                    : Icons.chevron_right,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 4),
              Icon(
                type == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: type == 'expense' ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                type == 'expense' ? '支出预算' : '收入预算',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
      // 顶级分类及其子分类（根据展开状态显示）
      if (type == 'expense' ? _isExpenseSectionExpanded : _isIncomeSectionExpanded)
        ...topLevelCategories.expand((category) =>
          _buildCategoryBudgetWithChildren(category, 0, budgetProvider, categoryProvider)
        ),
    ];
  }

  /// 递归构建分类预算及其子分类
  List<Widget> _buildCategoryBudgetWithChildren(
    Category category,
    int level,
    BudgetProvider budgetProvider,
    CategoryProvider categoryProvider,
  ) {
    final hasChildren = _hasChildren(category, categoryProvider.visibleCategories);
    final isExpanded = _expandedCategoryIds.contains(category.id);
    final children = hasChildren ? _getChildren(category, categoryProvider.visibleCategories) : <Category>[];

    // 只显示有预算的子分类
    final childrenWithBudget = children.where((c) =>
      budgetProvider.budgets.any((b) => b.categoryId == c.id)
    ).toList();

    return [
      _buildBudgetProgressCard(category, level, childrenWithBudget.isNotEmpty, isExpanded, budgetProvider),
      // 如果展开且有子分类，递归显示子分类
      if (isExpanded && childrenWithBudget.isNotEmpty)
        ...childrenWithBudget.expand((child) =>
          _buildCategoryBudgetWithChildren(child, level + 1, budgetProvider, categoryProvider)
        ),
    ];
  }

  /// 预算进度卡片
  Widget _buildBudgetProgressCard(
    Category category,
    int level,
    bool hasChildren,
    bool isExpanded,
    BudgetProvider budgetProvider,
  ) {
    // 获取该分类的统计数据（可能是直接的，也可能是汇总的）
    final stats = _getCategoryStats(category, budgetProvider);

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final monthlyAmount = stats['monthly_amount'] as double;
    final spentAmount = stats['spent_amount'] as double;
    final usagePercentage = stats['usage_percentage'] as double;
    final isAggregated = stats['is_aggregated'] as bool? ?? false;

    // 确定状态颜色
    Color statusColor;
    if (usagePercentage >= 100) {
      statusColor = Colors.red;
    } else if (usagePercentage >= 80) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    // 解析图标和颜色
    final iconData = CategoryIconUtils.getIconData(category.icon ?? 'category');
    final color = CategoryIconUtils.getColor(category.color);

    return Card(
      margin: EdgeInsets.only(bottom: 8, left: level * 16.0, right: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类名称和图标
            Row(
              children: [
                // 展开/折叠按钮或占位
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategoryIds.remove(category.id);
                        } else {
                          _expandedCategoryIds.add(category.id!);
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(iconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isAggregated) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(汇总)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${usagePercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 金额信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '预算: ¥${monthlyAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  '已用: ¥${spentAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类的统计数据（支持汇总）
  Map<String, dynamic> _getCategoryStats(Category category, BudgetProvider budgetProvider) {
    // 首先尝试获取该分类自己的统计数据
    final directStats = budgetProvider.monthlyStats.firstWhere(
      (s) => s['category_id'] == category.id,
      orElse: () => <String, dynamic>{},
    );

    // 如果该分类本身有预算，直接返回
    if (directStats.isNotEmpty) {
      return {...directStats, 'is_aggregated': false};
    }

    // 否则，尝试汇总子分类的数据
    final children = _getChildren(category, context.read<CategoryProvider>().visibleCategories);
    if (children.isEmpty) {
      return {};
    }

    double totalMonthlyAmount = 0;
    double totalSpentAmount = 0;

    for (final child in children) {
      final childStats = budgetProvider.monthlyStats.firstWhere(
        (s) => s['category_id'] == child.id,
        orElse: () => <String, dynamic>{},
      );

      if (childStats.isNotEmpty) {
        totalMonthlyAmount += (childStats['monthly_amount'] as double? ?? 0);
        totalSpentAmount += (childStats['spent_amount'] as double? ?? 0);
      }
    }

    // 如果没有任何子分类有预算，返回空
    if (totalMonthlyAmount == 0) {
      return {};
    }

    final usagePercentage = totalMonthlyAmount > 0 ? (totalSpentAmount / totalMonthlyAmount * 100) : 0.0;

    return {
      'category_id': category.id,
      'monthly_amount': totalMonthlyAmount,
      'spent_amount': totalSpentAmount,
      'remaining_amount': totalMonthlyAmount - totalSpentAmount,
      'usage_percentage': usagePercentage,
      'is_aggregated': true,
    };
  }

  /// 跳转到添加预算页面
  void _navigateToAddBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AnnualBudgetFormScreen(),
      ),
    ).then((_) => _loadData());
  }
}
