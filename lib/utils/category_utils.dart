import '../models/category.dart';
import '../providers/category_provider.dart';

/// 分类工具类
///
/// 提供分类相关的通用工具方法，避免代码重复
class CategoryUtils {
  /// 获取分类的完整路径（父分类 > 子分类）
  ///
  /// 示例: "生活 > 餐饮 > 午餐"
  ///
  /// [category] 要获取路径的分类
  /// [provider] 分类提供者，用于查询父分类
  ///
  /// 返回完整的分类路径字符串
  static String getCategoryPath(
    Category category,
    CategoryProvider provider,
  ) {
    final path = <String>[];
    Category? current = category;
    final visited = <int>{};  // 防止循环引用

    while (current != null) {
      // 检测循环引用
      if (visited.contains(current.id)) {
        break;
      }
      visited.add(current.id!);

      path.insert(0, current.name);

      if (current.parentId != null) {
        current = provider.getCategoryById(current.parentId!);
      } else {
        current = null;
      }
    }

    return path.join(' > ');
  }

  /// 获取叶子分类（没有子分类的分类）
  ///
  /// [categories] 所有分类列表
  /// [type] 分类类型（'income' 或 'expense'）
  ///
  /// 返回指定类型的叶子分类列表
  static List<Category> getLeafCategories(
    List<Category> categories,
    String type,
  ) {
    return categories
        .where((c) => c.type == type)
        .where((c) => !categories.any((other) => other.parentId == c.id))
        .toList();
  }
}
