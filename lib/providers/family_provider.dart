import 'package:flutter/foundation.dart';
import '../models/family_group.dart';
import '../models/family_member.dart';
import '../services/database/family_db_service.dart';

/// 家庭组和成员状态管理
class FamilyProvider with ChangeNotifier {
  final FamilyDbService _dbService = FamilyDbService();

  // 状态数据
  List<FamilyGroup> _familyGroups = [];
  List<FamilyMember> _familyMembers = [];
  FamilyGroup? _currentFamilyGroup;
  FamilyMember? _currentFamilyMember;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<FamilyGroup> get familyGroups => _familyGroups;
  List<FamilyMember> get familyMembers => _familyMembers;
  FamilyGroup? get currentFamilyGroup => _currentFamilyGroup;
  FamilyMember? get currentFamilyMember => _currentFamilyMember;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取当前家庭组的成员列表
  List<FamilyMember> get currentGroupMembers {
    if (_currentFamilyGroup == null) return [];
    return _familyMembers
        .where((m) => m.familyGroupId == _currentFamilyGroup!.id)
        .toList();
  }

  // ==================== 初始化 ====================

  /// 初始化，加载所有数据
  Future<void> initialize() async {
    await loadFamilyGroups();
    await loadFamilyMembers();

    // 如果有家庭组，默认选择第一个
    if (_familyGroups.isNotEmpty) {
      _currentFamilyGroup = _familyGroups.first;
      notifyListeners();
    }
  }

  // ==================== 家庭组操作 ====================

  /// 加载所有家庭组
  Future<void> loadFamilyGroups() async {
    _setLoading(true);
    try {
      _familyGroups = await _dbService.getAllFamilyGroups();
      _clearError();
    } catch (e) {
      _setError('加载家庭组失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建家庭组
  Future<bool> createFamilyGroup(String name, {String? description}) async {
    _setLoading(true);
    try {
      final group = FamilyGroup(
        name: name,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _dbService.createFamilyGroup(group);

      // 重新加载列表
      await loadFamilyGroups();

      // 设置为当前家庭组
      _currentFamilyGroup = _familyGroups.firstWhere((g) => g.id == id);

      _clearError();
      return true;
    } catch (e) {
      _setError('创建家庭组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新家庭组
  Future<bool> updateFamilyGroup(FamilyGroup group) async {
    _setLoading(true);
    try {
      await _dbService.updateFamilyGroup(group);
      await loadFamilyGroups();

      // 如果是当前家庭组，更新引用
      if (_currentFamilyGroup?.id == group.id) {
        _currentFamilyGroup = _familyGroups.firstWhere((g) => g.id == group.id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('更新家庭组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除家庭组
  Future<bool> deleteFamilyGroup(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteFamilyGroup(id);
      await loadFamilyGroups();

      // 如果删除的是当前家庭组，切换到第一个
      if (_currentFamilyGroup?.id == id) {
        _currentFamilyGroup = _familyGroups.isNotEmpty ? _familyGroups.first : null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('删除家庭组失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换当前家庭组
  void setCurrentFamilyGroup(FamilyGroup group) {
    _currentFamilyGroup = group;
    notifyListeners();
  }

  // ==================== 家庭成员操作 ====================

  /// 加载所有家庭成员
  Future<void> loadFamilyMembers() async {
    _setLoading(true);
    try {
      _familyMembers = await _dbService.getAllFamilyMembers();
      _clearError();
    } catch (e) {
      _setError('加载家庭成员失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载指定家庭组的成员
  Future<void> loadMembersByGroupId(int groupId) async {
    _setLoading(true);
    try {
      final members = await _dbService.getMembersByGroupId(groupId);
      // 更新当前组的成员
      _familyMembers.removeWhere((m) => m.familyGroupId == groupId);
      _familyMembers.addAll(members);
      _clearError();
    } catch (e) {
      _setError('加载成员失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建家庭成员
  Future<bool> createFamilyMember({
    required int familyGroupId,
    required String name,
    String? avatar,
    String? role,
  }) async {
    _setLoading(true);
    try {
      final member = FamilyMember(
        familyGroupId: familyGroupId,
        name: name,
        avatar: avatar,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _dbService.createFamilyMember(member);

      // 重新加载成员列表
      await loadMembersByGroupId(familyGroupId);

      // 如果是当前家庭组，设置为当前成员
      if (_currentFamilyGroup?.id == familyGroupId) {
        _currentFamilyMember = _familyMembers.firstWhere((m) => m.id == id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('创建成员失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新家庭成员
  Future<bool> updateFamilyMember(FamilyMember member) async {
    _setLoading(true);
    try {
      await _dbService.updateFamilyMember(member);
      await loadMembersByGroupId(member.familyGroupId);

      // 如果是当前成员，更新引用
      if (_currentFamilyMember?.id == member.id) {
        _currentFamilyMember = _familyMembers.firstWhere((m) => m.id == member.id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('更新成员失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除家庭成员
  Future<bool> deleteFamilyMember(int id) async {
    _setLoading(true);
    try {
      final member = _familyMembers.firstWhere((m) => m.id == id);
      await _dbService.deleteFamilyMember(id);
      await loadMembersByGroupId(member.familyGroupId);

      // 如果删除的是当前成员，清空
      if (_currentFamilyMember?.id == id) {
        _currentFamilyMember = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('删除成员失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换当前成员
  void setCurrentFamilyMember(FamilyMember member) {
    _currentFamilyMember = member;
    notifyListeners();
  }

  /// 根据ID获取成员
  FamilyMember? getMemberById(int id) {
    try {
      return _familyMembers.firstWhere((m) => m.id == id);
    } catch (e) {
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
