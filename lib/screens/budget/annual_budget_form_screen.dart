import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../models/category.dart';
import '../../utils/category_icon_utils.dart';

/// 年度预算设置页面
class AnnualBudgetFormScreen extends StatefulWidget {
  const AnnualBudgetFormScreen({super.key});

  @override
  State<AnnualBudgetFormScreen> createState() => _AnnualBudgetFormScreenState();
}

class _AnnualBudgetFormScreenState extends State<AnnualBudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _amountControllers = {};
  final Map<int, bool> _selectedCategories = {};
  final Set<int> _expandedCategoryIds = {}; // 展开的父分类ID集合
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    await context.read<CategoryProvider>().loadCategories();
    // 默认展开所有一级分类
    _expandAllTopLevel();
  }

  /// 展开所有一级分类
  void _expandAllTopLevel() {
    final categoryProvider = context.read<CategoryProvider>();
    for (var category in categoryProvider.visibleCategories) {
      if (category.parentId == null && _hasChildren(category, categoryProvider.visibleCategories)) {
        setState(() {
          _expandedCategoryIds.add(category.id!);
        });
      }
    }
  }

  /// 判断分类是否有子分类
  bool _hasChildren(Category category, List<Category> allCategories) {
    return allCategories.any((c) => c.parentId == category.id);
  }

  /// 获取子分类
  List<Category> _getChildren(Category parent, List<Category> allCategories) {
    return allCategories.where((c) => c.parentId == parent.id).toList();
  }

  @override
  void dispose() {
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('设置 ${budgetProvider.currentYear}年 预算'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 说明卡片
            Builder(
              builder: (context) {
                final appColors = context.appColors;
                return Card(
                  margin: const EdgeInsets.all(16),
                  color: appColors.infoContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: appColors.onInfoContainer),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '设置年度预算后，系统将自动计算月度预算（年度÷12）',
                            style: TextStyle(fontSize: 14, color: appColors.onInfoContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 分类树形列表
            Expanded(
              child: _buildCategoryTree(categoryProvider, budgetProvider),
            ),

            // 提交按钮
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分类树
  Widget _buildCategoryTree(CategoryProvider categoryProvider, BudgetProvider budgetProvider) {
    final categories = categoryProvider.visibleCategories;

    if (categories.isEmpty) {
      return const Center(
        child: Text('没有可用的分类'),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 支出分类树
        ..._buildCategoryTypeSection('expense', categoryProvider, budgetProvider),

        // 收入分类树
        ..._buildCategoryTypeSection('income', categoryProvider, budgetProvider),
      ],
    );
  }

  /// 构建分类类型区域（支出或收入）
  List<Widget> _buildCategoryTypeSection(
    String type,
    CategoryProvider categoryProvider,
    BudgetProvider budgetProvider,
  ) {
    final topLevelCategories = categoryProvider.visibleCategories
        .where((c) => c.parentId == null && c.type == type)
        .toList();

    if (topLevelCategories.isEmpty) {
      return [];
    }

    return [
      // 类型标题
      Padding(
        padding: EdgeInsets.fromLTRB(0, type == 'expense' ? 8 : 16, 0, 8),
        child: Row(
          children: [
            Icon(
              type == 'expense' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: type == 'expense' ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              type == 'expense' ? '支出预算' : '收入预算',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      // 顶级分类及其子分类
      ...topLevelCategories.expand((category) =>
        _buildCategoryWithChildren(category, 0, categoryProvider, budgetProvider)
      ),
    ];
  }

  /// 递归构建分类及其子分类
  List<Widget> _buildCategoryWithChildren(
    Category category,
    int level,
    CategoryProvider categoryProvider,
    BudgetProvider budgetProvider,
  ) {
    final hasChildren = _hasChildren(category, categoryProvider.visibleCategories);
    final isExpanded = _expandedCategoryIds.contains(category.id);
    final children = hasChildren ? _getChildren(category, categoryProvider.visibleCategories) : <Category>[];

    return [
      _buildCategoryItem(category, level, hasChildren, isExpanded, budgetProvider),
      // 如果展开且有子分类，递归显示子分类
      if (isExpanded && hasChildren)
        ...children.expand((child) =>
          _buildCategoryWithChildren(child, level + 1, categoryProvider, budgetProvider)
        ),
    ];
  }

  /// 构建分类项
  Widget _buildCategoryItem(
    Category category,
    int level,
    bool hasChildren,
    bool isExpanded,
    BudgetProvider budgetProvider,
  ) {
    // 检查是否已有预算
    final hasExistingBudget = budgetProvider.budgets.any((b) => b.categoryId == category.id);
    final existingBudget = hasExistingBudget
        ? budgetProvider.budgets.firstWhere((b) => b.categoryId == category.id)
        : null;

    // 初始化控制器
    if (!_amountControllers.containsKey(category.id)) {
      _amountControllers[category.id!] = TextEditingController(
        text: existingBudget != null ? existingBudget.annualAmount.toStringAsFixed(0) : '',
      );
      _selectedCategories[category.id!] = hasExistingBudget;
    }

    final controller = _amountControllers[category.id]!;
    final isSelected = _selectedCategories[category.id] ?? false;

    // 解析图标和颜色
    final iconData = CategoryIconUtils.getIconData(category.icon ?? 'category');
    final color = CategoryIconUtils.getColor(category.color);

    // 计算月度金额（包括汇总）
    double annualAmount = 0;
    double monthlyAmount = 0;
    bool isAggregated = false;

    if (controller.text.isNotEmpty) {
      try {
        annualAmount = double.parse(controller.text);
        monthlyAmount = annualAmount / 12;
      } catch (e) {
        annualAmount = 0;
        monthlyAmount = 0;
      }
    } else if (hasChildren) {
      // 如果父分类没有自己的预算，计算子分类的汇总
      final children = _getChildren(category, context.read<CategoryProvider>().visibleCategories);
      for (final child in children) {
        final childController = _amountControllers[child.id];
        if (childController != null && childController.text.isNotEmpty) {
          try {
            annualAmount += double.parse(childController.text);
          } catch (e) {
            // 忽略无效输入
          }
        }
      }
      if (annualAmount > 0) {
        monthlyAmount = annualAmount / 12;
        isAggregated = true;
      }
    }

    return Card(
      margin: EdgeInsets.only(bottom: 8, left: level * 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：展开按钮、复选框、图标、名称、汇总按钮
            Row(
              children: [
                // 展开/折叠按钮或占位
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategoryIds.remove(category.id);
                        } else {
                          _expandedCategoryIds.add(category.id!);
                        }
                      });
                    },
                  )
                else
                  const SizedBox(width: 40),

                // 复选框
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategories[category.id!] = value ?? false;
                    });
                  },
                ),

                // 分类图标和名称
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(iconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAggregated) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(汇总)',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (monthlyAmount > 0)
                        Text(
                          '年度: ${annualAmount.toStringAsFixed(0)}元 → ${monthlyAmount.toStringAsFixed(0)}元/月',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAggregated ? Colors.blue[700] : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // 汇总按钮（仅父级分类显示）
                if (hasChildren)
                  Builder(
                    builder: (context) {
                      final appColors = context.appColors;
                      return Tooltip(
                        message: '从子分类汇总',
                        child: IconButton(
                          icon: const Icon(Icons.calculate, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          onPressed: () => _aggregateFromChildren(category),
                          style: IconButton.styleFrom(
                            backgroundColor: appColors.infoContainer,
                            foregroundColor: appColors.infoColor,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),

            // 第二行：金额输入（仅在选中时显示）
            if (isSelected) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: TextFormField(
                  controller: controller,
                  enabled: isSelected,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    hintText: '年度金额',
                    suffixText: '元/年',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  validator: (value) {
                    if (isSelected && (value == null || value.isEmpty)) {
                      return '请输入金额';
                    }
                    if (isSelected && double.tryParse(value!) == null) {
                      return '无效金额';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 从子分类汇总预算
  void _aggregateFromChildren(Category category) {
    final categoryProvider = context.read<CategoryProvider>();
    final children = _getChildren(category, categoryProvider.visibleCategories);

    if (children.isEmpty) {
      return;
    }

    double total = 0;
    int count = 0;

    for (final child in children) {
      final controller = _amountControllers[child.id];
      if (controller != null && controller.text.isNotEmpty) {
        try {
          total += double.parse(controller.text);
          count++;
        } catch (e) {
          // 忽略无效输入
        }
      }
    }

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('子分类中没有设置预算'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 更新父级输入框
    setState(() {
      _amountControllers[category.id]?.text = total.toStringAsFixed(0);
      _selectedCategories[category.id!] = true; // 自动选中
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已汇总 $count 个子分类，共 ${total.toStringAsFixed(0)} 元'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 处理提交
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final budgetProvider = context.read<BudgetProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    int successCount = 0;
    int failCount = 0;
    int updateCount = 0;

    // 遍历所有选中的分类
    for (var entry in _selectedCategories.entries) {
      if (entry.value) {
        final categoryId = entry.key;
        final controller = _amountControllers[categoryId];
        if (controller != null && controller.text.isNotEmpty) {
          final annualAmount = double.parse(controller.text);

          // 获取分类类型
          final category = categoryProvider.getCategoryById(categoryId);
          if (category != null) {
            // 检查是否已存在预算
            final hasExisting = budgetProvider.budgets.any((b) => b.categoryId == categoryId);

            bool success;
            if (hasExisting) {
              // 更新现有预算
              final existingBudget = budgetProvider.budgets.firstWhere(
                (b) => b.categoryId == categoryId,
              );
              success = await budgetProvider.updateAnnualBudget(
                existingBudget,
                annualAmount,
              );
              if (success) {
                updateCount++;
              } else {
                failCount++;
              }
            } else {
              // 创建新预算
              success = await budgetProvider.createAnnualBudget(
                categoryId,
                annualAmount,
                category.type,
              );
              if (success) {
                successCount++;
              } else {
                failCount++;
              }
            }
          }
        }
      }
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    // 显示结果
    if (successCount > 0 || updateCount > 0) {
      // 清空选中状态，让用户可以继续设置其他预算
      setState(() {
        _selectedCategories.clear();
      });

      String message = '';
      if (successCount > 0 && updateCount > 0) {
        message = '成功创建 $successCount 个预算，更新 $updateCount 个预算';
      } else if (successCount > 0) {
        message = '成功创建 $successCount 个预算';
      } else if (updateCount > 0) {
        message = '成功更新 $updateCount 个预算';
      }
      if (failCount > 0) {
        message += '，失败 $failCount 个';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(budgetProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
