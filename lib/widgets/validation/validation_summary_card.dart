import 'package:flutter/material.dart';
import '../../models/validation_result.dart';

/// 验证摘要卡片
///
/// 显示账单导入验证的总体结果
class ValidationSummaryCard extends StatelessWidget {
  final ValidationResult validationResult;

  const ValidationSummaryCard({
    super.key,
    required this.validationResult,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: _getBackgroundColor(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildComparisonTable(),
            if (validationResult.issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildIssuesList(),
            ],
            if (validationResult.suggestion != null) ...[
              const SizedBox(height: 12),
              _buildSuggestion(),
            ],
          ],
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    switch (validationResult.status) {
      case ValidationStatus.perfect:
        return Colors.green.shade50;
      case ValidationStatus.warning:
        return Colors.orange.shade50;
      case ValidationStatus.error:
        return Colors.red.shade50;
    }
  }

  /// 构建标题
  Widget _buildHeader() {
    IconData icon;
    String title;
    Color iconColor;

    switch (validationResult.status) {
      case ValidationStatus.perfect:
        icon = Icons.check_circle;
        title = '验证通过';
        iconColor = Colors.green;
        break;
      case ValidationStatus.warning:
        icon = Icons.warning;
        title = '发现轻微差异';
        iconColor = Colors.orange;
        break;
      case ValidationStatus.error:
        icon = Icons.error;
        title = '发现重大差异';
        iconColor = Colors.red;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: iconColor,
          ),
        ),
      ],
    );
  }

  /// 构建对比表格
  Widget _buildComparisonTable() {
    final fileSummary = validationResult.fileSummary;
    final calculatedSummary = validationResult.calculatedSummary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          _buildTableRow(
            '交易笔数',
            fileSummary.totalCount.toString(),
            calculatedSummary.totalCount.toString(),
            fileSummary.totalCount == calculatedSummary.totalCount,
          ),
          _buildTableRow(
            '收入笔数',
            fileSummary.incomeCount.toString(),
            calculatedSummary.incomeCount.toString(),
            fileSummary.incomeCount == calculatedSummary.incomeCount,
          ),
          _buildTableRow(
            '支出笔数',
            fileSummary.expenseCount.toString(),
            calculatedSummary.expenseCount.toString(),
            fileSummary.expenseCount == calculatedSummary.expenseCount,
          ),
          _buildTableRow(
            '收入金额',
            '¥${fileSummary.totalIncome.toStringAsFixed(2)}',
            '¥${calculatedSummary.totalIncome.toStringAsFixed(2)}',
            (fileSummary.totalIncome - calculatedSummary.totalIncome).abs() <= 0.01,
          ),
          _buildTableRow(
            '支出金额',
            '¥${fileSummary.totalExpense.toStringAsFixed(2)}',
            '¥${calculatedSummary.totalExpense.toStringAsFixed(2)}',
            (fileSummary.totalExpense - calculatedSummary.totalExpense).abs() <= 0.01,
            isLast: true,
          ),
        ],
      ),
    );
  }

  /// 构建表格标题行
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            flex: 2,
            child: Text(
              '指标',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '文件统计',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '导入统计',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  /// 构建表格数据行
  Widget _buildTableRow(
    String label,
    String fileValue,
    String calculatedValue,
    bool isMatch, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fileValue,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              calculatedValue,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            isMatch ? Icons.check_circle : Icons.cancel,
            color: isMatch ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// 构建问题列表
  Widget _buildIssuesList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '差异详情',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...validationResult.issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        issue.message,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// 构建建议信息
  Widget _buildSuggestion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              validationResult.suggestion!,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
