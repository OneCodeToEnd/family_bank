import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/counterparty_provider.dart';
import '../../models/counterparty_group.dart';
import 'counterparty_group_form_screen.dart';
import 'counterparty_suggestions_screen.dart';

/// 对手方管理页面
class CounterpartyManagementScreen extends StatefulWidget {
  const CounterpartyManagementScreen({super.key});

  @override
  State<CounterpartyManagementScreen> createState() =>
      _CounterpartyManagementScreenState();
}

class _CounterpartyManagementScreenState
    extends State<CounterpartyManagementScreen> {
  final Set<String> _expandedGroups = {}; // 展开的分组
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<CounterpartyProvider>().loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对手方管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: '智能建议',
            onPressed: () => _navigateToSuggestions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBar(),

          // 分组列表
          Expanded(
            child: _buildGroupList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddGroup(),
        icon: const Icon(Icons.create_new_folder),
        label: const Text('手动分组'),
      ),
    );
  }

  /// 搜索框
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索对手方...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  /// 分组列表
  Widget _buildGroupList() {
    return Consumer<CounterpartyProvider>(
      builder: (context, provider, child) {
        // 加载状态
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 错误状态
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }

        // 按主对手方分组
        final groupedData = _groupByMainCounterparty(provider.groups);

        // 过滤搜索结果
        final filteredGroups = groupedData.entries.where((entry) {
          if (_searchQuery.isEmpty) return true;
          return entry.key.toLowerCase().contains(_searchQuery) ||
              entry.value.any((g) => g.subCounterparty.toLowerCase().contains(_searchQuery));
        }).toList();

        // 空状态
        if (filteredGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? '暂无分组' : '未找到匹配的分组',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '点击右下角按钮创建分组',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ],
            ),
          );
        }

        // 分组列表
        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filteredGroups.length,
            itemBuilder: (context, index) {
              final entry = filteredGroups[index];
              return _buildGroupCard(entry.key, entry.value);
            },
          ),
        );
      },
    );
  }

  /// 按主对手方分组
  Map<String, List<CounterpartyGroup>> _groupByMainCounterparty(
      List<CounterpartyGroup> groups) {
    final Map<String, List<CounterpartyGroup>> result = {};
    for (final group in groups) {
      result.putIfAbsent(group.mainCounterparty, () => []).add(group);
    }
    return result;
  }

  /// 分组卡片
  Widget _buildGroupCard(String mainCounterparty, List<CounterpartyGroup> subGroups) {
    final isExpanded = _expandedGroups.contains(mainCounterparty);
    final subCount = subGroups.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.folder),
            ),
            title: Text(
              mainCounterparty,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$subCount 个子对手方'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _navigateToEditGroup(mainCounterparty, subGroups),
                  tooltip: '编辑',
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedGroups.remove(mainCounterparty);
                      } else {
                        _expandedGroups.add(mainCounterparty);
                      }
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedGroups.remove(mainCounterparty);
                } else {
                  _expandedGroups.add(mainCounterparty);
                }
              });
            },
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...subGroups.map((group) => _buildSubCounterpartyTile(group)),
          ],
        ],
      ),
    );
  }

  /// 子对手方条目
  Widget _buildSubCounterpartyTile(CounterpartyGroup group) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(group.subCounterparty),
      subtitle: Row(
        children: [
          if (group.autoCreated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '自动',
                style: TextStyle(fontSize: 10, color: Colors.blue),
              ),
            ),
          if (group.autoCreated) const SizedBox(width: 8),
          Text(
            '置信度: ${(group.confidenceScore * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, size: 20),
        onPressed: () => _confirmRemoveSubCounterparty(group),
        tooltip: '解除关联',
      ),
    );
  }

  /// 导航到添加分组
  Future<void> _navigateToAddGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CounterpartyGroupFormScreen(),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  /// 导航到编辑分组
  Future<void> _navigateToEditGroup(
      String mainCounterparty, List<CounterpartyGroup> subGroups) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterpartyGroupFormScreen(
          mainCounterparty: mainCounterparty,
          existingSubCounterparties: subGroups.map((g) => g.subCounterparty).toList(),
        ),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  /// 导航到智能建议
  Future<void> _navigateToSuggestions() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CounterpartySuggestionsScreen(),
      ),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  /// 确认解除子对手方关联
  Future<void> _confirmRemoveSubCounterparty(CounterpartyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认解除关联'),
        content: Text('确定要将"${group.subCounterparty}"从"${group.mainCounterparty}"分组中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<CounterpartyProvider>();
      await provider.removeSubFromGroup(group.subCounterparty);

      if (provider.errorMessage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已解除关联')),
          );
        }
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('解除失败: ${provider.errorMessage}')),
          );
        }
      }
    }
  }
}
