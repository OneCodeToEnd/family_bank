import 'package:flutter/material.dart';
import '../../models/validation_result.dart';
import '../../theme/app_colors.dart';

/// 验证摘要卡片
///
/// 显示账单导入验证的总体结果
class ValidationSummaryCard extends StatefulWidget {
  final ValidationResult validationResult;

  const ValidationSummaryCard({
    super.key,
    required this.validationResult,
  });

  @override
  State<ValidationSummaryCard> createState() => _ValidationSummaryCardState();
}

class _ValidationSummaryCardState extends State<ValidationSummaryCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: _getBackgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildHeader()),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildComparisonTable(),
                  if (widget.validationResult.issues.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildIssuesList(),
                  ],
                  if (widget.validationResult.suggestion != null) ...[
                    const SizedBox(height: 12),
                    _buildSuggestion(),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor() {
    final appColors = context.appColors;

    switch (widget.validationResult.status) {
      case ValidationStatus.perfect:
        return appColors.successContainer;
      case ValidationStatus.warning:
        return appColors.warningContainer;
      case ValidationStatus.error:
        return Theme.of(context).colorScheme.errorContainer;
    }
  }

  /// 构建标题
  Widget _buildHeader() {
    IconData icon;
    String title;
    Color iconColor;
    final appColors = context.appColors;

    switch (widget.validationResult.status) {
      case ValidationStatus.perfect:
        icon = Icons.check_circle;
        title = '验证通过';
        iconColor = appColors.successColor;
        break;
      case ValidationStatus.warning:
        icon = Icons.warning;
        title = '发现轻微差异';
        iconColor = appColors.warningColor;
        break;
      case ValidationStatus.error:
        icon = Icons.error;
        title = '发现重大差异';
        iconColor = Theme.of(context).colorScheme.error;
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
    final fileSummary = widget.validationResult.fileSummary;
    final calculatedSummary = widget.validationResult.calculatedSummary;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
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
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
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
            color: isMatch ? appColors.successColor : colorScheme.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  /// 构建问题列表
  Widget _buildIssuesList() {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '差异详情',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...widget.validationResult.issues.map((issue) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: appColors.warningColor),
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
    final appColors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appColors.infoContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.infoColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: appColors.onInfoContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.validationResult.suggestion!,
              style: textTheme.bodySmall?.copyWith(
                color: appColors.onInfoContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
