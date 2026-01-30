/// 年度预算模型
class AnnualBudget {
  final int? id;
  final int familyId;
  final int categoryId;
  final int year;
  final String type; // 'income' 或 'expense'
  final double annualAmount;
  final double monthlyAmount; // 自动计算: annualAmount / 12
  final DateTime createdAt;
  final DateTime updatedAt;

  AnnualBudget({
    this.id,
    required this.familyId,
    required this.categoryId,
    required this.year,
    required this.type,
    required this.annualAmount,
    required this.monthlyAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从年度金额创建预算（自动计算月度金额）
  factory AnnualBudget.fromAnnualAmount({
    int? id,
    required int familyId,
    required int categoryId,
    required int year,
    required String type,
    required double annualAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return AnnualBudget(
      id: id,
      familyId: familyId,
      categoryId: categoryId,
      year: year,
      type: type,
      annualAmount: annualAmount,
      monthlyAmount: annualAmount / 12,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  factory AnnualBudget.fromMap(Map<String, dynamic> map) {
    return AnnualBudget(
      id: map['id'] as int?,
      familyId: map['family_id'] as int,
      categoryId: map['category_id'] as int,
      year: map['year'] as int,
      type: map['type'] as String? ?? 'expense',
      annualAmount: (map['annual_amount'] as num).toDouble(),
      monthlyAmount: (map['monthly_amount'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'family_id': familyId,
      'category_id': categoryId,
      'year': year,
      'type': type,
      'annual_amount': annualAmount,
      'monthly_amount': monthlyAmount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  AnnualBudget copyWith({
    int? id,
    int? familyId,
    int? categoryId,
    int? year,
    String? type,
    double? annualAmount,
    double? monthlyAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnualBudget(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      type: type ?? this.type,
      annualAmount: annualAmount ?? this.annualAmount,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AnnualBudget(id: $id, familyId: $familyId, categoryId: $categoryId, '
        'year: $year, type: $type, annualAmount: $annualAmount, monthlyAmount: $monthlyAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnnualBudget &&
        other.id == id &&
        other.familyId == familyId &&
        other.categoryId == categoryId &&
        other.year == year && other.type == type &&
        other.annualAmount == annualAmount &&
        other.monthlyAmount == monthlyAmount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        familyId.hashCode ^
        categoryId.hashCode ^
        year.hashCode ^
        annualAmount.hashCode ^
        monthlyAmount.hashCode;
  }
}
