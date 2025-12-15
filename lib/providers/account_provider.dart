import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/database/account_db_service.dart';

/// 账户状态管理
class AccountProvider with ChangeNotifier {
  final AccountDbService _dbService = AccountDbService();

  // 状态数据
  List<Account> _accounts = [];
  Account? _currentAccount;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Account> get accounts => _accounts;
  List<Account> get visibleAccounts => _accounts.where((a) => !a.isHidden).toList();
  Account? get currentAccount => _currentAccount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==================== 初始化 ====================

  /// 初始化，加载所有账户
  Future<void> initialize() async {
    await loadAccounts();
  }

  // ==================== 账户操作 ====================

  /// 加载所有账户
  Future<void> loadAccounts() async {
    _setLoading(true);
    try {
      _accounts = await _dbService.getAllAccounts();
      _clearError();
    } catch (e) {
      _setError('加载账户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载可见账户
  Future<void> loadVisibleAccounts() async {
    _setLoading(true);
    try {
      _accounts = await _dbService.getVisibleAccounts();
      _clearError();
    } catch (e) {
      _setError('加载账户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根据成员ID加载账户
  Future<void> loadAccountsByMemberId(int memberId) async {
    _setLoading(true);
    try {
      _accounts = await _dbService.getAccountsByMemberId(memberId);
      _clearError();
    } catch (e) {
      _setError('加载账户失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建账户
  Future<bool> createAccount({
    required int familyMemberId,
    required String name,
    required String type,
    String? icon,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      // 检查账户名是否已存在
      final exists = await _dbService.isAccountNameExists(familyMemberId, name);
      if (exists) {
        _setError('账户名称已存在');
        return false;
      }

      final account = Account(
        familyMemberId: familyMemberId,
        name: name,
        type: type,
        icon: icon,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _dbService.createAccount(account);

      // 重新加载账户列表
      await loadAccounts();

      // 设置为当前账户
      _currentAccount = _accounts.firstWhere((a) => a.id == id);

      _clearError();
      return true;
    } catch (e) {
      _setError('创建账户失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新账户
  Future<bool> updateAccount(Account account) async {
    _setLoading(true);
    try {
      // 检查账户名是否与其他账户重复
      final exists = await _dbService.isAccountNameExists(
        account.familyMemberId,
        account.name,
        excludeId: account.id,
      );
      if (exists) {
        _setError('账户名称已存在');
        return false;
      }

      await _dbService.updateAccount(account);
      await loadAccounts();

      // 如果是当前账户，更新引用
      if (_currentAccount?.id == account.id) {
        _currentAccount = _accounts.firstWhere((a) => a.id == account.id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('更新账户失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除账户
  Future<bool> deleteAccount(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteAccount(id);
      await loadAccounts();

      // 如果删除的是当前账户，清空
      if (_currentAccount?.id == id) {
        _currentAccount = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('删除账户失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换账户隐藏状态
  Future<bool> toggleAccountVisibility(int id) async {
    _setLoading(true);
    try {
      final account = _accounts.firstWhere((a) => a.id == id);
      await _dbService.toggleAccountVisibility(id, !account.isHidden);
      await loadAccounts();
      _clearError();
      return true;
    } catch (e) {
      _setError('操作失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换当前账户
  void setCurrentAccount(Account account) {
    _currentAccount = account;
    notifyListeners();
  }

  /// 根据ID获取账户
  Account? getAccountById(int id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 根据类型获取账户列表
  List<Account> getAccountsByType(String type) {
    return _accounts.where((a) => a.type == type).toList();
  }

  /// 获取账户统计信息
  Future<Map<String, dynamic>?> getAccountStatistics(int accountId) async {
    try {
      return await _dbService.getAccountStatistics(accountId);
    } catch (e) {
      _setError('获取统计信息失败: $e');
      return null;
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
}
