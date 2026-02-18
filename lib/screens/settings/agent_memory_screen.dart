import 'package:flutter/material.dart';
import '../../models/agent_memory.dart';
import '../../services/database/agent_memory_db_service.dart';

/// Agent 记忆管理页面
class AgentMemoryScreen extends StatefulWidget {
  const AgentMemoryScreen({super.key});

  @override
  State<AgentMemoryScreen> createState() => _AgentMemoryScreenState();
}

class _AgentMemoryScreenState extends State<AgentMemoryScreen> {
  final AgentMemoryDbService _dbService = AgentMemoryDbService();
  List<AgentMemory> _memories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<void> _loadMemories() async {
    final memories = await _dbService.getAll();
    setState(() {
      _memories = memories;
      _loading = false;
    });
  }

  Future<void> _deleteMemory(int id) async {
    await _dbService.delete(id);
    _loadMemories();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有记忆吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dbService.clearAll();
      _loadMemories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能问答记忆'),
        actions: [
          if (_memories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空全部',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _memories.isEmpty
              ? _buildEmptyState()
              : _buildMemoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '暂无记忆',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '与智能问答互动后会自动积累',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _memories.length,
      itemBuilder: (context, index) {
        final memory = _memories[index];
        return _buildMemoryCard(memory);
      },
    );
  }

  Widget _buildMemoryCard(AgentMemory memory) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, chipColor) = switch (memory.type) {
      'like' => ('赞', colorScheme.primary),
      'dislike' => ('踩', colorScheme.error),
      _ => ('记忆', Colors.green),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(label, style: const TextStyle(fontSize: 12)),
                  backgroundColor: chipColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: chipColor),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  _formatTime(memory.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(Icons.delete_outline, color: colorScheme.outline),
                    onPressed: memory.id != null
                        ? () => _deleteMemory(memory.id!)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(memory.content),
            if (memory.relatedQuery != null) ...[
              const SizedBox(height: 4),
              Text(
                '关联问题：${memory.relatedQuery}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}