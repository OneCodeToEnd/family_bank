import 'transaction.dart';
import 'validation_result.dart';

/// 账单导入结果
///
/// 包含导入的交易列表和验证结果
class ImportResult {
  /// 导入的交易列表
  final List<Transaction> transactions;

  /// 验证结果（可选）
  final ValidationResult? validationResult;

  /// 导入来源
  final String source;

  /// 成功导入的交易数量
  int get successCount => transactions.length;

  /// 是否有验证结果
  bool get hasValidation => validationResult != null;

  /// 验证是否通过
  bool get isValidationPassed => validationResult?.isValid ?? true;

  /// 是否有验证警告
  bool get hasValidationWarnings => validationResult?.hasWarnings ?? false;

  ImportResult({
    required this.transactions,
    this.validationResult,
    this.source = 'manual',
  });

  /// 创建一个没有验证的导入结果
  factory ImportResult.withoutValidation({
    required List<Transaction> transactions,
    String source = 'manual',
  }) {
    return ImportResult(
      transactions: transactions,
      validationResult: null,
      source: source,
    );
  }

  /// 创建一个包含验证的导入结果
  factory ImportResult.withValidation({
    required List<Transaction> transactions,
    required ValidationResult validationResult,
    String source = 'manual',
  }) {
    return ImportResult(
      transactions: transactions,
      validationResult: validationResult,
      source: source,
    );
  }

  @override
  String toString() {
    return 'ImportResult(transactions: ${transactions.length}, '
        'source: $source, hasValidation: $hasValidation, '
        'isValid: $isValidationPassed)';
  }
}
