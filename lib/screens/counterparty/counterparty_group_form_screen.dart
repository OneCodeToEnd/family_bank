import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/counterparty_provider.dart';
import '../../models/counterparty_group.dart';
import '../../services/database/transaction_db_service.dart';

/// 对手方分组编辑表单
class CounterpartyGroupFormScreen extends StatefulWidget {
  final String? mainCounterparty;
  final List<String>? existingSubCounterparties;

  const CounterpartyGroupFormScreen({
    super.key,
    this.mainCounterparty,
    this.existingSubCounterparties,
  });

  @override
  State<CounterpartyGroupFormScreen> createState() =>
      _CounterpartyGroupFormScreenState();
}

class _CounterpartyGroupFormScreenState
    extends State<CounterpartyGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mainCounterpartyController = TextEditingController();
  final _searchController = TextEditingController();

  List<String> _selectedSubCounterparties = [];
  List<String> _availableCounterparties = [];
  List<String> _filteredCounterparties = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mainCounterparty != null) {
      _mainCounterpartyController.text = widget.mainCounterparty!;
      _selectedSubCounterparties = List.from(widget.existingSubCounterparties ?? []);
    }
    _loadAvailableCounterparties();
  }

  @override
  void dispose() {
    _mainCounterpartyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCounterparties() async {
    setState(() => _isLoading = true);
    try {
      final dbService = TransactionDbService();
      final counterparties = await dbService.getCounterparties(limit: 1000);

      // 过滤掉已经被分组的对手方（除了当前编辑的分组）
      if (!mounted) return;
      final provider = context.read<CounterpartyProvider>();
      final filteredList = <String>[];

      for (final counterparty in counterparties) {
        final mainCounterparty = await provider.getMainCounterparty(counterparty);
        // 如果未分组，或者属于当前编辑的分组，则可选
        if (mainCounterparty == null ||
            mainCounterparty == widget.mainCounterparty) {
          filteredList.add(counterparty);
        }
      }

      if (!mounted) return;
      setState(() {
        _availableCounterparties = filteredList;
        _filteredCounterparties = filteredList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载对手方失败: $e')),
        );
      }
    }
  }

  void _filterCounterparties(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCounterparties = _availableCounterparties;
      } else {
        _filteredCounterparties = _availableCounterparties
            .where((c) => c.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.mainCounterparty != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑分组' : '创建分组'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: '删除分组',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 主对手方名称
                  TextFormField(
                    controller: _mainCounterpartyController,
                    decoration: const InputDecoration(
                      labelText: '主对手方名称',
                      hintText: '例如: 沃尔玛',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入主对手方名称';
                      }
                      return null;
                    },
                    enabled: !isEditing, // 编辑时不允许修改主对手方名称
                  ),
                  const SizedBox(height: 24),

                  // 子对手方选择
                  Text(
                    '子对手方',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择要关联到此分组的对手方',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),

                  // 已选择的子对手方
                  if (_selectedSubCounterparties.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSubCounterparties.map((counterparty) {
                        return Chip(
                          label: Text(counterparty),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedSubCounterparties.remove(counterparty);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 搜索框
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索对手方...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _filterCounterparties,
                  ),
                  const SizedBox(height: 16),

                  // 可选对手方列表
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filteredCounterparties.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          _searchController.text.isEmpty
                              ? '暂无可用对手方'
                              : '未找到匹配的对手方',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: _filteredCounterparties.map((counterparty) {
                          final isSelected =
                              _selectedSubCounterparties.contains(counterparty);
                          return CheckboxListTile(
                            title: Text(counterparty),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedSubCounterparties.add(counterparty);
                                } else {
                                  _selectedSubCounterparties.remove(counterparty);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // 底部按钮
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveGroup,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubCounterparties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个子对手方')),
      );
      return;
    }

    final mainCounterparty = _mainCounterpartyController.text.trim();
    final provider = context.read<CounterpartyProvider>();

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在保存...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      if (widget.mainCounterparty != null) {
        // 编辑模式：删除旧的，创建新的
        final oldSubs = widget.existingSubCounterparties ?? [];
        final toRemove = oldSubs.where((s) => !_selectedSubCounterparties.contains(s));
        final toAdd = _selectedSubCounterparties.where((s) => !oldSubs.contains(s));

        for (final sub in toRemove) {
          await provider.removeSubFromGroup(sub);
        }

        for (final sub in toAdd) {
          await provider.createGroup(
            mainCounterparty: mainCounterparty,
            subCounterparty: sub,
          );
        }
      } else {
        // 创建模式：批量创建
        final groups = _selectedSubCounterparties.map((sub) {
          return CounterpartyGroup(
            mainCounterparty: mainCounterparty,
            subCounterparty: sub,
            autoCreated: false,
            confidenceScore: 1.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
        await provider.createGroupsBatch(groups);
      }

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框

        if (provider.errorMessage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
          Navigator.pop(context, true); // 返回并刷新
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: ${provider.errorMessage}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${widget.mainCounterparty}"分组吗？\n\n这将解除所有子对手方的关联。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<CounterpartyProvider>();

      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在删除...'),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // 删除所有子对手方关联
        for (final sub in widget.existingSubCounterparties ?? []) {
          await provider.removeSubFromGroup(sub);
        }

        if (mounted) {
          Navigator.pop(context); // 关闭加载对话框

          if (provider.errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('删除成功')),
            );
            Navigator.pop(context, true); // 返回并刷新
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('删除失败: ${provider.errorMessage}')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}
