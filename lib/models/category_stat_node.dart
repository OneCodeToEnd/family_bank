import 'category.dart';
import 'transaction.dart';

/// 预算状态枚举
enum BudgetStatus {
  normal,    // < 80%
  warning,   // 80% ~ 100%
  exceeded,  // >= 100%
}

/// 分类统计节点
/// 用于分类层级统计展示，包含分类信息、金额统计、子分类和流水明细
class CategoryStatNode {
  /// 分类信息
  final Category category;

  /// 该分类及所有子分类的总金额
  final double amount;

  /// 交易笔数
  final int transactionCount;

  /// 子分类统计列表
  final List<CategoryStatNode> children;

  /// 该分类的流水明细（仅末级分类加载）
  List<Transaction>? transactions;

  /// 是否展开
  bool isExpanded;

  /// 预算金额（根据时间范围计算：月度/季度/年度）
  final double? budgetAmount;

  /// 预算使用百分比
  final double? budgetUsagePercent;

  /// 预算状态
  final BudgetStatus? budgetStatus;

  CategoryStatNode({
    required this.category,
    required this.amount,
    required this.transactionCount,
    this.children = const [],
    this.transactions,
    this.isExpanded = false,
    this.budgetAmount,
    this.budgetUsagePercent,
    this.budgetStatus,
  });

  /// 是否为末级分类（没有子分类）
  bool get isLeafNode => children.isEmpty;

  /// 复制并更新
  CategoryStatNode copyWith({
    Category? category,
    double? amount,
    int? transactionCount,
    List<CategoryStatNode>? children,
    List<Transaction>? transactions,
    bool? isExpanded,
    double? budgetAmount,
    double? budgetUsagePercent,
    BudgetStatus? budgetStatus,
  }) {
    return CategoryStatNode(
      category: category ?? this.category,
      amount: amount ?? this.amount,
      transactionCount: transactionCount ?? this.transactionCount,
      children: children ?? this.children,
      transactions: transactions ?? this.transactions,
      isExpanded: isExpanded ?? this.isExpanded,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      budgetUsagePercent: budgetUsagePercent ?? this.budgetUsagePercent,
      budgetStatus: budgetStatus ?? this.budgetStatus,
    );
  }

  @override
  String toString() {
    return 'CategoryStatNode(category: ${category.name}, amount: $amount, count: $transactionCount, children: ${children.length}, isLeaf: $isLeafNode)';
  }
}
