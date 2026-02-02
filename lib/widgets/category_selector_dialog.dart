import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/category_utils.dart';

/// 分类选择对话框
///
/// 可复用的分类选择组件，支持：
/// - 按交易类型筛选（收入/支出）
/// - 只显示叶子分类
/// - 显示完整层级路径
/// - 支持"未分类"选项
/// - 显示当前选中状态
class CategorySelectorDialog extends StatelessWidget {
  final String transactionType;  // 'income' or 'expense'
  final int? currentCategoryId;
  final bool showUncategorized;  // 是否显示"未分类"选项

  const CategorySelectorDialog({
    super.key,
    required this.transactionType,
    this.currentCategoryId,
    this.showUncategorized = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        // 获取叶子分类
        final leafCategories = CategoryUtils.getLeafCategories(
          categoryProvider.visibleCategories,
          transactionType,
        );

        return SimpleDialog(
          title: const Text('选择分类'),
          children: [
            // "未分类"选项
            if (showUncategorized)
              SimpleDialogOption(
                child: Row(
                  children: [
                    if (currentCategoryId == null)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('未分类'),
                  ],
                ),
                onPressed: () => Navigator.pop(context, null),
              ),

            // 分类列表
            ...leafCategories.map((category) {
              final displayName = CategoryUtils.getCategoryPath(
                category,
                categoryProvider,
              );
              final isSelected = category.id == currentCategoryId;

              return SimpleDialogOption(
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(displayName)),
                  ],
                ),
                onPressed: () => Navigator.pop(context, category),
              );
            }),
          ],
        );
      },
    );
  }
}

/// 便捷方法：显示分类选择对话框
///
/// [context] 构建上下文
/// [transactionType] 交易类型（'income' 或 'expense'）
/// [currentCategoryId] 当前选中的分类ID
/// [showUncategorized] 是否显示"未分类"选项
///
/// 返回用户选择的分类，如果取消则返回 null
Future<Category?> showCategorySelectorDialog(
  BuildContext context, {
  required String transactionType,
  int? currentCategoryId,
  bool showUncategorized = true,
}) {
  return showDialog<Category?>(
    context: context,
    builder: (context) => CategorySelectorDialog(
      transactionType: transactionType,
      currentCategoryId: currentCategoryId,
      showUncategorized: showUncategorized,
    ),
  );
}
