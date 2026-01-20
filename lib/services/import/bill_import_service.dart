import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:charset/charset.dart';
import '../../models/transaction.dart' as model;

/// 账单导入服务
class BillImportService {
  /// 导入支付宝 CSV 账单
  Future<List<model.Transaction>> importAlipayCSV(
    File file,
    int defaultAccountId,
  ) async {
    try {
      // 读取文件（GBK 编码）
      final bytes = await file.readAsBytes();
      final content = _decodeGBK(bytes);

      // 解析 CSV
      final rows = const CsvToListConverter().convert(
        content,
        eol: '\n',
        fieldDelimiter: ',',
      );

      // 跳过前24行（表头信息）
      if (rows.length <= 25) {
        throw Exception('文件内容不完整');
      }

      final transactions = <model.Transaction>[];
      final now = DateTime.now();

      // 从第26行开始解析（第25行是列名）
      for (int i = 25; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.length < 7) continue;

        try {
          final timeStr = row[0]?.toString() ?? '';
          final typeCategory = row[1]?.toString() ?? '';  // 交易分类
          final counterparty = row[2]?.toString() ?? '';   // 交易对方
          final description = row[4]?.toString() ?? '';    // 商品说明
          final incomeExpense = row[5]?.toString() ?? '';  // 收/支
          final amountStr = row[6]?.toString() ?? '';      // 金额
          final payMethod = row[7]?.toString() ?? '';      // 收/付款方式
          final status = row[8]?.toString() ?? '';         // 交易状态

          // 跳过不计收支的记录
          if (incomeExpense != '支出' && incomeExpense != '收入') {
            continue;
          }

          // 跳过非成功状态
          if (status != '支付成功' && status != '交易成功' && status != '还款成功') {
            continue;
          }

          // 解析时间
          final transactionTime = _parseDateTime(timeStr);
          if (transactionTime == null) continue;

          // 解析金额
          final amount = double.tryParse(amountStr);
          if (amount == null || amount <= 0) continue;

          // 确定类型
          final type = incomeExpense == '收入' ? 'income' : 'expense';

          // 组合描述（不再包含交易对方，交易对方单独存储）
          final fullDescription = description.isNotEmpty
                    ? '$typeCategory - $description'
                    : typeCategory;

          transactions.add(model.Transaction(
            accountId: defaultAccountId,
            type: type,
            amount: amount,
            description: fullDescription,
            counterparty: counterparty.isNotEmpty ? counterparty : null,
            transactionTime: transactionTime,
            importSource: 'alipay',
            isConfirmed: false,
            notes: '支付方式: $payMethod',
            createdAt: now,
            updatedAt: now,
          ));
        } catch (e) {
          // 跳过解析失败的行
          continue;
        }
      }

      return transactions;
    } catch (e) {
      throw Exception('导入支付宝账单失败: $e');
    }
  }

  /// 导入微信 XLSX 账单
  Future<List<model.Transaction>> importWeChatExcel(
    File file,
    int defaultAccountId,
  ) async {
    try {
      // 读取 Excel 文件
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        throw Exception('Excel 文件为空');
      }

      // 获取第一个工作表
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('工作表为空');
      }

      final transactions = <model.Transaction>[];
      final now = DateTime.now();

      // 从第18行开始解析（第17行是列名，索引从0开始所以是17）
      for (int i = 17; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        try {
          final timeStr = row[0]?.value?.toString() ?? '';
          final transactionType = row[1]?.value?.toString() ?? '';  // 交易类型
          final counterparty = row[2]?.value?.toString() ?? '';     // 交易对方
          final product = row[3]?.value?.toString() ?? '';          // 商品
          final incomeExpense = row[4]?.value?.toString() ?? '';    // 收/支
          final amountStr = row[5]?.value?.toString() ?? '';        // 金额(元)
          final payMethod = row[6]?.value?.toString() ?? '';        // 支付方式
          final status = row[7]?.value?.toString() ?? '';           // 当前状态

          // 跳过中性交易
          if (incomeExpense != '支出' && incomeExpense != '收入') {
            continue;
          }

          // 跳过非成功状态
          if (status != '支付成功' && status != '已转账' && status != '已存入零钱' && status != '对方已收钱') {
            continue;
          }

          // 解析时间
          final transactionTime = _parseDateTime(timeStr);
          if (transactionTime == null) continue;

          // 解析金额（移除 ¥ 符号）
          var cleanAmount = amountStr.replaceAll('¥', '').replaceAll(',', '').trim();
          final amount = double.tryParse(cleanAmount);
          if (amount == null || amount <= 0) continue;

          // 确定类型
          final type = incomeExpense == '收入' ? 'income' : 'expense';

          // 组合描述（不再包含交易对方，交易对方单独存储）
          final fullDescription = product.isNotEmpty
              ? '$transactionType - $product'
              : transactionType;

          transactions.add(model.Transaction(
            accountId: defaultAccountId,
            type: type,
            amount: amount,
            description: fullDescription,
            counterparty: counterparty.isNotEmpty ? counterparty : null,
            transactionTime: transactionTime,
            importSource: 'wechat',
            isConfirmed: false,
            notes: '支付方式: $payMethod',
            createdAt: now,
            updatedAt: now,
          ));
        } catch (e) {
          // 跳过解析失败的行
          continue;
        }
      }

      return transactions;
    } catch (e) {
      throw Exception('导入微信账单失败: $e');
    }
  }

  /// 解析日期时间
  DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // 支付宝和微信格式: 2025-11-29 20:26:34
      final format = DateFormat('yyyy-MM-dd HH:mm:ss');
      return format.parse(dateStr);
    } catch (e) {
      try {
        // 尝试其他格式
        final format = DateFormat('yyyy-MM-dd HH:mm');
        return format.parse(dateStr);
      } catch (e2) {
        return null;
      }
    }
  }

  /// GBK 编码转换
  String _decodeGBK(List<int> bytes) {
    try {
      // 使用 charset 库进行 GBK 解码
      return const GbkCodec().decode(bytes);
    } catch (e) {
      // 如果失败，尝试 UTF-8
      try {
        return String.fromCharCodes(bytes);
      } catch (e2) {
        return String.fromCharCodes(bytes);
      }
    }
  }
}
