import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/account_provider.dart';
import '../../widgets/category_hierarchy_stat_card.dart';
import 'counterparty_transactions_screen.dart';

/// 数据分析页面
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String _selectedPeriod = 'month'; // month, quarter, year, all
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  int? _selectedAccountId; // 选中的账户ID，null表示全部账户

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<TransactionProvider>();

    // 根据选择的时间段设置筛选条件
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (_selectedPeriod) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterMonth, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
      default:
        startDate = null;
        endDate = null;
    }

    // 应用时间和账户筛选
    provider.setDateRangeFilter(startDate, endDate);
    provider.setAccountFilter(_selectedAccountId);
    await provider.loadTransactionsWithFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _showAccountSelector,
            tooltip: '选择账户',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showPeriodSelector,
            tooltip: '选择时间段',
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无数据',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开始记账后即可查看分析',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 时间段显示
                _buildPeriodInfo(),
                const SizedBox(height: 16),

                // 总览统计卡片
                _buildOverviewCard(provider),
                const SizedBox(height: 16),

                // 分类统计看板（新增）
                const CategoryHierarchyStatCard(),
                const SizedBox(height: 16),

                // 收支趋势图
                _buildTrendChart(provider),
                const SizedBox(height: 16),

                // 分类支出排行
                _buildCategoryRanking(provider),
                const SizedBox(height: 16),

                // 账户支出汇总
                _buildAccountExpenseRanking(provider),
                const SizedBox(height: 16),

                // 前十大单笔支出
                _buildTopExpenses(provider),
                const SizedBox(height: 16),

                // 账户收支对比
                _buildAccountIncomeExpenseChart(provider),
                const SizedBox(height: 16),

                // 支出对方排行
                _buildCounterpartyRanking(provider),
                const SizedBox(height: 16),

                // 分类支出饼图
                _buildCategoryPieChart(provider),
                const SizedBox(height: 16),

                // 月度同比环比
                _buildMonthComparison(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 时间段显示
  Widget _buildPeriodInfo() {
    String periodText;
    switch (_selectedPeriod) {
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
        if (_customStartDate != null && _customEndDate != null) {
          final start = DateFormat('yyyy/MM/dd').format(_customStartDate!);
          final end = DateFormat('yyyy/MM/dd').format(_customEndDate!);
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
    if (_selectedAccountId != null) {
      final accountProvider = context.read<AccountProvider>();
      final account = accountProvider.accounts.firstWhere(
        (a) => a.id == _selectedAccountId,
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

  /// 总览统计卡片
  Widget _buildOverviewCard(TransactionProvider provider) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('overview_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data;
        if (stats == null) {
          return const SizedBox.shrink();
        }

        final totalIncome = stats['total_income'] as double? ?? 0.0;
        final totalExpense = stats['total_expense'] as double? ?? 0.0;
        final balance = stats['balance'] as double? ?? 0.0;
        final incomeCount = stats['income_count'] as int? ?? 0;
        final expenseCount = stats['expense_count'] as int? ?? 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 收支平衡
                Builder(
                  builder: (context) {
                    final appColors = context.appColors;
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: balance >= 0
                              ? [appColors.successColor.withValues(alpha: 0.8), appColors.successColor]
                              : [Theme.of(context).colorScheme.error.withValues(alpha: 0.8), Theme.of(context).colorScheme.error],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '收支平衡',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¥${balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 收入支出对比
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        '总收入',
                        '¥${totalIncome.toStringAsFixed(2)}',
                        '$incomeCount 笔',
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        '总支出',
                        '¥${totalExpense.toStringAsFixed(2)}',
                        '$expenseCount 笔',
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    String amount,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 收支趋势图
  Widget _buildTrendChart(TransactionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '收支趋势',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('trend_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
              future: provider.getMonthlyTrend(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final trendData = snapshot.data ?? [];
                if (trendData.isEmpty) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('暂无趋势数据')),
                  );
                }

                return SizedBox(
                  height: 250,
                  child: _buildLineChart(trendData),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 折线图
  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    // 分离收入和支出数据
    final months = <String>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final month = item['month'] as String;
      final amount = (item['total_amount'] as num?)?.toDouble() ?? 0.0;

      months.add(month);

      // 这里需要分别获取收入和支出
      // 由于 getMonthlyTrend 返回的是总和，我们需要分别查询
      // 暂时使用总金额作为示例
      expenseSpots.add(FlSpot(i.toDouble(), amount));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < months.length) {
                  final month = months[index];
                  // 显示月份，如 "01"
                  final parts = month.split('-');
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      parts.length > 1 ? parts[1] : month,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        minX: 0,
        maxX: (months.length - 1).toDouble(),
        minY: 0,
        lineBarsData: [
          // 支出线
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  /// 分类支出排行
  Widget _buildCategoryRanking(TransactionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支出分类排行',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('category_ranking_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
              future: provider.getCategoryExpenseRanking(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ranking = snapshot.data ?? [];
                if (ranking.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('暂无分类数据'),
                    ),
                  );
                }

                // 计算总金额用于百分比
                final totalAmount = ranking.fold<double>(
                  0,
                  (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0.0),
                );

                return Column(
                  children: ranking.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final categoryName = item['category_name'] as String? ?? '未知';
                    final amount = (item['total_amount'] as num?)?.toDouble() ?? 0.0;
                    final count = item['transaction_count'] as int? ?? 0;
                    final percentage = totalAmount > 0 ? (amount / totalAmount * 100) : 0.0;

                    return _buildRankingItem(
                      index + 1,
                      categoryName,
                      amount,
                      count,
                      percentage,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(
    int rank,
    String categoryName,
    double amount,
    int count,
    double percentage,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // 排名
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? (rank == 1
                      ? Colors.amber
                      : rank == 2
                          ? Colors.grey
                          : Colors.brown)
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.white : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 分类名称和笔数
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count 笔 · ${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 金额
          Text(
            '¥${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// 时间段选择器
  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择时间段',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_view_month),
                title: const Text('本月'),
                selected: _selectedPeriod == 'month',
                onTap: () {
                  setState(() => _selectedPeriod = 'month');
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('本季度'),
                selected: _selectedPeriod == 'quarter',
                onTap: () {
                  setState(() => _selectedPeriod = 'quarter');
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('本年'),
                selected: _selectedPeriod == 'year',
                onTap: () {
                  setState(() => _selectedPeriod = 'year');
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('全部'),
                selected: _selectedPeriod == 'all',
                onTap: () {
                  setState(() => _selectedPeriod = 'all');
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: const Text('自定义'),
                selected: _selectedPeriod == 'custom',
                onTap: () {
                  Navigator.pop(context);
                  _showCustomDatePicker();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 自定义日期选择
  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _loadData();
    }
  }

  /// 账户选择器
  void _showAccountSelector() {
    final accountProvider = context.read<AccountProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择账户',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // 全部账户选项
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('全部账户'),
                selected: _selectedAccountId == null,
                onTap: () {
                  setState(() => _selectedAccountId = null);
                  Navigator.pop(context);
                  _loadData();
                },
              ),
              const Divider(),
              // 账户列表
              ...accountProvider.visibleAccounts.map((account) {
                return ListTile(
                  leading: Icon(_getAccountIcon(account.icon)),
                  title: Text(account.name),
                  subtitle: Text(account.type),
                  selected: _selectedAccountId == account.id,
                  onTap: () {
                    setState(() => _selectedAccountId = account.id);
                    Navigator.pop(context);
                    _loadData();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 获取账户图标
  IconData _getAccountIcon(String? iconName) {
    if (iconName == null) return Icons.account_balance_wallet;

    final iconMap = {
      'wallet': Icons.account_balance_wallet,
      'credit_card': Icons.credit_card,
      'savings': Icons.savings,
      'account_balance': Icons.account_balance,
      'payment': Icons.payment,
      'money': Icons.attach_money,
    };

    return iconMap[iconName] ?? Icons.account_balance_wallet;
  }

  /// 账户支出汇总
  Widget _buildAccountExpenseRanking(TransactionProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('account_expense_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getAccountExpenseRanking(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final total = data.fold<double>(0, (sum, item) => sum + (item['total_amount'] as num).toDouble());

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('账户支出排行', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...data.map((item) {
                  final amount = (item['total_amount'] as num).toDouble();
                  final percentage = (amount / total * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['account_name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(value: amount / total, backgroundColor: Colors.grey[200]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('$percentage%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 前十大单笔支出
  Widget _buildTopExpenses(TransactionProvider provider) {
    return FutureBuilder(
      key: ValueKey('top_expenses_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getTopExpenses(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('前十大单笔支出', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...snapshot.data!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: index < 3 ? [Colors.amber, Colors.grey, Colors.brown][index] : Colors.blue,
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(tx.description ?? ''),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(tx.transactionTime)),
                    trailing: Text('¥${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 账户收支对比柱状图
  Widget _buildAccountIncomeExpenseChart(TransactionProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('account_income_expense_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getAccountIncomeExpenseStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('账户收支对比', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: data.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(toY: (item['total_income'] as num).toDouble(), color: Colors.green, width: 15),
                            BarChartRodData(toY: (item['total_expense'] as num).toDouble(), color: Colors.red, width: 15),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= data.length) return const Text('');
                              return Text(data[value.toInt()]['account_name'], style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 12, height: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('收入', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Container(width: 12, height: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    const Text('支出', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 支出对方排行
  Widget _buildCounterpartyRanking(TransactionProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('counterparty_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getCounterpartyRanking(type: 'expense', limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final total = data.fold<double>(0, (sum, item) => sum + (item['total_amount'] as num).toDouble());

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('支出对方排行', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final amount = (item['total_amount'] as num).toDouble();
                  final percentage = (amount / total * 100).toStringAsFixed(1);
                  final counterparty = item['counterparty'] as String? ?? '未知';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(counterparty),
                    subtitle: Text('${item['transaction_count']}笔交易'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('¥${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$percentage%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    onTap: () => _navigateToCounterpartyTransactions(counterparty, 'expense'),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 分类支出饼图
  Widget _buildCategoryPieChart(TransactionProvider provider) {
    const fallbackColors = [
      0xFFE57373, 0xFF64B5F6, 0xFF81C784, 0xFFFFD54F, 0xFFBA68C8,
      0xFF4DD0E1, 0xFFFF8A65, 0xFFA1887F, 0xFF90A4AE, 0xFFAED581,
    ];

    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('category_pie_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getCategoryExpenseRanking(limit: 10),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final total = data.fold<double>(0, (sum, item) => sum + (item['total_amount'] as num).toDouble());

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('分类支出占比', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: data.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final amount = (item['total_amount'] as num).toDouble();
                        final percentage = amount / total * 100;
                        final colorValue = item['category_color'];
                        Color color;
                        try {
                          color = colorValue is int
                            ? Color(colorValue)
                            : Color(int.parse('0xFF${colorValue?.replaceAll('#', '')}'));
                        } catch (e) {
                          color = Color(fallbackColors[index % fallbackColors.length]);
                        }
                        return PieChartSectionData(
                          value: amount,
                          title: '${percentage.toStringAsFixed(1)}%',
                          color: color,
                          radius: 100,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final colorValue = item['category_color'];
                    Color color;
                    try {
                      color = colorValue is int
                        ? Color(colorValue)
                        : Color(int.parse('0xFF${colorValue?.replaceAll('#', '')}'));
                    } catch (e) {
                      color = Color(fallbackColors[index % fallbackColors.length]);
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, color: color),
                        const SizedBox(width: 4),
                        Text(item['category_name'], style: const TextStyle(fontSize: 12)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 月度同比环比
  Widget _buildMonthComparison(TransactionProvider provider) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('month_comparison_${provider.filterAccountId}_${provider.filterStartDate}_${provider.filterEndDate}'),
      future: provider.getMonthlyTrend(type: 'expense'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.length < 2) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final current = data.last;
        final previous = data[data.length - 2];
        final currentAmount = (current['total_amount'] as num).toDouble();
        final previousAmount = (previous['total_amount'] as num).toDouble();
        final momChange = previousAmount == 0 ? 0 : ((currentAmount - previousAmount) / previousAmount * 100);

        Map<String, dynamic>? yearAgo;
        double yoyChange = 0;
        if (data.length >= 13) {
          yearAgo = data[data.length - 13];
          final yearAgoAmount = (yearAgo['total_amount'] as num).toDouble();
          yoyChange = yearAgoAmount == 0 ? 0 : ((currentAmount - yearAgoAmount) / yearAgoAmount * 100);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('月度对比', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('环比', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            '${momChange >= 0 ? '+' : ''}${momChange.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: momChange >= 0 ? Colors.red : Colors.green),
                          ),
                          Text('vs ${previous['month']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (yearAgo != null)
                      Expanded(
                        child: Column(
                          children: [
                            const Text('同比', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(
                              '${yoyChange >= 0 ? '+' : ''}${yoyChange.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: yoyChange >= 0 ? Colors.red : Colors.green),
                            ),
                            Text('vs ${yearAgo['month']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 导航到对方交易流水详情页面
  void _navigateToCounterpartyTransactions(String counterparty, String type) {
    // 获取当前的筛选时间范围
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate = now;

    switch (_selectedPeriod) {
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'quarter':
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterMonth, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        startDate = _customStartDate;
        endDate = _customEndDate;
        break;
      default:
        startDate = null;
        endDate = null;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterpartyTransactionsScreen(
          counterparty: counterparty,
          type: type,
          startDate: startDate,
          endDate: endDate,
          accountId: _selectedAccountId,
        ),
      ),
    );
  }
}
