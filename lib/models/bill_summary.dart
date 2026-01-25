class BillSummary {
  final int totalCount;
  final int incomeCount;
  final int expenseCount;
  final double totalIncome;
  final double totalExpense;
  final double netAmount;

  BillSummary({
    required this.totalCount,
    required this.incomeCount,
    required this.expenseCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
  });

  /// Convert to JSON with English keys to avoid encoding issues
  Map<String, dynamic> toJson() => {
        'totalCount': totalCount,
        'incomeCount': incomeCount,
        'expenseCount': expenseCount,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netAmount': netAmount,
      };

  /// Create from JSON with English keys
  factory BillSummary.fromJson(Map<String, dynamic> json) => BillSummary(
        totalCount: json['totalCount'] as int,
        incomeCount: json['incomeCount'] as int,
        expenseCount: json['expenseCount'] as int,
        totalIncome: (json['totalIncome'] as num).toDouble(),
        totalExpense: (json['totalExpense'] as num).toDouble(),
        netAmount: (json['netAmount'] as num).toDouble(),
      );

  @override
  String toString() {
    return 'BillSummary(totalCount: $totalCount, incomeCount: $incomeCount, '
        'expenseCount: $expenseCount, totalIncome: $totalIncome, '
        'totalExpense: $totalExpense, netAmount: $netAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BillSummary &&
        other.totalCount == totalCount &&
        other.incomeCount == incomeCount &&
        other.expenseCount == expenseCount &&
        other.totalIncome == totalIncome &&
        other.totalExpense == totalExpense &&
        other.netAmount == netAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalCount,
      incomeCount,
      expenseCount,
      totalIncome,
      totalExpense,
      netAmount,
    );
  }
}
