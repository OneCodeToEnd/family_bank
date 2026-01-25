import 'dart:typed_data';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:charset/charset.dart';
import '../models/bill_summary.dart';
import '../models/validation_result.dart';
import '../models/bill_file_type.dart';
import '../models/transaction.dart';
import '../constants/bill_file_constants.dart';
import 'ai/ai_classifier_service.dart';

/// 账单导入验证服务
///
/// 负责验证导入账单的准确性，通过对比文件摘要和计算摘要来发现潜在问题
class BillValidationService {
  final AIClassifierService _aiClassifierService;

  BillValidationService(this._aiClassifierService);

  /// 从交易列表计算摘要统计信息
  ///
  /// 根据交易类型（income/expense）和金额计算各项统计指标
  BillSummary calculateSummaryFromTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return BillSummary(
        totalCount: 0,
        incomeCount: 0,
        expenseCount: 0,
        totalIncome: 0.0,
        totalExpense: 0.0,
        netAmount: 0.0,
      );
    }

    int incomeCount = 0;
    int expenseCount = 0;
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        incomeCount++;
        totalIncome += transaction.amount;
      } else if (transaction.type == 'expense') {
        expenseCount++;
        totalExpense += transaction.amount;
      }
    }

    // Round to 2 decimal places to avoid floating point precision issues
    totalIncome = double.parse(totalIncome.toStringAsFixed(2));
    totalExpense = double.parse(totalExpense.toStringAsFixed(2));
    final netAmount = double.parse((totalIncome - totalExpense).toStringAsFixed(2));

    return BillSummary(
      totalCount: transactions.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netAmount: netAmount,
    );
  }

  /// 从文件中提取摘要信息（使用 AI）
  ///
  /// 使用 LLM 从原始文件内容中提取汇总统计信息
  ///
  /// [fileBytes] 文件字节内容
  /// [fileName] 文件名（用于检测文件类型）
  /// [fileType] 文件类型
  Future<BillSummary> extractSummaryFromFile(
    Uint8List fileBytes,
    String fileName,
    BillFileType fileType,
  ) async {
    try {
      // 1. 准备文件内容
      final fileContent = _prepareFileContent(fileBytes, fileType);

      // 2. 调用 AI 提取摘要
      final fileTypeStr = fileType == BillFileType.alipayCSV ? 'alipay' : 'wechat';
      final summaryData = await _aiClassifierService.extractBillSummary(
        fileContent,
        fileTypeStr,
      );

      // 3. 解析为 BillSummary
      return BillSummary.fromJson(summaryData);
    } catch (e) {
      // 提取失败时返回空摘要
      // Failed to extract summary from file: $e
      return BillSummary(
        totalCount: 0,
        incomeCount: 0,
        expenseCount: 0,
        totalIncome: 0.0,
        totalExpense: 0.0,
        netAmount: 0.0,
      );
    }
  }

  /// 准备文件内容供 LLM 分析
  ///
  /// 根据文件类型提取表头部分（包含汇总信息）
  String _prepareFileContent(Uint8List fileBytes, BillFileType fileType) {
    switch (fileType) {
      case BillFileType.alipayCSV:
        return _prepareAlipayContent(fileBytes);
      case BillFileType.wechatXLSX:
        return _prepareWeChatContent(fileBytes);
      default:
        throw Exception('Unsupported file type: $fileType');
    }
  }

  /// 准备支付宝 CSV 文件内容
  ///
  /// 提取前 24 行表头信息（包含汇总统计）
  String _prepareAlipayContent(Uint8List fileBytes) {
    try {
      // 使用 GBK 编码解码
      final content = const GbkCodec().decode(fileBytes);

      // 分割行
      final lines = content.split('\n');

      // 提取前 24 行（表头信息，包含汇总数据）
      final headerLines = lines.take(BillFileConstants.alipay.summaryRows).toList();

      return headerLines.join('\n');
    } catch (e) {
      // 如果 GBK 解码失败，尝试 UTF-8
      try {
        final content = utf8.decode(fileBytes);
        final lines = content.split('\n');
        final headerLines = lines.take(BillFileConstants.alipay.summaryRows).toList();
        return headerLines.join('\n');
      } catch (e2) {
        throw Exception('Failed to decode Alipay CSV file: $e2');
      }
    }
  }

  /// 准备微信 XLSX 文件内容
  ///
  /// 提取前 17 行表头信息（包含汇总统计）
  String _prepareWeChatContent(Uint8List fileBytes) {
    try {
      // 解析 Excel 文件
      final excel = Excel.decodeBytes(fileBytes);

      if (excel.tables.isEmpty) {
        throw Exception('Excel file is empty');
      }

      // 获取第一个工作表
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel sheet is empty');
      }

      // 提取前 17 行（表头信息，包含汇总数据）
      final headerRows = sheet.rows.take(BillFileConstants.wechat.summaryRows).toList();

      // 转换为文本格式
      final lines = headerRows.map((row) {
        return row.map((cell) => cell?.value?.toString() ?? '').join(',');
      }).toList();

      return lines.join('\n');
    } catch (e) {
      throw Exception('Failed to parse WeChat XLSX file: $e');
    }
  }

  /// 验证导入结果
  ///
  /// 对比文件摘要和计算摘要，生成验证结果
  ///
  /// [fileSummary] 从文件中提取的摘要
  /// [calculatedSummary] 从交易列表计算的摘要
  ValidationResult validateImport(
    BillSummary fileSummary,
    BillSummary calculatedSummary,
  ) {
    final issues = <ValidationIssue>[];

    // 1. 检查交易总笔数
    if (fileSummary.totalCount != calculatedSummary.totalCount) {
      final discrepancy = (calculatedSummary.totalCount - fileSummary.totalCount).abs().toDouble();
      issues.add(ValidationIssue(
        field: 'totalCount',
        expectedValue: fileSummary.totalCount,
        actualValue: calculatedSummary.totalCount,
        discrepancy: discrepancy,
        message: '交易笔数不匹配: 文件显示 ${fileSummary.totalCount} 笔，实际导入 ${calculatedSummary.totalCount} 笔',
      ));
    }

    // 2. 检查收入笔数
    if (fileSummary.incomeCount != calculatedSummary.incomeCount) {
      final discrepancy = (calculatedSummary.incomeCount - fileSummary.incomeCount).abs().toDouble();
      issues.add(ValidationIssue(
        field: 'incomeCount',
        expectedValue: fileSummary.incomeCount,
        actualValue: calculatedSummary.incomeCount,
        discrepancy: discrepancy,
        message: '收入笔数不匹配: 文件显示 ${fileSummary.incomeCount} 笔，实际导入 ${calculatedSummary.incomeCount} 笔',
      ));
    }

    // 3. 检查支出笔数
    if (fileSummary.expenseCount != calculatedSummary.expenseCount) {
      final discrepancy = (calculatedSummary.expenseCount - fileSummary.expenseCount).abs().toDouble();
      issues.add(ValidationIssue(
        field: 'expenseCount',
        expectedValue: fileSummary.expenseCount,
        actualValue: calculatedSummary.expenseCount,
        discrepancy: discrepancy,
        message: '支出笔数不匹配: 文件显示 ${fileSummary.expenseCount} 笔，实际导入 ${calculatedSummary.expenseCount} 笔',
      ));
    }

    // 4. 检查收入金额（使用容差 0.01）
    final incomeDiff = (calculatedSummary.totalIncome - fileSummary.totalIncome).abs();
    if (incomeDiff > 0.01) {
      issues.add(ValidationIssue(
        field: 'totalIncome',
        expectedValue: fileSummary.totalIncome,
        actualValue: calculatedSummary.totalIncome,
        discrepancy: incomeDiff,
        message: '收入金额不匹配: 文件显示 ¥${fileSummary.totalIncome.toStringAsFixed(2)}，实际导入 ¥${calculatedSummary.totalIncome.toStringAsFixed(2)}',
      ));
    }

    // 5. 检查支出金额（使用容差 0.01）
    final expenseDiff = (calculatedSummary.totalExpense - fileSummary.totalExpense).abs();
    if (expenseDiff > 0.01) {
      issues.add(ValidationIssue(
        field: 'totalExpense',
        expectedValue: fileSummary.totalExpense,
        actualValue: calculatedSummary.totalExpense,
        discrepancy: expenseDiff,
        message: '支出金额不匹配: 文件显示 ¥${fileSummary.totalExpense.toStringAsFixed(2)}，实际导入 ¥${calculatedSummary.totalExpense.toStringAsFixed(2)}',
      ));
    }

    // 6. 确定验证状态和建议
    final status = _determineValidationStatus(issues, fileSummary);
    final suggestion = _generateSuggestion(status, issues);

    return ValidationResult(
      status: status,
      fileSummary: fileSummary,
      calculatedSummary: calculatedSummary,
      issues: issues,
      suggestion: suggestion,
    );
  }

  /// 确定验证状态
  ///
  /// 根据问题的严重程度判断状态
  ValidationStatus _determineValidationStatus(
    List<ValidationIssue> issues,
    BillSummary fileSummary,
  ) {
    if (issues.isEmpty) {
      return ValidationStatus.perfect;
    }

    // 检查是否有重大差异
    for (final issue in issues) {
      final discrepancy = (issue.discrepancy ?? 0).toDouble();

      // 笔数差异超过 2 笔视为错误
      if (issue.field.contains('Count')) {
        if (discrepancy > 2) {
          return ValidationStatus.error;
        }
      }

      // 金额差异超过 5% 或超过 100 元视为错误
      if (issue.field.contains('total')) {
        final expected = (issue.expectedValue as num).toDouble();
        if (expected > 0) {
          final percentage = (discrepancy / expected) * 100;
          if (percentage > 5 || discrepancy > 100) {
            return ValidationStatus.error;
          }
        } else if (discrepancy > 100) {
          return ValidationStatus.error;
        }
      }
    }

    // 有差异但不严重，返回警告
    return ValidationStatus.warning;
  }

  /// 生成建议信息
  ///
  /// 根据验证状态生成用户友好的建议
  String _generateSuggestion(ValidationStatus status, List<ValidationIssue> issues) {
    switch (status) {
      case ValidationStatus.perfect:
        return '✓ 验证通过！所有统计数据完全匹配，可以安全导入。';

      case ValidationStatus.warning:
        final countIssues = issues.where((i) => i.field.contains('Count')).length;
        final amountIssues = issues.where((i) => i.field.contains('total')).length;

        final parts = <String>[];
        if (countIssues > 0) {
          parts.add('$countIssues 项笔数差异');
        }
        if (amountIssues > 0) {
          parts.add('$amountIssues 项金额差异');
        }

        return '⚠ 发现轻微差异（${parts.join('、')}）。\n'
            '可能原因：\n'
            '• 部分交易被过滤（如失败交易、退款交易）\n'
            '• 文件格式或编码问题\n'
            '建议：请仔细检查导入预览，确认无误后再导入。';

      case ValidationStatus.error:
        return '✗ 发现重大差异！\n'
            '可能原因：\n'
            '• 文件解析错误\n'
            '• 文件格式不兼容\n'
            '• 数据损坏或不完整\n'
            '建议：请检查文件是否正确，或联系技术支持。';
    }
  }
}
