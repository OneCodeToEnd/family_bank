import 'package:flutter/foundation.dart';
import '../models/counterparty_group.dart';
import '../models/counterparty_suggestion.dart';
import '../services/database/counterparty_group_db_service.dart';
import '../services/counterparty/counterparty_matching_service.dart';
import '../utils/app_logger.dart';

/// 对手方分组状态管理
class CounterpartyProvider with ChangeNotifier {
  final CounterpartyGroupDbService _dbService = CounterpartyGroupDbService();
  final CounterpartyMatchingService _matchingService = CounterpartyMatchingService();

  // 状态数据
  List<CounterpartyGroup> _groups = [];
  List<CounterpartySuggestion> _suggestions = [];
  Map<String, int> _groupStatistics = {}; // 主对手方 -> 子对手方数量

  // 加载状态
  bool _isLoading = false;
  bool _isGeneratingSuggestions = false;
  String? _errorMessage;

  // Getters
  List<CounterpartyGroup> get groups => _groups;
  List<CounterpartySuggestion> get suggestions => _suggestions;
  Map<String, int> get groupStatistics => _groupStatistics;
  bool get isLoading => _isLoading;
  bool get isGeneratingSuggestions => _isGeneratingSuggestions;
  String? get errorMessage => _errorMessage;

  /// 获取所有主对手方列表（去重）
  List<String> get mainCounterparties {
    final Set<String> mains = {};
    for (var group in _groups) {
      mains.add(group.mainCounterparty);
    }
    return mains.toList()..sort();
  }

  /// 获取未读建议数量
  int get unreadSuggestionsCount => _suggestions.length;

  // ==================== 初始化 ====================

  /// 初始化，加载所有分组
  Future<void> initialize() async {
    await loadGroups();
    await loadGroupStatistics();
  }

  // ==================== 分组操作 ====================

  /// 加载所有分组
  Future<void> loadGroups() async {
    _setLoading(true);
    try {
      _groups = await _dbService.getAllGroups();
      _clearError();
      AppLogger.d('[CounterpartyProvider] 加载 ${_groups.length} 个分组');
    } catch (e) {
      _setError('加载分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 加载分组失败', error: e);
    } finally {
      _setLoading(false);
    }
  }

  /// 加载分组统计信息
  Future<void> loadGroupStatistics() async {
    try {
      _groupStatistics = await _dbService.getGroupStatistics();
      notifyListeners();
    } catch (e) {
      AppLogger.e('[CounterpartyProvider] 加载统计信息失败', error: e);
    }
  }

