import 'package:flutter/foundation.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart' as category_model;
import '../models/category_stat_node.dart';
import '../services/database/transaction_db_service.dart';
import '../services/database/rule_db_service.dart';
import '../services/database/category_db_service.dart';

/// 账单流水状态管理
class TransactionProvider with ChangeNotifier {
  final TransactionDbService _dbService = TransactionDbService();
  final RuleDbService _ruleService = RuleDbService();

  // 状态数据
  List<model.Transaction> _transactions = [];
  model.Transaction? _currentTransaction;

  // 筛选条件
  int? _filterAccountId;
  int? _filterCategoryId;
  String? _filterType;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterCounterparty;

  // 对手方相关
  List<String> _counterparties = [];

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<model.Transaction> get transactions => _transactions;
  model.Transaction? get currentTransaction => _currentTransaction;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 筛选条件 Getters
  int? get filterAccountId => _filterAccountId;
  int? get filterCategoryId => _filterCategoryId;
  String? get filterType => _filterType;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;
  String? get filterCounterparty => _filterCounterparty;

  // 对手方 Getters
  List<String> get counterparties => _counterparties;

  /// 获取收入账单
  List<model.Transaction> get incomeTransactions =>
      _transactions.where((t) => t.type == 'income').toList();

  /// 获取支出账单
  List<model.Transaction> get expenseTransactions =>
      _transactions.where((t) => t.type == 'expense').toList();

  /// 获取未分类账单
  List<model.Transaction> get uncategorizedTransactions =>
      _transactions.where((t) => t.categoryId == null).toList();

  /// 获取未确认账单
  List<model.Transaction> get unconfirmedTransactions =>
      _transactions.where((t) => !t.isConfirmed).toList();

  // ==================== 初始化 ====================

  /// 初始化
  Future<void> initialize() async {
    await loadTransactions();
  }

  // ==================== 账单操作 ====================

