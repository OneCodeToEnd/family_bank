import 'package:flutter/foundation.dart';
import '../services/database/transaction_db_service.dart';
import '../services/database/annual_budget_db_service.dart';
import '../utils/app_logger.dart';

/// 首页统计数据模型
class HomeStatistics {
  final Map<String, dynamic> transactionStats;
  final Map<String, dynamic>? yearlyIncomeBudget;
  final Map<String, dynamic>? yearlyExpenseBudget;
  final Map<String, dynamic>? monthlyIncomeBudget;
  final Map<String, dynamic>? monthlyExpenseBudget;

  HomeStatistics({
    required this.transactionStats,
    this.yearlyIncomeBudget,
    this.yearlyExpenseBudget,
    this.monthlyIncomeBudget,
    this.monthlyExpenseBudget,
  });
}

/// 首页状态管理
class HomeProvider with ChangeNotifier {
  final TransactionDbService _transactionDbService = TransactionDbService();
  final AnnualBudgetDbService _budgetDbService = AnnualBudgetDbService();

  // 状态数据
  HomeStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  HomeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 初始化（可选，首页会主动加载）
  Future<void> initialize() async {
    // 首页会在需要时主动调用 loadStatistics
  }

  /// 加载首页统计数据
  /// [familyId] 当前家庭ID，如果为null则使用默认值1
  Future<void> loadStatistics({int? familyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 使用传入的 familyId，如果为 null 则使用默认值 1
      final currentFamilyId = familyId ?? 1;
      final now = DateTime.now();

      // 并行加载所有数据
      final results = await Future.wait([
        _transactionDbService.getHomePageStatistics(),
        _budgetDbService.getTotalYearlyBudgetProgress(
          currentFamilyId,
          now.year,
          'income',
        ),
        _budgetDbService.getTotalYearlyBudgetProgress(
          currentFamilyId,
          now.year,
          'expense',
        ),
        _budgetDbService.getTotalMonthlyBudgetProgress(
          currentFamilyId,
          now.year,
          now.month,
          'income',
        ),
        _budgetDbService.getTotalMonthlyBudgetProgress(
          currentFamilyId,
          now.year,
          now.month,
          'expense',
        ),
      ]);

      _statistics = HomeStatistics(
        transactionStats: results[0],
        yearlyIncomeBudget: results[1],
        yearlyExpenseBudget: results[2],
        monthlyIncomeBudget: results[3],
        monthlyExpenseBudget: results[4],
      );

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.e('加载首页统计数据失败', error: e, stackTrace: stackTrace);
      _isLoading = false;
      _errorMessage = '加载数据失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 刷新统计数据
  Future<void> refresh({int? familyId}) async {
    await loadStatistics(familyId: familyId);
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
