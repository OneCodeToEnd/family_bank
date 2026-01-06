/// 分类建议
class CategorySuggestion {
  final int categoryId;
  final String categoryName;
  final double confidence;
  final String reason; // 建议原因

  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.confidence,
    required this.reason,
  });

  @override
  String toString() {
    return 'CategorySuggestion(categoryId: $categoryId, categoryName: $categoryName, confidence: $confidence, reason: $reason)';
  }
}