  /// 创建分组
  Future<bool> createGroup({
    required String mainCounterparty,
    required String subCounterparty,
    bool autoCreated = false,
    double confidenceScore = 1.0,
  }) async {
    _setLoading(true);
    try {
      // 检查子对手方是否已分组
      final isGrouped = await _dbService.isSubCounterpartyGrouped(subCounterparty);
      if (isGrouped) {
        _setError('该对手方已在其他分组中');
        return false;
      }

      final group = CounterpartyGroup(
        mainCounterparty: mainCounterparty,
        subCounterparty: subCounterparty,
        autoCreated: autoCreated,
        confidenceScore: confidenceScore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.createGroup(group);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 创建分组: $mainCounterparty -> $subCounterparty');
      return true;
    } catch (e) {
      _setError('创建分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 创建分组失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量创建分组
  Future<bool> createGroupsBatch(List<CounterpartyGroup> groups) async {
    _setLoading(true);
    try {
      await _dbService.batchCreateGroups(groups);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 批量创建 ${groups.length} 个分组');
      return true;
    } catch (e) {
      _setError('批量创建分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 批量创建分组失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新分组
  Future<bool> updateGroup(CounterpartyGroup group) async {
    _setLoading(true);
    try {
      await _dbService.updateGroup(group);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 更新分组: ID=${group.id}');
      return true;
    } catch (e) {
      _setError('更新分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 更新分组失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除分组
  Future<bool> deleteGroup(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteGroup(id);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 删除分组: ID=$id');
      return true;
    } catch (e) {
      _setError('删除分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 删除分组失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除主对手方的所有分组
  Future<bool> deleteMainCounterparty(String mainCounterparty) async {
    _setLoading(true);
    try {
      await _dbService.deleteGroupsByMainCounterparty(mainCounterparty);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 删除主对手方: $mainCounterparty');
      return true;
    } catch (e) {
      _setError('删除主对手方失败: $e');
      AppLogger.e('[CounterpartyProvider] 删除主对手方失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 解除子对手方的分组关联
  Future<bool> removeSubFromGroup(String subCounterparty) async {
    _setLoading(true);
    try {
      await _dbService.removeSubFromGroup(subCounterparty);
      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 解除分组: $subCounterparty');
      return true;
    } catch (e) {
      _setError('解除分组失败: $e');
      AppLogger.e('[CounterpartyProvider] 解除分组失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== 智能建议 ====================

  /// 生成智能分组建议（使用 LLM）
  Future<void> generateSuggestions() async {
    _isGeneratingSuggestions = true;
    notifyListeners();

    try {
      _suggestions = await _matchingService.generateSuggestionsWithAI();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 生成 ${_suggestions.length} 个建议');
    } catch (e) {
      _setError('生成建议失败: $e');
      AppLogger.e('[CounterpartyProvider] 生成建议失败', error: e);
    } finally {
      _isGeneratingSuggestions = false;
      notifyListeners();
    }
  }

  /// 应用建议
  Future<bool> applySuggestion(CounterpartySuggestion suggestion) async {
    _setLoading(true);
    try {
      // 创建分组
      final groups = suggestion.subCounterparties.map((sub) {
        return CounterpartyGroup(
          mainCounterparty: suggestion.mainCounterparty,
          subCounterparty: sub,
          autoCreated: true,
          confidenceScore: suggestion.confidenceScore,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      await _dbService.batchCreateGroups(groups);

      // 从建议列表中移除
      _suggestions.remove(suggestion);

      await loadGroups();
      await loadGroupStatistics();
      _clearError();
      AppLogger.i('[CounterpartyProvider] 应用建议: ${suggestion.mainCounterparty}');
      return true;
    } catch (e) {
      _setError('应用建议失败: $e');
      AppLogger.e('[CounterpartyProvider] 应用建议失败', error: e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 忽略建议
  void ignoreSuggestion(CounterpartySuggestion suggestion) {
    _suggestions.remove(suggestion);
    notifyListeners();
    AppLogger.d('[CounterpartyProvider] 忽略建议: ${suggestion.mainCounterparty}');
  }

  /// 清空所有建议
  void clearSuggestions() {
    _suggestions.clear();
    notifyListeners();
    AppLogger.d('[CounterpartyProvider] 清空所有建议');
  }

  // ==================== 查询方法 ====================

  /// 根据主对手方获取所有子对手方
  Future<List<String>> getSubCounterparties(String mainCounterparty) async {
    try {
      return await _dbService.getSubCounterparties(mainCounterparty);
    } catch (e) {
      AppLogger.e('[CounterpartyProvider] 获取子对手方失败', error: e);
      return [];
    }
  }

  /// 根据子对手方查找主对手方
  Future<String?> getMainCounterparty(String subCounterparty) async {
    try {
      return await _dbService.getMainCounterparty(subCounterparty);
    } catch (e) {
      AppLogger.e('[CounterpartyProvider] 查找主对手方失败', error: e);
      return null;
    }
  }

  /// 检查子对手方是否已分组
  Future<bool> isSubCounterpartyGrouped(String subCounterparty) async {
    try {
      return await _dbService.isSubCounterpartyGrouped(subCounterparty);
    } catch (e) {
      AppLogger.e('[CounterpartyProvider] 检查分组状态失败', error: e);
      return false;
    }
  }

  /// 根据主对手方获取分组列表
  List<CounterpartyGroup> getGroupsByMainCounterparty(String mainCounterparty) {
    return _groups.where((g) => g.mainCounterparty == mainCounterparty).toList();
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

  /// 清除错误信息
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
