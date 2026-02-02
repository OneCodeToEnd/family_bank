import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart';
import '../../services/database/transaction_db_service.dart';
import '../../widgets/transaction_item_widget.dart';
import '../../widgets/transaction_detail_sheet.dart';

/// 对方交易流水详情页面
/// 显示与指定对方的所有交易记录
class CounterpartyTransactionsScreen extends StatefulWidget {
  final String counterparty;
  final String type; // income/expense
  final DateTime? startDate;
  final DateTime? endDate;
  final int? accountId;

  const CounterpartyTransactionsScreen({
    super.key,
    required this.counterparty,
    required this.type,
    this.startDate,
    this.endDate,
    this.accountId,
  });

  @override
  State<CounterpartyTransactionsScreen> createState() =>
      _CounterpartyTransactionsScreenState();
}

class _CounterpartyTransactionsScreenState
    extends State<CounterpartyTransactionsScreen> {
  bool _isLoading = true;
  List<Transaction> _transactions = [];
  Map<String, dynamic>? _statistics;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbService = TransactionDbService();

      // 加载交易流水
      final transactions = await dbService.getTransactionsByDateRange(
        widget.startDate ?? DateTime(2000),
        widget.endDate ?? DateTime.now(),
        accountId: widget.accountId,
        type: widget.type,
        counterparty: widget.counterparty,
      );

      // 加载统计信息
      final statistics =
          await dbService.getCounterpartyStatistics(widget.counterparty);

      setState(() {
        _transactions = transactions;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.counterparty),
        actions: [
          if (_statistics != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_statistics!['transaction_count'] ?? 0} 笔交易',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无交易记录',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // 统计信息卡片
          if (_statistics != null) _buildStatisticsCard(),

          // 交易列表
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return TransactionItemWidget(
                  transaction: transaction,
                  onTap: () => _showTransactionDetail(transaction),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final totalIncome =
        (_statistics!['total_income'] as num?)?.toDouble() ?? 0.0;
    final totalExpense =
        (_statistics!['total_expense'] as num?)?.toDouble() ?? 0.0;
    final firstTransaction = _statistics!['first_transaction'] as int?;
    final lastTransaction = _statistics!['last_transaction'] as int?;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '交易统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 收支统计
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总收入',
                    '¥${totalIncome.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    '总支出',
                    '¥${totalExpense.toStringAsFixed(2)}',
                    Colors.red,
                    Icons.arrow_downward,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 交易时间范围
            if (firstTransaction != null && lastTransaction != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '首次交易: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(firstTransaction))}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '最近交易: ${DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(lastTransaction))}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String amount,
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
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
