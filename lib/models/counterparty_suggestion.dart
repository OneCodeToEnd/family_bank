/// 对手方分组建议模型
/// 用于智能识别相似对手方并提供分组建议
class CounterpartySuggestion {
  final String mainCounterparty; // 建议的主对手方名称
  final List<String> subCounterparties; // 建议关联的子对手方列表
  final double confidenceScore; // 建议的置信度（0-1）
  final String reason; // 建议原因说明

  CounterpartySuggestion({
    required this.mainCounterparty,
    required this.subCounterparties,
    required this.confidenceScore,
    required this.reason,
  });

  /// 从Map创建建议
  factory CounterpartySuggestion.fromMap(Map<String, dynamic> map) {
    return CounterpartySuggestion(
      mainCounterparty: map['main_counterparty'] as String,
      subCounterparties: List<String>.from(map['sub_counterparties'] as List),
      confidenceScore: (map['confidence_score'] as num).toDouble(),
      reason: map['reason'] as String,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'main_counterparty': mainCounterparty,
      'sub_counterparties': subCounterparties,
      'confidence_score': confidenceScore,
      'reason': reason,
    };
  }

  /// 复制并修改
  CounterpartySuggestion copyWith({
    String? mainCounterparty,
    List<String>? subCounterparties,
    double? confidenceScore,
    String? reason,
  }) {
    return CounterpartySuggestion(
      mainCounterparty: mainCounterparty ?? this.mainCounterparty,
      subCounterparties: subCounterparties ?? this.subCounterparties,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reason: reason ?? this.reason,
    );
  }

  @override
  String toString() {
    return 'CounterpartySuggestion(main: $mainCounterparty, subs: ${subCounterparties.length}, confidence: $confidenceScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterpartySuggestion &&
        other.mainCounterparty == mainCounterparty &&
        _listEquals(other.subCounterparties, subCounterparties);
  }

  @override
  int get hashCode {
    return mainCounterparty.hashCode ^ subCounterparties.hashCode;
  }

  /// 列表相等性比较
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
