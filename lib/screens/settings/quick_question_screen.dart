import 'package:flutter/material.dart';
import '../../services/ai/quick_question_service.dart';

/// 常见问题管理页面
class QuickQuestionScreen extends StatefulWidget {
  const QuickQuestionScreen({super.key});

  @override
  State<QuickQuestionScreen> createState() => _QuickQuestionScreenState();
}

class _QuickQuestionScreenState extends State<QuickQuestionScreen> {
  final QuickQuestionService _service = QuickQuestionService();
  List<String> _questions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _service.getQuestions();
    setState(() {
      _questions = questions;
      _loading = false;
    });
  }

  Future<void> _addQuestion() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加常见问题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入问题，如：这个月花了多少钱？',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _service.addQuestion(result);
      _loadQuestions();
    }
  }

  Future<void> _deleteQuestion(int index) async {
    await _service.removeQuestion(index);
    _loadQuestions();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, item);
    });
    await _service.saveQuestions(_questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('常见问题'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? _buildEmptyState()
              : _buildQuestionList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuestion,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.quiz_outlined,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('暂无常见问题',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('点击右下角按钮添加常见问题',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _questions.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        return Card(
          key: ValueKey('$index-${_questions[index]}'),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.drag_handle,
                color: Theme.of(context).colorScheme.outline),
            title: Text(_questions[index]),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.outline),
              onPressed: () => _deleteQuestion(index),
            ),
          ),
        );
      },
    );
  }
}
