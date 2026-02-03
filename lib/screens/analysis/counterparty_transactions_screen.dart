import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../services/database/transaction_db_service.dart';
import '../../providers/counterparty_provider.dart';
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
  bool _isGroup = false; // 是否为分组对手方
  List<String> _subCounterparties = []; // 子对手方列表
  List<Map<String, dynamic>> _subBreakdown = []; // 子对手方明细

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
      final counterpartyProvider = context.read<CounterpartyProvider>();

      // 检查是否为分组对手方
      final subCounterparties =
          await counterpartyProvider.getSubCounterparties(widget.counterparty);
      _isGroup = subCounterparties.isNotEmpty;
      _subCounterparties = subCounterparties;

      // 加载交易流水
      List<Transaction> transactions;
      if (_isGroup) {
        // 使用分组查询
        transactions = await dbService.getTransactionsByGroupedCounterparty(
          counterparty: widget.counterparty,
          startDate: widget.startDate ?? DateTime(2000),
          endDate: widget.endDate ?? DateTime.now(),
          accountId: widget.accountId,
          type: widget.type,
        );
      } else {
        // 使用普通查询
        transactions = await dbService.getTransactionsByDateRange(
          widget.startDate ?? DateTime(2000),
          widget.endDate ?? DateTime.now(),
          accountId: widget.accountId,
          type: widget.type,
          counterparty: widget.counterparty,
        );
      }

      // 加载统计信息
      Map<String, dynamic> statistics;
      if (_isGroup) {
        statistics = await dbService.getCounterpartyStatisticsGrouped(
          widget.counterparty,
        );
      } else {
        statistics = await dbService.getCounterpartyStatistics(
          widget.counterparty,
        );
      }

      // 加载子对手方明细
      List<Map<String, dynamic>> subBreakdown = [];
      if (_isGroup) {
        subBreakdown = await dbService.getSubCounterpartyBreakdown(
          widget.counterparty,
        );
      }

      setState(() {
        _transactions = transactions;
        _statistics = statistics;
        _subBreakdown = subBreakdown;
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(widget.counterparty)),
            if (_isGroup) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder, size: 12, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '分组 (${_subCounterparties.length})',
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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

            // 子对手方明细
            if (_isGroup && _subBreakdown.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                '分店明细',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._subBreakdown.map((sub) {
                final subName = sub['sub_counterparty'] as String;
                final subCount = sub['transaction_count'] as int;
                final subAmount = (sub['total_amount'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.store, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subName,
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                      Text(
                        '$subCount笔',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¥${subAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
