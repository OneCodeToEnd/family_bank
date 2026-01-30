import 'package:flutter/material.dart';
import '../../models/ai_classification_config.dart';
import '../../theme/app_colors.dart';

/// 提示词编辑界面
class AIPromptEditScreen extends StatefulWidget {
  final AIClassificationConfig config;

  const AIPromptEditScreen({
    super.key,
    required this.config,
  });

  @override
  State<AIPromptEditScreen> createState() => _AIPromptEditScreenState();
}

class _AIPromptEditScreenState extends State<AIPromptEditScreen> {
  late TextEditingController _systemPromptController;
  late TextEditingController _userPromptController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController(
      text: widget.config.systemPrompt,
    );
    _userPromptController = TextEditingController(
      text: widget.config.userPromptTemplate,
    );

    _systemPromptController.addListener(_onTextChanged);
    _userPromptController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    _userPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('提示词配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '帮助',
          ),
          if (_isModified)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetToDefault,
              tooltip: '重置为默认',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildSystemPromptSection(),
          const SizedBox(height: 24),
          _buildUserPromptSection(),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final appColors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: appColors.infoContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: appColors.onInfoContainer),
                const SizedBox(width: 8),
                Text(
                  '提示词说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appColors.onInfoContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '系统提示词定义 AI 的角色和任务',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
            Text(
              '用户提示词模板定义交易信息的格式',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
            const SizedBox(height: 8),
            Text(
              '可用变量：{{description}}, {{counterparty}}, {{amount}}, {{type}}, {{categories}}',
              style: textTheme.bodySmall?.copyWith(
                color: appColors.onInfoContainer.withValues(alpha: 0.8),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '系统提示词',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _systemPromptController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '定义 AI 的角色和任务...',
            border: OutlineInputBorder(),
            helperText: '这部分告诉 AI 它是谁以及要做什么',
          ),
        ),
      ],
    );
  }

  Widget _buildUserPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '用户提示词模板',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _userPromptController,
          maxLines: 15,
          decoration: const InputDecoration(
            hintText: '交易信息和分类列表的格式...',
            border: OutlineInputBorder(),
            helperText: '使用 {{变量名}} 格式插入交易信息',
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isModified ? _save : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('保存'),
    );
  }

  void _save() {
    final updated = widget.config.copyWith(
      systemPrompt: _systemPromptController.text,
      userPromptTemplate: _userPromptController.text,
    );

    Navigator.pop(context, updated);
  }

  void _resetToDefault() {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置提示词'),
        content: const Text('确定要重置为默认提示词吗？当前的修改将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 使用反射获取默认值比较困难，这里直接硬编码
              const defaultSystemPrompt = '''你是一个专业的账单分类助手。
根据交易信息，从给定的分类列表中选择最合适的分类。
请仔细分析交易描述、对方和金额，给出准确的分类建议。
必须返回JSON格式的结果。''';

              const defaultUserPromptTemplate = '''
交易信息：
- 描述：{{description}}
- 对方：{{counterparty}}
- 金额：{{amount}} 元
- 类型：{{type}}

可选分类：
{{categories}}

请返回JSON格式：
{
  "categoryId": <分类ID>,
  "confidence": <置信度0-1>,
  "reason": "<选择理由>"
}''';

              setState(() {
                _systemPromptController.text = defaultSystemPrompt;
                _userPromptController.text = defaultUserPromptTemplate;
              });
              Navigator.pop(context);
            },
            child: Text('重置', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示词帮助'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '可用变量：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildVariableItem('{{description}}', '交易描述'),
              _buildVariableItem('{{counterparty}}', '交易对方'),
              _buildVariableItem('{{amount}}', '交易金额'),
              _buildVariableItem('{{type}}', '交易类型（收入/支出）'),
              _buildVariableItem('{{categories}}', '可选分类列表'),
              const SizedBox(height: 16),
              const Text(
                '提示：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• 保持系统提示词简洁明确'),
              const Text('• 用户提示词中必须包含 {{categories}}'),
              const Text('• 要求返回 JSON 格式以便解析'),
              const Text('• 可以添加示例来提高准确性'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableItem(String variable, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              variable,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
