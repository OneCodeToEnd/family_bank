import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category.dart';

/// 添加/编辑分类页面
class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final String? type; // 用于新建分类时指定类型
  final Category? parentCategory; // 父分类

  const CategoryFormScreen({
    super.key,
    this.category,
    this.type,
    this.parentCategory,
  });

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedColor;
  List<String> _tags = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      // 编辑模式
      _nameController.text = widget.category!.name;
      _selectedType = widget.category!.type;
      _selectedColor = widget.category!.color;
      _tags = List.from(widget.category!.tags);
    } else if (widget.type != null) {
      // 新建模式，指定了类型
      _selectedType = widget.type!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final hasParent = widget.parentCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑分类' : '添加分类'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 父分类信息（如果有）
            if (hasParent)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('父分类', style: TextStyle(fontSize: 12)),
                          Text(
                            widget.parentCategory!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (hasParent) const SizedBox(height: 16),

            // 类型选择（仅新建时且无父分类时可选）
            if (!isEditing && !hasParent) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('类型', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                    SizedBox(width: 4),
                                    Text('支出'),
                                  ],
                                ),
                              ),
                              selected: _selectedType == 'expense',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = 'expense';
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
                                    Text('收入'),
                                  ],
                                ),
                              ),
                              selected: _selectedType == 'income',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = 'income';
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 分类名称
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '分类名称',
                    hintText: '例如：餐饮',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入分类名称';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 颜色选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('颜色', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        '#E57373', '#F06292', '#BA68C8', '#9575CD', '#7986CB',
                        '#64B5F6', '#4FC3F7', '#4DD0E1', '#4DB6AC', '#81C784',
                        '#AED581', '#DCE775', '#FFF176', '#FFD54F', '#FFB74D',
                        '#FF8A65', '#A1887F', '#E0E0E0', '#90A4AE', '#607D8B',
                      ].map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${color.replaceAll('#', '')}')),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 标签
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('标签（可选）', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: const InputDecoration(
                              hintText: '输入标签后按添加',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.label),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add_circle),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _tags.remove(tag);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 系统分类提示
            if (isEditing && widget.category!.isSystem)
              Card(
                color: Colors.orange.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '这是系统预设分类，无法删除，但可以编辑名称和标签。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isEditing && widget.category!.isSystem) const SizedBox(height: 16),

            // 提交按钮
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? '保存' : '添加'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  /// 提交表单
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final categoryProvider = context.read<CategoryProvider>();
    final isEditing = widget.category != null;

    bool success;
    if (isEditing) {
      // 编辑分类
      final updatedCategory = widget.category!.copyWith(
        name: _nameController.text.trim(),
        color: _selectedColor,
        tags: _tags,
      );
      success = await categoryProvider.updateCategory(updatedCategory);
    } else {
      // 添加分类
      success = await categoryProvider.createCategory(
        name: _nameController.text.trim(),
        type: widget.parentCategory?.type ?? _selectedType,
        parentId: widget.parentCategory?.id,
        color: _selectedColor,
        tags: _tags,
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '分类已更新' : '分类已添加'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(categoryProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
