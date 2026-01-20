import 'package:flutter/material.dart';
import '../../models/category_rule.dart';
import '../../models/category.dart';
import '../../services/database/category_rule_db_service.dart';
import '../../services/database/database_service.dart';
import '../../services/category/category_learning_service.dart';
import 'category_rule_form_screen.dart';

/// 分类规则管理页面
class CategoryRuleListScreen extends StatefulWidget {
  const CategoryRuleListScreen({super.key});

  @override
  State<CategoryRuleListScreen> createState() => _CategoryRuleListScreenState();
}

class _CategoryRuleListScreenState extends State<CategoryRuleListScreen> {
  final DatabaseService _dbService = DatabaseService();
  CategoryRuleDbService? _ruleDbService;
  final CategoryLearningService _learningService = CategoryLearningService();

  List<CategoryRule> _rules = [];
  Map<int, Category> _categoryMap = {};
  bool _loading = true;
  String _filterSource = 'all'; // all, user, learned
  String _filterStatus = 'all'; // all, active, inactive
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    final db = await _dbService.database;
    _ruleDbService = CategoryRuleDbService(db);
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      // 加载规则
      final rules = await _ruleDbService!.findAll();

      // 加载分类信息
      final db = await _dbService.database;
      final categoryMaps = await db.query('categories');
      final categoryMap = <int, Category>{};
      for (final map in categoryMaps) {
        final category = Category.fromMap(map);
        categoryMap[category.id!] = category;
      }

      // 加载统计信息
      final stats = await _learningService.getLearningStatistics();

      setState(() {
        _rules = rules;
        _categoryMap = categoryMap;
        _statistics = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  List<CategoryRule> get _filteredRules {
    return _rules.where((rule) {
      // 过滤来源
      if (_filterSource != 'all') {
        if (_filterSource == 'user' && rule.source != 'user') {
          return false;
        }
        if (_filterSource == 'learned' && rule.source != 'learned') {
          return false;
        }
      }

      // 过滤状态
      if (_filterStatus != 'all') {
        if (_filterStatus == 'active' && !rule.isActive) {
          return false;
        }
        if (_filterStatus == 'inactive' && rule.isActive) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类规则管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: '清理低效规则',
            onPressed: _showCleanupDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatistics(),
                _buildFilters(),
                Expanded(child: _buildRuleList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRule,
        tooltip: '添加规则',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 统计信息卡片
  Widget _buildStatistics() {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '规则统计',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatItem('总规则', _statistics!['total_rules']),
                _buildStatItem('活跃规则', _statistics!['active_rules']),
                _buildStatItem('学习规则', _statistics!['learned_rules']),
                _buildStatItem('用户规则', _statistics!['user_rules']),
                _buildStatItem('总匹配', _statistics!['total_matches']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.blue.shade50,
    );
  }

  /// 筛选器
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('全部')),
                ButtonSegment(value: 'user', label: Text('手动创建')),
                ButtonSegment(value: 'learned', label: Text('自动学习')),
              ],
              selected: {_filterSource},
              onSelectionChanged: (Set<String> selected) {
                setState(() {
                  _filterSource = selected.first;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'all', label: Text('全部')),
              ButtonSegment(value: 'active', label: Text('启用')),
              ButtonSegment(value: 'inactive', label: Text('禁用')),
            ],
            selected: {_filterStatus},
            onSelectionChanged: (Set<String> selected) {
              setState(() {
                _filterStatus = selected.first;
              });
            },
          ),
        ],
      ),
    );
  }

  /// 规则列表
  Widget _buildRuleList() {
    final filteredRules = _filteredRules;

    if (filteredRules.isEmpty) {
      return const Center(
        child: Text('暂无规则'),
      );
    }

    return ListView.builder(
      itemCount: filteredRules.length,
      itemBuilder: (context, index) {
        final rule = filteredRules[index];
        return _buildRuleItem(rule);
      },
    );
  }

  /// 规则项
  Widget _buildRuleItem(CategoryRule rule) {
    final category = _categoryMap[rule.categoryId];
    final categoryName = category?.name ?? '未知分类';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rule.isActive ? Colors.green : Colors.grey,
          child: Text(
            rule.matchType.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          rule.keyword,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: rule.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分类: $categoryName'),
            Text('类型: ${_getMatchTypeText(rule.matchType)}'),
            if (rule.counterparty != null)
              Text('对方: ${rule.counterparty}'),
            Text(
              '优先级: ${rule.priority} | 匹配: ${rule.matchCount}次 | ${_getSourceText(rule.source)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, rule),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('编辑'),
            ),
            PopupMenuItem(
              value: rule.isActive ? 'disable' : 'enable',
              child: Text(rule.isActive ? '禁用' : '启用'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('删除'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMatchTypeText(String type) {
    switch (type) {
      case 'exact':
        return '精确匹配';
      case 'partial':
        return '部分匹配';
      case 'counterparty':
        return '交易对方';
      default:
        return type;
    }
  }

  String _getSourceText(String source) {
    switch (source) {
      case 'user':
        return '手动创建';
      case 'learned':
        return '自动学习';
      case 'preset':
        return '预设';
      default:
        return source;
    }
  }

  /// 处理菜单操作
  Future<void> _handleMenuAction(String action, CategoryRule rule) async {
    switch (action) {
      case 'edit':
        await _editRule(rule);
        break;
      case 'enable':
      case 'disable':
        await _toggleRuleStatus(rule);
        break;
      case 'delete':
        await _deleteRule(rule);
        break;
    }
  }

  /// 切换规则状态
  Future<void> _toggleRuleStatus(CategoryRule rule) async {
    try {
      await _ruleDbService!.toggleActive(rule.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(rule.isActive ? '规则已禁用' : '规则已启用'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  /// 删除规则
  Future<void> _deleteRule(CategoryRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除规则"${rule.keyword}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _ruleDbService!.delete(rule.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('规则已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 清理低效规则对话框
  Future<void> _showCleanupDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理低效规则'),
        content: const Text(
          '将删除匹配次数小于 3 次的自动学习规则。\n\n'
          '这些规则可能是误判导致的，清理后可以提高匹配准确性。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清理', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      final deleted = await _learningService.cleanupIneffectiveRules(
        minMatchCount: 3,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 $deleted 条低效规则')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败: $e')),
        );
      }
    }
  }

  /// 添加规则
  Future<void> _addRule() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryRuleFormScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  /// 编辑规则
  Future<void> _editRule(CategoryRule rule) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryRuleFormScreen(rule: rule),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }
}
