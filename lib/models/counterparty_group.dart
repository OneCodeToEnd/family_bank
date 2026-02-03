/// 对手方分组模型
/// 用于将多个子对手方（如不同分店）关联到一个主对手方
class CounterpartyGroup {
  final int? id;
  final String mainCounterparty; // 主对手方名称（如"沃尔玛"）
  final String subCounterparty; // 子对手方名称（如"沃尔玛福田香梅分店"）
  final bool autoCreated; // 是否由智能识别自动创建
  final double confidenceScore; // 匹配置信度（0-1）
  final DateTime createdAt;
  final DateTime updatedAt;

  CounterpartyGroup({
    this.id,
    required this.mainCounterparty,
    required this.subCounterparty,
    this.autoCreated = false,
    this.confidenceScore = 1.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CounterpartyGroup.fromMap(Map<String, dynamic> map) {
    return CounterpartyGroup(
      id: map['id'] as int?,
      mainCounterparty: map['main_counterparty'] as String,
      subCounterparty: map['sub_counterparty'] as String,
      autoCreated: (map['auto_created'] as int?) == 1,
      confidenceScore: (map['confidence_score'] as num?)?.toDouble() ?? 1.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'main_counterparty': mainCounterparty,
      'sub_counterparty': subCounterparty,
      'auto_created': autoCreated ? 1 : 0,
      'confidence_score': confidenceScore,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  CounterpartyGroup copyWith({
    int? id,
    String? mainCounterparty,
    String? subCounterparty,
    bool? autoCreated,
    double? confidenceScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CounterpartyGroup(
      id: id ?? this.id,
      mainCounterparty: mainCounterparty ?? this.mainCounterparty,
      subCounterparty: subCounterparty ?? this.subCounterparty,
      autoCreated: autoCreated ?? this.autoCreated,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CounterpartyGroup(id: $id, main: $mainCounterparty, sub: $subCounterparty, autoCreated: $autoCreated, confidence: $confidenceScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CounterpartyGroup &&
        other.id == id &&
        other.mainCounterparty == mainCounterparty &&
        other.subCounterparty == subCounterparty;
  }

  @override
  int get hashCode {
    return id.hashCode ^ mainCounterparty.hashCode ^ subCounterparty.hashCode;
  }
}
