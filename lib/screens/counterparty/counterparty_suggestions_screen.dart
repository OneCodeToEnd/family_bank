import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/counterparty_provider.dart';
import '../../models/counterparty_suggestion.dart';
import 'counterparty_group_form_screen.dart';

/// 智能分组建议页面
class CounterpartySuggestionsScreen extends StatefulWidget {
  const CounterpartySuggestionsScreen({super.key});

  @override
  State<CounterpartySuggestionsScreen> createState() =>
      _CounterpartySuggestionsScreenState();
}

class _CounterpartySuggestionsScreenState
    extends State<CounterpartySuggestionsScreen> {
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateSuggestions();
    });
  }

  Future<void> _generateSuggestions() async {
    await context.read<CounterpartyProvider>().generateSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能分组建议'),
        actions: [
          Consumer<CounterpartyProvider>(
            builder: (context, provider, child) {
              if (_selectedIndices.isEmpty || provider.suggestions.isEmpty) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => _applySelectedSuggestions(),
                icon: const Icon(Icons.check_circle),
                label: Text('确认 (${_selectedIndices.length})'),
              );
            },
          ),
        ],
      ),
      body: Consumer<CounterpartyProvider>(
        builder: (context, provider, child) {
          // 生成中状态
          if (provider.isGeneratingSuggestions) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在分析对手方数据...'),
                  SizedBox(height: 8),
                  Text(
                    '使用AI智能识别相似对手方',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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
                    onPressed: _generateSuggestions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          // 空状态
          if (provider.suggestions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    '暂无分组建议',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '系统未发现需要分组的相似对手方',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _generateSuggestions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新分析'),
                  ),
                ],
              ),
            );
          }

          // 建议列表
          return Column(
            children: [
              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '共发现 ${provider.suggestions.length} 个分组建议，请审核后确认',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

              // 建议列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: provider.suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = provider.suggestions[index];
                    final isSelected = _selectedIndices.contains(index);
                    return _buildSuggestionCard(suggestion, index, isSelected);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 建议卡片
  Widget _buildSuggestionCard(
      CounterpartySuggestion suggestion, int index, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedIndices.add(index);
                  } else {
                    _selectedIndices.remove(index);
                  }
                });
              },
            ),
            title: Row(
              children: [
                const Icon(Icons.folder, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.mainCounterparty,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildConfidenceBadge(suggestion.confidenceScore),
              ],
            ),
            subtitle: Text(
              '${suggestion.subCounterparties.length} 个相似对手方',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),

          // 子对手方列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestion.subCounterparties.map((sub) {
                return Chip(
                  label: Text(sub, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ),

          // 原因说明
          if (suggestion.reason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.reason,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _ignoreSuggestion(index),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('忽略'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editSuggestion(suggestion),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _applySuggestion(index),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('确认'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 置信度徽章
  Widget _buildConfidenceBadge(double score) {
    Color color;
    String label;

    if (score >= 0.9) {
      color = Colors.green;
      label = '高';
    } else if (score >= 0.7) {
      color = Colors.orange;
      label = '中';
    } else {
      color = Colors.red;
      label = '低';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 应用单个建议
  Future<void> _applySuggestion(int index) async {
    final provider = context.read<CounterpartyProvider>();
    final suggestion = provider.suggestions[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认分组'),
        content: Text(
          '确定要将以下对手方分组到"${suggestion.mainCounterparty}"吗？\n\n'
          '${suggestion.subCounterparties.join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.applySuggestion(suggestion);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已应用分组建议')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('应用失败: ${provider.errorMessage}')),
          );
        }
      }
    }
  }

  /// 批量应用选中的建议
  Future<void> _applySelectedSuggestions() async {
    if (_selectedIndices.isEmpty) return;

    final provider = context.read<CounterpartyProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量确认'),
        content: Text('确定要应用选中的 ${_selectedIndices.length} 个分组建议吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
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
                  Text('正在应用建议...'),
                ],
              ),
            ),
          ),
        ),
      );

      int successCount = 0;
      final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));

      for (final index in indices) {
        final suggestion = provider.suggestions[index];
        final success = await provider.applySuggestion(suggestion);
        if (success) {
          successCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功应用 $successCount/${_selectedIndices.length} 个建议'),
          ),
        );
        setState(() {
          _selectedIndices.clear();
        });
      }
    }
  }

  /// 忽略建议
  Future<void> _ignoreSuggestion(int index) async {
    final provider = context.read<CounterpartyProvider>();
    final suggestion = provider.suggestions[index];
    provider.ignoreSuggestion(suggestion);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已忽略该建议')),
      );
    }
  }

  /// 编辑建议
  Future<void> _editSuggestion(CounterpartySuggestion suggestion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CounterpartyGroupFormScreen(
          mainCounterparty: suggestion.mainCounterparty,
          existingSubCounterparties: suggestion.subCounterparties,
        ),
      ),
    );

    if (result == true && mounted) {
      await _generateSuggestions();
    }
  }
}
