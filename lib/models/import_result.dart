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

  /// 推荐的账户ID（用于智能匹配）
  final int? suggestedAccountId;

  /// 账单平台（alipay/wechat/unknown）
  final String? platform;

  /// 成功导入的交易数量
  int get successCount => transactions.length;

  /// 是否有验证结果
  bool get hasValidation => validationResult != null;

  /// 验证是否通过
  bool get isValidationPassed => validationResult?.isValid ?? true;

  /// 是否有验证警告
  bool get hasValidationWarnings => validationResult?.hasWarnings ?? false;

  /// 是否有推荐账户
  bool get hasSuggestedAccount => suggestedAccountId != null;

  ImportResult({
    required this.transactions,
    this.validationResult,
    this.source = 'manual',
    this.suggestedAccountId,
    this.platform,
  });

  /// 创建一个没有验证的导入结果
  factory ImportResult.withoutValidation({
    required List<Transaction> transactions,
    String source = 'manual',
    int? suggestedAccountId,
    String? platform,
  }) {
    return ImportResult(
      transactions: transactions,
      validationResult: null,
      source: source,
      suggestedAccountId: suggestedAccountId,
      platform: platform,
    );
  }

  /// 创建一个包含验证的导入结果
  factory ImportResult.withValidation({
    required List<Transaction> transactions,
    required ValidationResult validationResult,
    String source = 'manual',
    int? suggestedAccountId,
    String? platform,
  }) {
    return ImportResult(
      transactions: transactions,
      validationResult: validationResult,
      source: source,
      suggestedAccountId: suggestedAccountId,
      platform: platform,
    );
  }

  /// 复制并更新账户ID
  ImportResult copyWithAccount(int accountId) {
    return ImportResult(
      transactions: transactions.map((t) => t.copyWith(accountId: accountId)).toList(),
      validationResult: validationResult,
      source: source,
      suggestedAccountId: accountId,
      platform: platform,
    );
  }

  @override
  String toString() {
    return 'ImportResult(transactions: ${transactions.length}, '
        'source: $source, hasValidation: $hasValidation, '
        'isValid: $isValidationPassed, platform: $platform, '
        'suggestedAccountId: $suggestedAccountId)';
  }
}
