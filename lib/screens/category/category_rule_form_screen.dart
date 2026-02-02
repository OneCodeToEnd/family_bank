import 'package:flutter/material.dart';
import '../../models/category_rule.dart';
import '../../models/category.dart';
import '../../services/database/category_rule_db_service.dart';
import '../../services/database/database_service.dart';

/// 分类规则表单页面
class CategoryRuleFormScreen extends StatefulWidget {
  final CategoryRule? rule;

  const CategoryRuleFormScreen({super.key, this.rule});

  @override
  State<CategoryRuleFormScreen> createState() => _CategoryRuleFormScreenState();
}

class _CategoryRuleFormScreenState extends State<CategoryRuleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  CategoryRuleDbService? _ruleDbService;

  late TextEditingController _keywordController;
  late TextEditingController _counterpartyController;
  late TextEditingController _priorityController;

  int? _selectedCategoryId;
  String _matchType = 'exact';
  bool _isActive = true;
  bool _loading = true;
  List<Category> _categories = []; // 叶子节点分类
  List<Category> _allCategories = []; // 所有分类（用于构建路径）

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.rule?.keyword ?? '');
    _counterpartyController = TextEditingController(text: widget.rule?.counterparty ?? '');
    _priorityController = TextEditingController(text: widget.rule?.priority.toString() ?? '0');

    if (widget.rule != null) {
      _selectedCategoryId = widget.rule!.categoryId;
      _matchType = widget.rule!.matchType;
      _isActive = widget.rule!.isActive;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final db = await _dbService.database;
    _ruleDbService = CategoryRuleDbService(db);
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
    });

    try {
      final db = await _dbService.database;
      final categoryMaps = await db.query('categories');
      final allCategories = categoryMaps.map((map) => Category.fromMap(map)).toList();

      // 只显示叶子节点（没有子分类的分类）
      final leafCategories = allCategories.where((c) {
        return !allCategories.any((other) => other.parentId == c.id);
      }).toList();

      setState(() {
        _allCategories = allCategories; // 保存所有分类用于构建路径
        _categories = leafCategories;
        if (_selectedCategoryId == null && leafCategories.isNotEmpty) {
          _selectedCategoryId = leafCategories.first.id;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载分类失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _counterpartyController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? '添加规则' : '编辑规则'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _loading ? null : _saveRule,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKeywordField(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildMatchTypeSelector(),
                  const SizedBox(height: 16),
                  if (_matchType == 'counterparty') ...[
                    _buildCounterpartyField(),
                    const SizedBox(height: 16),
                  ],
                  _buildPriorityField(),
                  const SizedBox(height: 16),
                  _buildActiveSwitch(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildKeywordField() {
    return TextFormField(
      controller: _keywordController,
      decoration: const InputDecoration(
        labelText: '关键词',
        hintText: '输入匹配关键词',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.key),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入关键词';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('没有可用的分类'),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: '目标分类',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
        helperText: '只能选择末级分类（没有子分类的分类）',
      ),
      items: _categories.map((category) {
        // 构建分类路径显示
        String displayName = _getCategoryPath(category);

        return DropdownMenuItem(
          value: category.id,
          child: Text(displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return '请选择分类';
        }
        return null;
      },
    );
  }

  /// 获取分类路径
  String _getCategoryPath(Category category) {
    final path = <String>[];
    Category? current = category;

    while (current != null) {
      path.insert(0, current.name);
      if (current.parentId != null) {
        current = _allCategories.firstWhere(
          (c) => c.id == current!.parentId,
          orElse: () => current!,
        );
        if (current.id == category.id) {
          // 避免循环引用
          break;
        }
      } else {
        current = null;
      }
    }

    return path.join(' > ');
  }

  Widget _buildMatchTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '匹配类型',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'exact',
              label: Text('精确'),
              icon: Icon(Icons.done),
            ),
            ButtonSegment(
              value: 'partial',
              label: Text('部分'),
              icon: Icon(Icons.search),
            ),
            ButtonSegment(
              value: 'counterparty',
              label: Text('对方'),
              icon: Icon(Icons.person),
            ),
          ],
          selected: {_matchType},
          onSelectionChanged: (Set<String> selected) {
            setState(() {
              _matchType = selected.first;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          _getMatchTypeDescription(),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  String _getMatchTypeDescription() {
    switch (_matchType) {
      case 'exact':
        return '交易描述完全匹配关键词';
      case 'partial':
        return '交易描述包含关键词';
      case 'counterparty':
        return '匹配交易对方名称';
      default:
        return '';
    }
  }

  Widget _buildCounterpartyField() {
    return TextFormField(
      controller: _counterpartyController,
      decoration: const InputDecoration(
        labelText: '交易对方',
        hintText: '输入交易对方名称',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (_matchType == 'counterparty' && (value == null || value.trim().isEmpty)) {
          return '请输入交易对方名称';
        }
        return null;
      },
    );
  }

  Widget _buildPriorityField() {
    return TextFormField(
      controller: _priorityController,
      decoration: const InputDecoration(
        labelText: '优先级',
        hintText: '数字越大优先级越高',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.low_priority),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入优先级';
        }
        final priority = int.tryParse(value);
        if (priority == null) {
          return '请输入有效的数字';
        }
        return null;
      },
    );
  }

  Widget _buildActiveSwitch() {
    return SwitchListTile(
      title: const Text('启用规则'),
      subtitle: const Text('禁用的规则不会参与匹配'),
      value: _isActive,
      onChanged: (value) {
        setState(() {
          _isActive = value;
        });
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _saveRule,
        icon: const Icon(Icons.save),
        label: Text(widget.rule == null ? '添加规则' : '保存修改'),
      ),
    );
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final rule = CategoryRule(
        id: widget.rule?.id,
        keyword: _keywordController.text.trim(),
        categoryId: _selectedCategoryId!,
        priority: int.parse(_priorityController.text.trim()),
        isActive: _isActive,
        matchCount: widget.rule?.matchCount ?? 0,
        source: 'user',
        matchType: _matchType,
        counterparty: _matchType == 'counterparty' ? _counterpartyController.text.trim() : null,
        createdAt: widget.rule?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.rule == null) {
        await _ruleDbService!.create(rule);
      } else {
        await _ruleDbService!.update(rule);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.rule == null ? '规则已添加' : '规则已更新'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
