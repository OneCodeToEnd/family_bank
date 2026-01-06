import 'category_suggestion.dart';

/// 分类匹配结果
class CategoryMatchResult {
  final int? categoryId; // 匹配到的分类ID
  final double confidence; // 置信度 (0-1)
  final String matchType; // 匹配类型
  final String? matchedRule; // 匹配的规则描述
  final int? ruleId; // 匹配的规则ID
  final bool needsConfirmation; // 是否需要用户确认
  final List<CategorySuggestion> alternatives; // 备选分类

  const CategoryMatchResult({
    this.categoryId,
    required this.confidence,
    required this.matchType,
    this.matchedRule,
    this.ruleId,
    this.needsConfirmation = false,
    this.alternatives = const [],
  });

  /// 是否成功匹配
  bool get isMatched => categoryId != null;

  /// 是否高置信度
  bool get isHighConfidence => confidence >= 0.85;

  /// 是否中等置信度
  bool get isMediumConfidence => confidence >= 0.7 && confidence < 0.85;

  /// 是否低置信度
  bool get isLowConfidence => confidence < 0.7;

  @override
  String toString() {
    return 'CategoryMatchResult(categoryId: $categoryId, confidence: $confidence, matchType: $matchType, needsConfirmation: $needsConfirmation)';
  }
}
