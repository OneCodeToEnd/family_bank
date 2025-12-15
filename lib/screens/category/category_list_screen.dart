import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';
import 'category_form_screen.dart';

/// 分类管理页面
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  String _selectedType = 'expense'; // expense, income
  bool _showHidden = false;
  final Set<int> _expandedCategories = {}; // 展开的分类ID

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            icon: Icon(_showHidden ? Icons.visibility_off : Icons.visibility),
            tooltip: _showHidden ? '隐藏已隐藏分类' : '显示已隐藏分类',
            onPressed: () {
              setState(() {
                _showHidden = !_showHidden;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 类型切换
          _buildTypeSelector(),

          // 分类列表
          Expanded(
            child: _buildCategoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddCategory(),
        icon: const Icon(Icons.add),
        label: const Text('添加分类'),
      ),
    );
  }

  /// 类型选择器
  Widget _buildTypeSelector() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('支出分类'),
                    ],
                  ),
                ),
                selected: _selectedType == 'expense',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = 'expense';
                      _expandedCategories.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('收入分类'),
                    ],
                  ),
                ),
                selected: _selectedType == 'income',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedType = 'income';
                      _expandedCategories.clear();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分类列表
  Widget _buildCategoryList() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('错误: ${provider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // 获取顶级分类
        final topCategories = provider
            .getTopLevelCategories(type: _selectedType)
            .where((c) => _showHidden || !c.isHidden)
            .toList();

        if (topCategories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('还没有${_selectedType == 'expense' ? '支出' : '收入'}分类'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToAddCategory(),
                  icon: const Icon(Icons.add),
                  label: const Text('添加分类'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: topCategories.length,
          itemBuilder: (context, index) {
            return _buildCategoryTree(topCategories[index], provider, 0);
          },
        );
      },
    );
  }

  /// 构建分类树节点
  Widget _buildCategoryTree(Category category, CategoryProvider provider, int level) {
    final isExpanded = _expandedCategories.contains(category.id);
    final subCategories = provider.getSubCategories(category.id!)
        .where((c) => _showHidden || !c.isHidden)
        .toList();
    final hasChildren = subCategories.isNotEmpty;

    return Column(
      children: [
        // 当前分类
        Card(
          margin: EdgeInsets.only(
            left: level * 16.0,
            right: 0,
            top: 4,
            bottom: 4,
          ),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 展开/折叠图标
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(category.id);
                        } else {
                          _expandedCategories.add(category.id!);
                        }
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 8),
                // 分类图标
                CircleAvatar(
                  backgroundColor: _getCategoryColor(category.type).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.category,
                    color: _getCategoryColor(category.type),
                    size: 20,
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(category.name),
                if (category.isSystem)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '系统',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  ),
                if (category.isHidden)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.visibility_off, size: 16, color: Colors.grey),
                  ),
              ],
            ),
            subtitle: category.tags.isNotEmpty
                ? Text(category.tags.join(', '), style: const TextStyle(fontSize: 12))
                : null,
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, category, provider),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('编辑'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_visibility',
                  child: Row(
                    children: [
                      Icon(category.isHidden ? Icons.visibility : Icons.visibility_off),
                      const SizedBox(width: 8),
                      Text(category.isHidden ? '显示' : '隐藏'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_child',
                  child: const Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('添加子分类'),
                    ],
                  ),
                ),
                if (!category.isSystem)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
            onTap: () => _navigateToEditCategory(category),
          ),
        ),
        // 子分类
        if (isExpanded && hasChildren)
          ...subCategories.map((subCategory) =>
              _buildCategoryTree(subCategory, provider, level + 1)),
      ],
    );
  }

  /// 获取分类颜色
  Color _getCategoryColor(String type) {
    return type == 'income' ? Colors.green : Colors.red;
  }

  /// 处理菜单操作
  void _handleMenuAction(String action, Category category, CategoryProvider provider) async {
    switch (action) {
      case 'edit':
        _navigateToEditCategory(category);
        break;
      case 'toggle_visibility':
        await provider.toggleCategoryVisibility(category.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(category.isHidden ? '分类已显示' : '分类已隐藏'),
            ),
          );
        }
        break;
      case 'add_child':
        _navigateToAddCategory(parentCategory: category);
        break;
      case 'delete':
        _confirmDelete(category, provider);
        break;
    }
  }

  /// 确认删除
  void _confirmDelete(Category category, CategoryProvider provider) {
    // 检查是否有子分类
    final hasChildren = provider.getSubCategories(category.id!).isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除分类"${category.name}"吗？'),
            if (hasChildren) ...[
              const SizedBox(height: 12),
              const Text(
                '警告：此分类下有子分类，删除后所有子分类也会被删除。',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '此操作会将使用此分类的账单设为"未分类"，且无法恢复。',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteCategory(category.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '分类已删除' : '删除失败'),
                    backgroundColor: success ? null : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 跳转到添加分类
  void _navigateToAddCategory({Category? parentCategory}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(
          type: _selectedType,
          parentCategory: parentCategory,
        ),
      ),
    );
  }

  /// 跳转到编辑分类
  void _navigateToEditCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(
          category: category,
        ),
      ),
    );
  }
}