  /// 加载所有账单
  Future<void> loadTransactions() async {
    _setLoading(true);
    try {
      _transactions = await _dbService.getAllTransactions();
      _clearError();
    } catch (e) {
      _setError('加载账单失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根据筛选条件加载账单
  Future<void> loadTransactionsWithFilter() async {
    _setLoading(true);
    try {
      if (_filterStartDate != null || _filterEndDate != null) {
        // 使用时间范围查询
        _transactions = await _dbService.getTransactionsByDateRange(
          _filterStartDate ?? DateTime(2000),
          _filterEndDate ?? DateTime.now(),
          accountId: _filterAccountId,
          categoryId: _filterCategoryId,
          type: _filterType,
          counterparty: _filterCounterparty,
        );
      } else if (_filterAccountId != null) {
        _transactions = await _dbService.getTransactionsByAccountId(_filterAccountId!);
      } else if (_filterCategoryId != null) {
        _transactions = await _dbService.getTransactionsByCategoryId(_filterCategoryId!);
      } else if (_filterType != null) {
        _transactions = await _dbService.getTransactionsByType(_filterType!);
      } else {
        _transactions = await _dbService.getAllTransactions();
      }
      _clearError();
    } catch (e) {
      _setError('加载账单失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建账单
  Future<bool> createTransaction({
    required int accountId,
    int? categoryId,
    required String type,
    required double amount,
    String? description,
    String? counterparty,
    DateTime? transactionTime,
    String importSource = 'manual',
    bool isConfirmed = true,
  }) async {
    _setLoading(true);
    try {
      final transaction = model.Transaction(
        accountId: accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        counterparty: counterparty,
        transactionTime: transactionTime ?? DateTime.now(),
        importSource: importSource,
        isConfirmed: isConfirmed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.createTransaction(transaction);

      // 重新加载
      await loadTransactionsWithFilter();

      _clearError();
      return true;
    } catch (e) {
      _setError('创建账单失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量导入账单
  Future<Map<String, dynamic>?> importTransactionsBatch(
    List<model.Transaction> transactions,
  ) async {
    _setLoading(true);
    try {
      final result = await _dbService.createTransactionsBatch(transactions);

      // 重新加载
      await loadTransactionsWithFilter();

      _clearError();
      return result;
    } catch (e) {
      _setError('导入账单失败: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新账单
  Future<bool> updateTransaction(model.Transaction transaction) async {
    _setLoading(true);
    try {
      await _dbService.updateTransaction(transaction);
      await loadTransactionsWithFilter();

      // 如果是当前账单，更新引用
      if (_currentTransaction?.id == transaction.id) {
        _currentTransaction = _transactions.firstWhere((t) => t.id == transaction.id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('更新账单失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新账单分类
  Future<bool> updateTransactionCategory(
    int transactionId,
    int categoryId, {
    bool isConfirmed = true,
  }) async {
    _setLoading(true);
    try {
      await _dbService.updateTransactionCategory(
        transactionId,
        categoryId,
        isConfirmed: isConfirmed,
      );
      await loadTransactionsWithFilter();
      _clearError();
      return true;
    } catch (e) {
      _setError('更新分类失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量更新账单分类
  Future<bool> updateTransactionsCategoryBatch(
    List<int> transactionIds,
    int categoryId,
  ) async {
    _setLoading(true);
    try {
      await _dbService.updateTransactionsCategoryBatch(transactionIds, categoryId);
      await loadTransactionsWithFilter();
      _clearError();
      return true;
    } catch (e) {
      _setError('批量更新失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除账单
  Future<bool> deleteTransaction(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteTransaction(id);
      await loadTransactionsWithFilter();

      // 如果删除的是当前账单，清空
      if (_currentTransaction?.id == id) {
        _currentTransaction = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('删除账单失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量删除账单
  Future<bool> deleteTransactionsBatch(List<int> ids) async {
    _setLoading(true);
    try {
      await _dbService.deleteTransactionsBatch(ids);
      await loadTransactionsWithFilter();
      _clearError();
      return true;
    } catch (e) {
      _setError('批量删除失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换当前账单
  void setCurrentTransaction(model.Transaction transaction) {
    _currentTransaction = transaction;
    notifyListeners();
  }

  /// 根据ID获取账单
  model.Transaction? getTransactionById(int id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== 智能分类 ====================

  /// 根据描述推荐分类
  Future<List<Map<String, dynamic>>> recommendCategory(String description) async {
    try {
      return await _ruleService.matchDescription(description);
    } catch (e) {
      _setError('推荐分类失败: $e');
      return [];
    }
  }

  /// 自动分类未分类账单
  Future<int> autoClassifyUncategorized() async {
    _setLoading(true);
    int classifiedCount = 0;

    try {
      final uncategorized = await _dbService.getUncategorizedTransactions();

      for (var transaction in uncategorized) {
        if (transaction.description == null || transaction.description!.isEmpty) {
          continue;
        }

        final matches = await _ruleService.matchDescription(transaction.description!);

        if (matches.isNotEmpty) {
          // 使用置信度最高的推荐
          final bestMatch = matches.first;
          final categoryId = bestMatch['category_id'] as int;

          await _dbService.updateTransactionCategory(
            transaction.id!,
            categoryId,
            isConfirmed: false, // 标记为未确认，需要用户审核
          );

          // 更新规则匹配次数
          final rule = bestMatch['rule'];
          if (rule != null && rule.id != null) {
            await _ruleService.incrementRuleMatchCount(rule.id);
          }

          classifiedCount++;
        }
      }

      await loadTransactionsWithFilter();
      _clearError();
    } catch (e) {
      _setError('自动分类失败: $e');
    } finally {
      _setLoading(false);
    }

    return classifiedCount;
  }

  // ==================== 筛选条件 ====================

  /// 设置账户筛选
  void setAccountFilter(int? accountId) {
    _filterAccountId = accountId;
    notifyListeners();
  }

  /// 设置分类筛选
  void setCategoryFilter(int? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  /// 设置类型筛选
  void setTypeFilter(String? type) {
    _filterType = type;
    notifyListeners();
  }

  /// 设置时间范围筛选
  void setDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    notifyListeners();
  }

  /// 清空筛选条件
  void clearFilters() {
    _filterAccountId = null;
    _filterCategoryId = null;
    _filterType = null;
    _filterStartDate = null;
    _filterEndDate = null;
    notifyListeners();
  }

  // ==================== 统计分析 ====================

  /// 获取账单统计
  Future<Map<String, dynamic>?> getStatistics() async {
    try {
      return await _dbService.getTransactionStatistics(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        accountId: _filterAccountId,
        categoryId: _filterCategoryId,
      );
    } catch (e) {
      _setError('获取统计失败: $e');
      return null;
    }
  }

  /// 获取分类支出排行
  Future<List<Map<String, dynamic>>> getCategoryExpenseRanking({int limit = 10}) async {
    try {
      return await _dbService.getCategoryExpenseRanking(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        accountId: _filterAccountId,
        limit: limit,
      );
    } catch (e) {
      _setError('获取排行失败: $e');
      return [];
    }
  }

  /// 获取月度趋势
  Future<List<Map<String, dynamic>>> getMonthlyTrend({String? type}) async {
    try {
      return await _dbService.getMonthlyTrend(
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        type: type,
      );
    } catch (e) {
      _setError('获取趋势失败: $e');
      return [];
    }
  }

  /// 搜索账单
  Future<void> searchTransactions(String keyword) async {
    _setLoading(true);
    try {
      _transactions = await _dbService.searchTransactions(keyword);
      _clearError();
    } catch (e) {
      _setError('搜索失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== 辅助方法 ====================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// 清空错误信息
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ==================== 对手方管理 ====================

  /// 加载历史对手方列表
  Future<void> loadCounterparties() async {
    try {
      _counterparties = await _dbService.getCounterparties();
      notifyListeners();
    } catch (e) {
      _setError('加载对手方列表失败: $e');
    }
  }

  /// 搜索对手方（用于自动补全）
  Future<List<String>> searchCounterparties(String keyword) async {
    if (keyword.trim().isEmpty) {
      return _counterparties.take(10).toList();
    }
    return await _dbService.searchCounterparties(keyword);
  }

  /// 设置对手方筛选
  void setCounterpartyFilter(String? counterparty) {
    _filterCounterparty = counterparty;
    notifyListeners();
    loadTransactionsWithFilter();
  }

  /// 清除对手方筛选
  void clearCounterpartyFilter() {
    _filterCounterparty = null;
    notifyListeners();
    loadTransactionsWithFilter();
  }

  /// 获取对手方统计
  Future<Map<String, dynamic>> getCounterpartyStatistics(
      String counterparty) async {
    return await _dbService.getCounterpartyStatistics(counterparty);
  }

  /// 获取对手方排行
  Future<List<Map<String, dynamic>>> getCounterpartyRanking({
    required String type,
    int limit = 10,
  }) async {
    return await _dbService.getCounterpartyRanking(
      type: type,
      startTime: _filterStartDate?.millisecondsSinceEpoch,
      endTime: _filterEndDate?.millisecondsSinceEpoch,
      accountId: _filterAccountId,
      limit: limit,
    );
  }

  /// 获取账户支出排行
  Future<List<Map<String, dynamic>>> getAccountExpenseRanking() async {
    return await _dbService.getAccountExpenseRanking(
      startTime: _filterStartDate?.millisecondsSinceEpoch,
      endTime: _filterEndDate?.millisecondsSinceEpoch,
    );
  }

  /// 获取前N大单笔支出
  Future<List<model.Transaction>> getTopExpenses({int limit = 10}) async {
    return await _dbService.getTopExpenses(
      startTime: _filterStartDate?.millisecondsSinceEpoch,
      endTime: _filterEndDate?.millisecondsSinceEpoch,
      limit: limit,
    );
  }

  /// 获取账户收支统计
  Future<List<Map<String, dynamic>>> getAccountIncomeExpenseStats() async {
    return await _dbService.getAccountIncomeExpenseStats(
      startTime: _filterStartDate?.millisecondsSinceEpoch,
      endTime: _filterEndDate?.millisecondsSinceEpoch,
    );
  }

  /// 智能推荐对手方（基于描述）
  Future<List<String>> recommendCounterparty(String description) async {
    if (description.trim().isEmpty) {
      return [];
    }

    // 简单实现：搜索描述中包含的关键词
    final keywords = description.trim().split(' ');
    final Set<String> recommendations = {};

    for (var keyword in keywords) {
      if (keyword.length >= 2) {
        final results = await searchCounterparties(keyword);
        recommendations.addAll(results.take(3));
      }
    }

    return recommendations.take(5).toList();
  }

  // ==================== 分类层级统计 ====================

  /// 获取分类层级统计树
  Future<List<CategoryStatNode>> getCategoryHierarchyStats({
    String type = 'expense',
  }) async {
    try {
      // 1. 获取一级分类
      final categoryDbService = CategoryDbService();
      final topCategories = await categoryDbService.getTopLevelCategories(type: type);

      // 2. 递归构建统计树
      final List<CategoryStatNode> statNodes = [];
      for (var category in topCategories) {
        if (category.id == null) continue;
        final node = await _buildCategoryStatNode(category);
        statNodes.add(node);
      }

      return statNodes;
    } catch (e) {
      _setError('获取分类统计失败: $e');
      return [];
    }
  }

  /// 递归构建分类统计节点
  Future<CategoryStatNode> _buildCategoryStatNode(category_model.Category category) async {
    final categoryDbService = CategoryDbService();

    // 获取子分类
    final children = await categoryDbService.getSubCategories(category.id!);

    // 递归构建子节点
    final List<CategoryStatNode> childNodes = [];
    for (var child in children) {
      final childNode = await _buildCategoryStatNode(child);
      childNodes.add(childNode);
    }

    // 获取该分类及所有子分类的统计
    final stats = await _dbService.getCategoryHierarchyStatistics(
      category.id!,
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      accountId: _filterAccountId,
    );

    return CategoryStatNode(
      category: category,
      amount: (stats['total_amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: stats['transaction_count'] as int? ?? 0,
      children: childNodes,
      isExpanded: false,
    );
  }

  /// 加载指定分类的流水明细
  Future<List<model.Transaction>> loadCategoryTransactions(
    int categoryId, {
    bool includeChildren = false,
  }) async {
    try {
      return await _dbService.getTransactionsByCategoryHierarchy(
        categoryId,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        accountId: _filterAccountId,
        includeChildren: includeChildren,
      );
    } catch (e) {
      _setError('加载分类流水失败: $e');
      return [];
    }
  }
}
