import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/transaction.dart' as model;
import 'transaction_form_screen.dart';
import 'transaction_detail_screen.dart';

/// 账单列表页面
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 筛选条件
  String? _filterType; // income, expense
  int? _filterAccountId;
  int? _filterCategoryId;
  int? _filterMemberId;
  DateTimeRange? _filterDateRange;

  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    // 延迟到 build 之后再加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<TransactionProvider>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账单管理'),
        actions: [
          IconButton(
            icon: Icon(_showFilter ? Icons.filter_list : Icons.filter_list_off),
            tooltip: '筛选',
            onPressed: () {
              setState(() {
                _showFilter = !_showFilter;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索',
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选栏
          if (_showFilter) _buildFilterBar(),

          // 统计汇总
          _buildSummaryCard(),

          // 账单列表
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddTransaction(),
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
      ),
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_list, size: 20),
                const SizedBox(width: 8),
                const Text('筛选条件', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('清除'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 类型筛选
                ChoiceChip(
                  label: const Text('收入'),
                  selected: _filterType == 'income',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'income' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('支出'),
                  selected: _filterType == 'expense',
                  onSelected: (selected) {
                    setState(() {
                      _filterType = selected ? 'expense' : null;
                    });
                  },
                ),
                // 日期范围
                ActionChip(
                  label: Text(_filterDateRange == null
                    ? '选择日期'
                    : '${DateFormat('MM/dd').format(_filterDateRange!.start)} - ${DateFormat('MM/dd').format(_filterDateRange!.end)}'),
                  onPressed: _selectDateRange,
                ),
                // 更多筛选（账户、分类、成员）
                ActionChip(
                  label: const Text('更多筛选'),
                  onPressed: _showMoreFilters,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 统计汇总卡片
  Widget _buildSummaryCard() {
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                      const SizedBox(height: 4),
                      const Text('收入', style: TextStyle(fontSize: 12)),
                      Text(
                        '¥${totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                      const SizedBox(height: 4),
                      const Text('支出', style: TextStyle(fontSize: 12)),
                      Text(
                        '¥${totalExpense.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 20),
                      const SizedBox(height: 4),
                      const Text('结余', style: TextStyle(fontSize: 12)),
                      Text(
                        '¥${(totalIncome - totalExpense).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalIncome >= totalExpense ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

        if (transactionProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('错误: ${transactionProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final transactions = _getFilteredTransactions(transactionProvider.transactions);

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('还没有账单记录'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddTransaction(),
                  icon: const Icon(Icons.add),
                  label: const Text('添加账单'),
                ),
              ],
            ),
          );
        }

        // 按日期分组
        final groupedTransactions = _groupByDate(transactions);

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: groupedTransactions.length,
          itemBuilder: (context, index) {
            final dateKey = groupedTransactions.keys.elementAt(index);
            final dayTransactions = groupedTransactions[dateKey]!;

            return _buildDateGroup(
              dateKey,
              dayTransactions,
              accountProvider,
              categoryProvider,
              familyProvider,
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
    FamilyProvider familyProvider,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Text(
                dateKey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (dayIncome > 0)
                Text(
                  '收 ¥${dayIncome.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              if (dayIncome > 0 && dayExpense > 0)
                const SizedBox(width: 12),
              if (dayExpense > 0)
                Text(
                  '支 ¥${dayExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        // 账单列表
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: transactions.map((transaction) {
              return _buildTransactionTile(
                transaction,
                accountProvider,
                categoryProvider,
                familyProvider,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 单个账单项
  Widget _buildTransactionTile(
    model.Transaction transaction,
    AccountProvider accountProvider,
    CategoryProvider categoryProvider,
    FamilyProvider familyProvider,
  ) {
    final account = accountProvider.getAccountById(transaction.accountId);
    final category = transaction.categoryId != null
        ? categoryProvider.getCategoryById(transaction.categoryId!)
        : null;
    final member = account != null
        ? familyProvider.getMemberById(account.familyMemberId)
        : null;

    final isIncome = transaction.type == 'income';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        child: Icon(
          category != null ? Icons.category : Icons.help_outline,
          color: isIncome ? Colors.green : Colors.red,
        ),
      ),
      title: Text(transaction.description ?? '无描述'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${category?.name ?? '未分类'} · ${account?.name ?? '未知账户'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (member != null)
            Text(
              member.name,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${isIncome ? '+' : '-'}¥${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
          Text(
            DateFormat('HH:mm').format(transaction.transactionTime),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      onTap: () => _navigateToTransactionDetail(transaction),
    );
  }

  /// 获取筛选后的账单
  List<model.Transaction> _getFilteredTransactions(List<model.Transaction> transactions) {
    var filtered = transactions;

    // 类型筛选
    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    // 账户筛选
    if (_filterAccountId != null) {
      filtered = filtered.where((t) => t.accountId == _filterAccountId).toList();
    }

    // 分类筛选
    if (_filterCategoryId != null) {
      filtered = filtered.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    // 日期筛选
    if (_filterDateRange != null) {
      filtered = filtered.where((t) {
        return t.transactionTime.isAfter(_filterDateRange!.start.subtract(const Duration(days: 1))) &&
               t.transactionTime.isBefore(_filterDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // 搜索关键词
    if (_searchController.text.isNotEmpty) {
      final keyword = _searchController.text.toLowerCase();
      filtered = filtered.where((t) =>
        (t.description?.toLowerCase().contains(keyword) ?? false) ||
        (t.notes?.toLowerCase().contains(keyword) ?? false)
      ).toList();
    }

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

    // 按日期排序
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<model.Transaction>>{};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }

    return sortedMap;
  }

  /// 格式化日期显示
  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '今天 ${DateFormat('MM月dd日').format(date)}';
    } else if (targetDate == yesterday) {
      return '昨天 ${DateFormat('MM月dd日').format(date)}';
    } else {
      return DateFormat('MM月dd日 EEEE').format(date);
    }
  }

  /// 清除筛选
  void _clearFilters() {
    setState(() {
      _filterType = null;
      _filterAccountId = null;
      _filterCategoryId = null;
      _filterMemberId = null;
      _filterDateRange = null;
      _searchController.clear();
    });
  }

  /// 选择日期范围
  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _filterDateRange,
    );

    if (picked != null) {
      setState(() {
        _filterDateRange = picked;
      });
    }
  }

  /// 显示更多筛选
  void _showMoreFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMoreFiltersSheet(),
    );
  }

  /// 更多筛选弹窗
  Widget _buildMoreFiltersSheet() {
    return Consumer3<AccountProvider, CategoryProvider, FamilyProvider>(
      builder: (context, accountProvider, categoryProvider, familyProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('更多筛选', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 账户筛选
              DropdownButtonFormField<int?>(
                value: _filterAccountId,
                decoration: const InputDecoration(
                  labelText: '账户',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部账户')),
                  ...accountProvider.visibleAccounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterAccountId = value;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),

              // 分类筛选
              DropdownButtonFormField<int?>(
                value: _filterCategoryId,
                decoration: const InputDecoration(
                  labelText: '分类',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('全部分类')),
                  ...categoryProvider.visibleCategories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterCategoryId = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索账单'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入关键词',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('清除'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('搜索'),
          ),
        ],
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
    );
  }

  /// 跳转到账单详情
  void _navigateToTransactionDetail(model.Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
  }
}
