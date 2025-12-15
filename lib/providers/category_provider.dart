import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../services/database/category_db_service.dart';

/// 分类状态管理
class CategoryProvider with ChangeNotifier {
  final CategoryDbService _dbService = CategoryDbService();

  // 状态数据
  List<Category> _categories = [];
  List<Map<String, dynamic>> _categoryTree = [];
  Category? _currentCategory;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Category> get categories => _categories;
  List<Category> get visibleCategories => _categories.where((c) => !c.isHidden).toList();
  List<Map<String, dynamic>> get categoryTree => _categoryTree;
  Category? get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取收入分类
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'income' && !c.isHidden).toList();

  /// 获取支出分类
  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'expense' && !c.isHidden).toList();

  // ==================== 初始化 ====================

  /// 初始化，加载所有分类
  Future<void> initialize() async {
    await loadCategories();
    await loadCategoryTree();
  }

  // ==================== 分类操作 ====================

  /// 加载所有分类
  Future<void> loadCategories() async {
    _setLoading(true);
    try {
      _categories = await _dbService.getAllCategories();
      _clearError();
    } catch (e) {
      _setError('加载分类失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载分类树
  Future<void> loadCategoryTree({String? type}) async {
    _setLoading(true);
    try {
      _categoryTree = await _dbService.getCategoryTree(type: type);
      _clearError();
    } catch (e) {
      _setError('加载分类树失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 根据类型加载分类
  Future<void> loadCategoriesByType(String type) async {
    _setLoading(true);
    try {
      _categories = await _dbService.getCategoriesByType(type);
      _clearError();
    } catch (e) {
      _setError('加载分类失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建分类
  Future<bool> createCategory({
    int? parentId,
    required String name,
    required String type,
    String? icon,
    String? color,
    List<String>? tags,
  }) async {
    _setLoading(true);
    try {
      // 检查分类名是否已存在
      final exists = await _dbService.isCategoryNameExists(name, type, parentId: parentId);
      if (exists) {
        _setError('分类名称已存在');
        return false;
      }

      final category = Category(
        parentId: parentId,
        name: name,
        type: type,
        icon: icon,
        color: color,
        tags: tags ?? [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final id = await _dbService.createCategory(category);

      // 重新加载分类
      await loadCategories();
      await loadCategoryTree();

      // 设置为当前分类
      _currentCategory = _categories.firstWhere((c) => c.id == id);

      _clearError();
      return true;
    } catch (e) {
      _setError('创建分类失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新分类
  Future<bool> updateCategory(Category category) async {
    _setLoading(true);
    try {
      // 检查分类名是否与其他分类重复
      final exists = await _dbService.isCategoryNameExists(
        category.name,
        category.type,
        parentId: category.parentId,
        excludeId: category.id,
      );
      if (exists) {
        _setError('分类名称已存在');
        return false;
      }

      await _dbService.updateCategory(category);
      await loadCategories();
      await loadCategoryTree();

      // 如果是当前分类，更新引用
      if (_currentCategory?.id == category.id) {
        _currentCategory = _categories.firstWhere((c) => c.id == category.id);
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('更新分类失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除分类
  Future<bool> deleteCategory(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteCategory(id);
      await loadCategories();
      await loadCategoryTree();

      // 如果删除的是当前分类，清空
      if (_currentCategory?.id == id) {
        _currentCategory = null;
      }

      _clearError();
      return true;
    } catch (e) {
      _setError('删除分类失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换分类隐藏状态
  Future<bool> toggleCategoryVisibility(int id) async {
    _setLoading(true);
    try {
      final category = _categories.firstWhere((c) => c.id == id);
      await _dbService.toggleCategoryVisibility(id, !category.isHidden);
      await loadCategories();
      await loadCategoryTree();
      _clearError();
      return true;
    } catch (e) {
      _setError('操作失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 切换当前分类
  void setCurrentCategory(Category category) {
    _currentCategory = category;
    notifyListeners();
  }

  /// 根据ID获取分类
  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取一级分类
  List<Category> getTopLevelCategories({String? type}) {
    var result = _categories.where((c) => c.parentId == null && !c.isHidden);
    if (type != null) {
      result = result.where((c) => c.type == type);
    }
    return result.toList();
  }

  /// 获取子分类
  List<Category> getSubCategories(int parentId) {
    return _categories.where((c) => c.parentId == parentId && !c.isHidden).toList();
  }

  /// 搜索分类
  Future<List<Category>> searchCategories(String keyword) async {
    try {
      return await _dbService.searchCategoriesByName(keyword);
    } catch (e) {
      _setError('搜索失败: $e');
      return [];
    }
  }

  /// 获取分类统计信息
  Future<Map<String, dynamic>?> getCategoryStatistics(int categoryId) async {
    try {
      return await _dbService.getCategoryStatistics(categoryId);
    } catch (e) {
      _setError('获取统计信息失败: $e');
      return null;
    }
  }

  /// 智能推荐分类
  Future<List<Category>> suggestCategories(String description, String type) async {
    try {
      // 简单的关键词匹配推荐
      final keywords = description.toLowerCase();

      // 获取该类型下的所有可见分类
      final candidates = _categories
          .where((c) => c.type == type && !c.isHidden)
          .toList();

      // 根据分类名称匹配度排序
      final scored = <MapEntry<Category, int>>[];

      for (var category in candidates) {
        int score = 0;
        final categoryName = category.name.toLowerCase();

        // 完全匹配
        if (keywords.contains(categoryName)) {
          score += 100;
        }
        // 部分匹配
        else if (categoryName.contains(keywords) || keywords.contains(categoryName)) {
          score += 50;
        }
        // 任意字符匹配
        else {
          for (var char in categoryName.runes) {
            if (keywords.codeUnits.contains(char)) {
              score += 1;
            }
          }
        }

        if (score > 0) {
          scored.add(MapEntry(category, score));
        }
      }

      // 按分数降序排序
      scored.sort((a, b) => b.value.compareTo(a.value));

      // 返回前5个
      return scored.take(5).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('智能推荐失败: $e');
      return [];
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
