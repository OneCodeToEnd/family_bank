import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/transaction.dart' as model;
import '../../models/category.dart';
import '../../utils/category_icon_utils.dart';
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

/// 账单列表页面
class TransactionListScreen extends StatefulWidget {
  final String? initialType; // 初始类型筛选：'income' 或 'expense'
  final DateTime? initialStartDate; // 初始开始日期
  final DateTime? initialEndDate; // 初始结束日期

  const TransactionListScreen({
    super.key,
    this.initialType,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  // 筛选条件
  DateTime _selectedMonth = DateTime.now();
  int? _selectedAccountId; // null 表示"全部账户"
  List<int> _selectedCategoryIds = []; // 选中的分类ID列表，空表示全部
  String? _selectedType; // 类型筛选：null=全部, 'income'=收入, 'expense'=支出
  DateTime? _startDate; // 自定义开始日期
  DateTime? _endDate; // 自定义结束日期
  bool _useCustomDateRange = false; // 是否使用自定义日期范围

  @override
  void initState() {
    super.initState();
    // 应用初始筛选条件
    if (widget.initialType != null) {
      _selectedType = widget.initialType;
    }
    if (widget.initialStartDate != null && widget.initialEndDate != null) {
      _startDate = widget.initialStartDate;
      _endDate = widget.initialEndDate;
      _useCustomDateRange = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await context.read<TransactionProvider>().loadTransactions();
    if (!mounted) return;
    await context.read<AccountProvider>().loadAccounts();
    if (!mounted) return;
    await context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('记账本'),
        backgroundColor: const Color(0xFF4CAF50), // 绿色主题
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 绿色背景的顶部区域
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // 账户筛选和分类筛选
                _buildFilterTabs(),

                // 月份选择和统计
                _buildMonthSelectorAndStats(),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // 账单列表
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// 顶部筛选标签（分类选择、账户选择）
  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // 分类选择按钮
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              final selectedCount = _selectedCategoryIds.length;
              return _buildFilterChip(
                label: selectedCount > 0 ? '$selectedCount个分类' : '全部分类',
                icon: Icons.category,
                selected: selectedCount > 0,
                onTap: () => _showCategorySelector(categoryProvider),
              );
            },
          ),
          const SizedBox(width: 12),

          // 账户选择下拉
          Expanded(
            child: Consumer<AccountProvider>(
              builder: (context, accountProvider, child) {
                final accounts = accountProvider.visibleAccounts;

                return Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedAccountId,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                      dropdownColor: const Color(0xFF4CAF50),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('全部账户', style: TextStyle(color: Colors.white)),
                        ),
                        ...accounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text(
                              account.name,
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 月份选择器和统计信息
  Widget _buildMonthSelectorAndStats() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = _getFilteredTransactions(provider.transactions);

        double totalIncome = 0;
        double totalExpense = 0;

        for (var t in transactions) {
          if (t.type == 'income') {
            totalIncome += t.amount;
          } else {
            totalExpense += t.amount;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // 月份选择器
              GestureDetector(
                onTap: _showMonthPicker,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('yyyy年MM月').format(_selectedMonth),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 收支统计
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '总支出¥${totalExpense.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '总收入¥${totalIncome.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 账单列表
  Widget _buildTransactionList() {
    return Consumer4<TransactionProvider, AccountProvider, CategoryProvider, FamilyProvider>(
      builder: (context, transactionProvider, accountProvider, categoryProvider, familyProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = _getFilteredTransactions(transactionProvider.transactions);

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '还没有账单记录',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToAddTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('添加账单'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        // 按日期分组
        final groupedTransactions = _groupByDate(transactions);

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: groupedTransactions.length,
          itemBuilder: (context, index) {
            final dateKey = groupedTransactions.keys.elementAt(index);
            final dayTransactions = groupedTransactions[dateKey]!;

            return _buildDateGroup(
              dateKey,
              dayTransactions,
              accountProvider,
              categoryProvider,
            );
          },
        );
      },
    );
  }

  /// 按日期分组的账单
  Widget _buildDateGroup(
    String dateKey,
    List<model.Transaction> transactions,
    AccountProvider accountProvider,
    CategoryProvider categoryProvider,
  ) {
    double dayIncome = 0;
    double dayExpense = 0;

    for (var t in transactions) {
      if (t.type == 'income') {
        dayIncome += t.amount;
      } else {
        dayExpense += t.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期头部
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (dayExpense > 0)
                    Text(
                      '出 ${dayExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  if (dayIncome > 0 && dayExpense > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('·', style: TextStyle(color: Colors.grey[500])),
                    ),
                  if (dayIncome > 0)
                    Text(
                      '入 ${dayIncome.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // 账单卡片
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: transactions.asMap().entries.map((entry) {
              final index = entry.key;
              final transaction = entry.value;
              final isLast = index == transactions.length - 1;

              return _buildTransactionItem(
                transaction,
                accountProvider,
                categoryProvider,
                isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 单个账单项
  Widget _buildTransactionItem(
    model.Transaction transaction,
    AccountProvider accountProvider,
    CategoryProvider categoryProvider,
    bool isLast,
  ) {
    final category = transaction.categoryId != null
        ? categoryProvider.getCategoryById(transaction.categoryId!)
        : null;
    final account = accountProvider.getAccountById(transaction.accountId);
    final isIncome = transaction.type == 'income';

    // 获取分类图标和颜色
    final categoryIcon = _getCategoryIcon(category);
    final categoryColor = _getCategoryColor(category, isIncome);

    return InkWell(
      onTap: () => _navigateToTransactionDetail(transaction),
      borderRadius: BorderRadius.vertical(
        top: Radius.zero,
        bottom: isLast ? const Radius.circular(12) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: !isLast
              ? Border(bottom: BorderSide(color: Colors.grey[100]!))
              : null,
        ),
        child: Row(
          children: [
            // 分类图标
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                categoryIcon,
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // 信息部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? '未分类',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('HH:mm').format(transaction.transactionTime)} ${transaction.description ?? account?.name ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 金额
            Text(
              '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isIncome ? Colors.orange : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类图标
  IconData _getCategoryIcon(Category? category) {
    if (category == null) return Icons.help_outline;

    // 根据分类名称返回对应图标
    final name = category.name;
    if (name.contains('餐饮') || name.contains('吃')) return Icons.restaurant;
    if (name.contains('购物')) return Icons.shopping_bag;
    if (name.contains('交通')) return Icons.directions_car;
    if (name.contains('娱乐')) return Icons.sports_esports;
    if (name.contains('医疗')) return Icons.local_hospital;
    if (name.contains('服务')) return Icons.room_service;
    if (name.contains('工资') || name.contains('收入')) return Icons.account_balance_wallet;

    return Icons.category;
  }

  /// 获取分类颜色
  Color _getCategoryColor(Category? category, bool isIncome) {
    if (isIncome) return Colors.orange;

    if (category == null) return Colors.grey;

    final name = category.name;
    if (name.contains('餐饮')) return const Color(0xFF4CAF50);
    if (name.contains('购物')) return const Color(0xFF2196F3);
    if (name.contains('交通')) return const Color(0xFFFF9800);
    if (name.contains('娱乐')) return const Color(0xFF00BCD4);
    if (name.contains('医疗')) return const Color(0xFFE91E63);
    if (name.contains('服务')) return const Color(0xFF9C27B0);

    return const Color(0xFF4CAF50);
  }

  /// 获取筛选后的账单
  List<model.Transaction> _getFilteredTransactions(List<model.Transaction> transactions) {
    var filtered = transactions;

    // 日期筛选：使用自定义日期范围或月份
    if (_useCustomDateRange && _startDate != null && _endDate != null) {
      filtered = filtered.where((t) {
        return t.transactionTime.isAfter(_startDate!.subtract(const Duration(seconds: 1))) &&
               t.transactionTime.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    } else {
      // 月份筛选
      filtered = filtered.where((t) {
        return t.transactionTime.year == _selectedMonth.year &&
               t.transactionTime.month == _selectedMonth.month;
      }).toList();
    }

    // 类型筛选
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // 账户筛选
    if (_selectedAccountId != null) {
      filtered = filtered.where((t) => t.accountId == _selectedAccountId).toList();
    }

    // 分类筛选
    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.categoryId != null && _selectedCategoryIds.contains(t.categoryId)
      ).toList();
    }

    // 按时间倒序排序
    filtered.sort((a, b) => b.transactionTime.compareTo(a.transactionTime));

    return filtered;
  }

  /// 按日期分组
  Map<String, List<model.Transaction>> _groupByDate(List<model.Transaction> transactions) {
    final grouped = <String, List<model.Transaction>>{};

    for (var transaction in transactions) {
      final displayDate = _formatDateKey(transaction.transactionTime);
      grouped.putIfAbsent(displayDate, () => []);
      grouped[displayDate]!.add(transaction);
    }

    return grouped;
  }

  /// 格式化日期显示 - 参考截图格式 "12月29日 今天"
  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    final monthDay = '${date.month}月${date.day}日';

    if (targetDate == today) {
      return '$monthDay 今天';
    } else if (targetDate == yesterday) {
      return '$monthDay 昨天';
    } else {
      // 获取星期
      final weekdays = ['', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      final weekday = weekdays[date.weekday];
      return '$monthDay $weekday';
    }
  }

  /// 显示月份选择器
  Future<void> _showMonthPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        selectedMonth: _selectedMonth,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  /// 显示分类选择器
  void _showCategorySelector(CategoryProvider categoryProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CategorySelectorSheet(
        categories: categoryProvider.visibleCategories,
        selectedCategoryIds: _selectedCategoryIds,
        onConfirm: (selectedIds) {
          setState(() {
            _selectedCategoryIds = selectedIds;
          });
        },
      ),
    );
  }

  /// 跳转到添加账单
  void _navigateToAddTransaction() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    ).then((_) => _loadData());
  }

  /// 跳转到账单详情
  void _navigateToTransactionDetail(model.Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    ).then((_) => _loadData());
  }
}

/// 月份选择器对话框
class _MonthPickerDialog extends StatefulWidget {
  final DateTime selectedMonth;

  const _MonthPickerDialog({required this.selectedMonth});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.selectedMonth.year;
    selectedMonth = widget.selectedMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择月份'),
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          children: [
            // 年份选择
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      selectedYear--;
                    });
                  },
                ),
                Text(
                  '$selectedYear年',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      selectedYear++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 月份网格
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == selectedMonth && selectedYear == widget.selectedMonth.year;

                  return InkWell(
                    onTap: () {
                      Navigator.pop(
                        context,
                        DateTime(selectedYear, month),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month月',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

/// 分类选择器弹窗（树形结构）
class _CategorySelectorSheet extends StatefulWidget {
  final List<Category> categories;
  final List<int> selectedCategoryIds;
  final Function(List<int>) onConfirm;

  const _CategorySelectorSheet({
    required this.categories,
    required this.selectedCategoryIds,
    required this.onConfirm,
  });

  @override
  State<_CategorySelectorSheet> createState() => _CategorySelectorSheetState();
}

class _CategorySelectorSheetState extends State<_CategorySelectorSheet> {
  late List<int> _tempSelectedIds;
  final Set<int> _expandedCategoryIds = {}; // 展开的父分类ID集合

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.selectedCategoryIds);
    // 默认展开所有一级分类
    _expandAllTopLevel();
  }

  /// 展开所有一级分类
  void _expandAllTopLevel() {
    for (var category in widget.categories) {
      if (category.parentId == null && _hasChildren(category)) {
        _expandedCategoryIds.add(category.id!);
      }
    }
  }

  /// 判断分类是否有子分类
  bool _hasChildren(Category category) {
    return widget.categories.any((c) => c.parentId == category.id);
  }

  /// 获取子分类
  List<Category> _getChildren(Category parent) {
    return widget.categories
        .where((c) => c.parentId == parent.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '选择分类',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_tempSelectedIds.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelectedIds.clear();
                      });
                    },
                    child: const Text('清除'),
                  ),
              ],
            ),
          ),

          // 分类树形列表
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 支出分类树
                ..._buildCategoryTree('expense'),

                // 收入分类树
                ..._buildCategoryTree('income'),
              ],
            ),
          ),

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '已选择 ${_tempSelectedIds.length} 个分类',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(_tempSelectedIds);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分类树（按类型）
  List<Widget> _buildCategoryTree(String type) {
    final topLevelCategories = widget.categories
        .where((c) => c.parentId == null && c.type == type)
        .toList();

    if (topLevelCategories.isEmpty) {
      return [];
    }

    return [
      // 类型标题
      Padding(
        padding: EdgeInsets.fromLTRB(16, type == 'expense' ? 8 : 16, 16, 8),
        child: Row(
          children: [
            Icon(
              type == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: type == 'expense' ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              type == 'expense' ? '支出分类' : '收入分类',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      // 顶级分类及其子分类
      ...topLevelCategories.expand((category) => _buildCategoryWithChildren(category, 0)),
    ];
  }

  /// 递归构建分类及其子分类
  List<Widget> _buildCategoryWithChildren(Category category, int level) {
    final hasChildren = _hasChildren(category);
    final isExpanded = _expandedCategoryIds.contains(category.id);
    final children = hasChildren ? _getChildren(category) : <Category>[];

    return [
      _buildCategoryItem(category, level, hasChildren, isExpanded),
      // 如果展开且有子分类，递归显示子分类
      if (isExpanded && hasChildren)
        ...children.expand((child) => _buildCategoryWithChildren(child, level + 1)),
    ];
  }

  Widget _buildCategoryItem(Category category, int level, bool hasChildren, bool isExpanded) {
    final isSelected = _tempSelectedIds.contains(category.id);

    return ListTile(
      contentPadding: EdgeInsets.only(
        left: 16.0 + (level * 24.0), // 根据层级缩进
        right: 16.0,
      ),
      leading: hasChildren
          ? IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_more : Icons.chevron_right,
                size: 20,
              ),
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
          : const SizedBox(width: 48), // 占位，保持对齐
      title: Row(
        children: [
          if (category.icon != null)
            Icon(
              CategoryIconUtils.getIconData(category.icon!),
              size: 18,
              color: CategoryIconUtils.getColor(category.color),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: level == 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        setState(() {
          if (isSelected) {
            // 取消选中：移除该分类及其所有子孙分类
            _tempSelectedIds.remove(category.id);
            final descendantIds = _getAllDescendantIds(category);
            for (var id in descendantIds) {
              _tempSelectedIds.remove(id);
            }
          } else {
            // 选中：添加该分类及其所有子孙分类
            _tempSelectedIds.add(category.id!);
            final descendantIds = _getAllDescendantIds(category);
            _tempSelectedIds.addAll(descendantIds);
          }
        });
      },
    );
  }

  /// 递归获取某个分类的所有子孙分类ID
  List<int> _getAllDescendantIds(Category category) {
    final List<int> descendantIds = [];
    final children = _getChildren(category);

    for (var child in children) {
      if (child.id != null) {
        descendantIds.add(child.id!);
        // 递归获取子分类的子分类
        descendantIds.addAll(_getAllDescendantIds(child));
      }
    }

    return descendantIds;
  }
}
