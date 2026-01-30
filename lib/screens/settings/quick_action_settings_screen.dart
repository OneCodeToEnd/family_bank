import 'package:flutter/material.dart';
import '../../constants/quick_action_constants.dart';
import '../../models/quick_action.dart';
import '../../services/quick_action_service.dart';

/// 快捷操作设置页面
/// 允许用户自定义首页快捷操作
class QuickActionSettingsScreen extends StatefulWidget {
  const QuickActionSettingsScreen({super.key});

  @override
  State<QuickActionSettingsScreen> createState() =>
      _QuickActionSettingsScreenState();
}

class _QuickActionSettingsScreenState
    extends State<QuickActionSettingsScreen> {
  final QuickActionService _service = QuickActionService();
  List<QuickAction> _selectedActions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  /// 加载快捷操作配置
  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final actions = await _service.loadQuickActions();
      setState(() {
        _selectedActions = actions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 保存快捷操作配置
  Future<void> _saveActions(List<QuickAction> actions) async {
    try {
      await _service.saveQuickActions(actions);
      setState(() {
        _selectedActions = actions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('快捷操作设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '恢复默认',
            onPressed: _showResetDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final availableActions = QuickActionConstants.allActions
        .where((action) => !_selectedActions.any((a) => a.id == action.id))
        .toList();

    return Column(
      children: [
        // 信息卡片
        _buildInfoCard(_selectedActions.length),

        // 当前快捷操作列表（可拖拽排序）
        Expanded(
          child: _buildCurrentActionsList(_selectedActions),
        ),

        // 可添加的快捷操作
        if (_selectedActions.length < QuickActionConstants.maxActions)
          _buildAvailableActionsSection(availableActions),
      ],
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard(int count) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前已选择 $count 个快捷操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '最少 ${QuickActionConstants.minActions} 个，最多 ${QuickActionConstants.maxActions} 个',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '长按拖动可调整顺序',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建当前操作列表（可拖拽排序）
  Widget _buildCurrentActionsList(
    List<QuickAction> actions,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: actions.length,
      onReorder: (oldIndex, newIndex) {
        _reorderActions(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final action = actions[index];
        final canDelete = actions.length > QuickActionConstants.minActions;

        return Card(
          key: ValueKey(action.id),
          child: ListTile(
            leading: Icon(action.icon),
            title: Text(action.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_handle),
                if (canDelete) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeAction(action),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建可添加的快捷操作区域
  Widget _buildAvailableActionsSection(
    List<QuickAction> availableActions,
  ) {
    if (availableActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '可添加的快捷操作',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: availableActions.length,
              itemBuilder: (context, index) {
                final action = availableActions[index];
                return _buildAvailableActionCard(action);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建可添加的快捷操作卡片
  Widget _buildAvailableActionCard(
    QuickAction action,
  ) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _addAction(action),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32),
              const SizedBox(height: 8),
              Text(
                action.name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Icon(Icons.add_circle, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 添加快捷操作
  Future<void> _addAction(QuickAction action) async {
    if (_selectedActions.length >= QuickActionConstants.maxActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已达到最大快捷操作数量')),
      );
      return;
    }

    if (_selectedActions.any((a) => a.id == action.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该快捷操作已存在')),
      );
      return;
    }

    final newActions = [..._selectedActions, action];
    await _saveActions(newActions);
  }

  /// 移除快捷操作
  void _removeAction(QuickAction action) {
    if (_selectedActions.length <= QuickActionConstants.minActions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('至少需要保留 ${QuickActionConstants.minActions} 个快捷操作'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除快捷操作'),
        content: Text('确定要移除"${action.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final newActions =
                  _selectedActions.where((a) => a.id != action.id).toList();
              _saveActions(newActions);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 调整快捷操作顺序
  Future<void> _reorderActions(int oldIndex, int newIndex) async {
    final newActions = List<QuickAction>.from(_selectedActions);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final action = newActions.removeAt(oldIndex);
    newActions.insert(newIndex, action);

    await _saveActions(newActions);
  }


  /// 显示恢复默认对话框
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复默认'),
        content: const Text('确定要恢复为默认的快捷操作吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final defaultActions = _service.getDefaultActions();
              await _saveActions(defaultActions);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('已恢复默认设置')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

