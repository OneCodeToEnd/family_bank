import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';

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

    provider.setDateRangeFilter(startDate, endDate);
    await provider.loadTransactionsWithFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        actions: [
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

                // 收支趋势图
                _buildTrendChart(provider),
                const SizedBox(height: 16),

                // 分类支出排行
                _buildCategoryRanking(provider),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 20),
            const SizedBox(width: 8),
            Text(
              '统计时间段：$periodText',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// 总览统计卡片
  Widget _buildOverviewCard(TransactionProvider provider) {
    return FutureBuilder<Map<String, dynamic>?>(
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: balance >= 0
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
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
}
