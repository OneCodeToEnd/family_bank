import 'package:flutter/foundation.dart';
import '../models/annual_budget.dart';
import '../services/database/annual_budget_db_service.dart';
import '../services/budget_alert_service.dart';

/// 预算状态管理
class BudgetProvider with ChangeNotifier {
  final AnnualBudgetDbService _dbService = AnnualBudgetDbService();
  final BudgetAlertService _alertService = BudgetAlertService();

  // 状态数据
  List<AnnualBudget> _budgets = [];
  int _currentYear = DateTime.now().year;
  int _currentFamilyId = 1; // TODO: 从 FamilyProvider 获取当前家庭ID
  List<Map<String, dynamic>> _monthlyStats = [];

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<AnnualBudget> get budgets => _budgets;
  List<AnnualBudget> get expenseBudgets => _budgets.where((b) => b.type == 'expense').toList();
  List<AnnualBudget> get incomeBudgets => _budgets.where((b) => b.type == 'income').toList();
  int get currentYear => _currentYear;
  int get currentFamilyId => _currentFamilyId;
  List<Map<String, dynamic>> get monthlyStats => _monthlyStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== 初始化 ====================

  /// 初始化，加载当前年度预算和月度统计
  Future<void> initialize() async {
    await loadBudgets();
    await loadMonthlyStats();
  }

  // ==================== 预算操作 ====================

  /// 加载当前年度的预算
  Future<void> loadBudgets() async {
    _setLoading(true);
    try {
      _budgets = await _dbService.getAnnualBudgetsByYear(_currentFamilyId, _currentYear);
      _clearError();
    } catch (e) {
      _setError('加载预算失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建年度预算
  Future<bool> createAnnualBudget(int categoryId, double annualAmount, String type) async {
    _setLoading(true);
    try {
      // 检查预算是否已存在
      final exists = await _dbService.budgetExists(_currentFamilyId, categoryId, _currentYear);
      if (exists) {
        _setError('该分类的年度预算已存在');
        return false;
      }

      // 创建预算
      final budget = AnnualBudget.fromAnnualAmount(
        familyId: _currentFamilyId,
        categoryId: categoryId,
        year: _currentYear,
        type: type,
        annualAmount: annualAmount,
      );

      await _dbService.createAnnualBudget(budget);

      // 重新加载数据
      await loadBudgets();
      await loadMonthlyStats();

      _clearError();
      return true;
    } catch (e) {
      _setError('创建预算失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新年度预算
  Future<bool> updateAnnualBudget(AnnualBudget budget, double newAnnualAmount) async {
    _setLoading(true);
    try {
      // 更新预算金额（自动重新计算月度金额）
      final updatedBudget = budget.copyWith(
        annualAmount: newAnnualAmount,
        monthlyAmount: newAnnualAmount / 12,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateAnnualBudget(updatedBudget);

      // 重新加载数据
      await loadBudgets();
      await loadMonthlyStats();

      _clearError();
      return true;
    } catch (e) {
      _setError('更新预算失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除年度预算
  Future<bool> deleteAnnualBudget(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteAnnualBudget(id);

      // 重新加载数据
      await loadBudgets();
      await loadMonthlyStats();

      _clearError();
      return true;
    } catch (e) {
      _setError('删除预算失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== 统计操作 ====================

  /// 加载当月预算统计
  Future<void> loadMonthlyStats() async {
    try {
      final now = DateTime.now();
      _monthlyStats = await _dbService.getAllMonthlyStats(
        _currentFamilyId,
        _currentYear,
        now.month,
      );
      _clearError();
    } catch (e) {
      _setError('加载月度统计失败: $e');
    }
  }

  /// 获取指定分类的预算进度
  Future<Map<String, dynamic>?> getBudgetProgress(int categoryId) async {
    try {
      final now = DateTime.now();
      final stats = await _dbService.getMonthlyBudgetStats(
        _currentFamilyId,
        categoryId,
        _currentYear,
        now.month,
      );
      return stats;
    } catch (e) {
      _setError('获取预算进度失败: $e');
      return null;
    }
  }

  /// 检查预算提醒（需要 BuildContext）
  Future<void> checkBudgetAlerts(dynamic context) async {
    final now = DateTime.now();
    await _alertService.checkBudgetAlerts(
      context,
      _currentFamilyId,
      _currentYear,
      now.month,
    );
  }

  // ==================== 年份导航 ====================

  /// 设置当前年份
  void setYear(int year) {
    if (_currentYear != year) {
      _currentYear = year;
      notifyListeners();
      loadBudgets();
      loadMonthlyStats();
    }
  }

  /// 切换到下一年
  void nextYear() {
    setYear(_currentYear + 1);
  }

  /// 切换到上一年
  void previousYear() {
    setYear(_currentYear - 1);
  }

  /// 设置当前家庭ID
  void setFamilyId(int familyId) {
    if (_currentFamilyId != familyId) {
      _currentFamilyId = familyId;
      notifyListeners();
      loadBudgets();
      loadMonthlyStats();
    }
  }

  // ==================== 辅助方法 ====================

  /// 设置加载状态
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
  }
}
