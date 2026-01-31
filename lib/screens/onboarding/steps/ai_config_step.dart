import 'package:flutter/material.dart';
import '../../../models/ai_provider.dart';
import '../../../services/ai/ai_config_service.dart';
import '../../../models/ai_classification_config.dart';

/// AI 配置步骤（可选）
class AIConfigStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const AIConfigStep({
    super.key,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
  });

  @override
  State<AIConfigStep> createState() => _AIConfigStepState();
}

class _AIConfigStepState extends State<AIConfigStep> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final AIConfigService _aiConfigService = AIConfigService();

  AIProvider _selectedProvider = AIProvider.deepseek;
  bool _isSaving = false;
  bool _apiKeyVisible = false;

  // AI 提供商选项
  final List<Map<String, dynamic>> _providers = [
    {
      'provider': AIProvider.deepseek,
      'name': 'DeepSeek',
      'description': '高性价比，推荐使用',
      'icon': Icons.psychology,
      'color': Colors.blue,
      'url': 'https://platform.deepseek.com/',
    },
    {
      'provider': AIProvider.qwen,
      'name': '通义千问',
      'description': '阿里云提供',
      'icon': Icons.cloud,
      'color': Colors.orange,
      'url': 'https://dashscope.aliyun.com/',
    },
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final config = AIClassificationConfig(
        enabled: true,
        provider: _selectedProvider,
        apiKey: _apiKeyController.text.trim(),
        modelId: _selectedProvider == AIProvider.deepseek
            ? 'deepseek-chat'
            : 'qwen-turbo',
      );

      await _aiConfigService.saveConfig(config);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI 配置保存成功'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onNext();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Row(
            children: [
              Text(
                '第 4 步',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '可选',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            '配置 AI 智能分类',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'AI 可以自动识别账单分类，大幅提高准确度',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 24),

          // 表单
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // AI 提供商选择
                  Text(
                    '选择 AI 提供商',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  for (final providerInfo in _providers)
                    Builder(
                      builder: (context) {
                        final isSelected = _selectedProvider == providerInfo['provider'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedProvider = providerInfo['provider'];
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                providerInfo['icon'],
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : providerInfo['color'],
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      providerInfo['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      providerInfo['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                      },
                    ),

                  const SizedBox(height: 24),

                  // API Key 输入
                  TextFormField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key *',
                      hintText: '输入你的 API Key',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _apiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _apiKeyVisible = !_apiKeyVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_apiKeyVisible,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入 API Key';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveConfig(),
                  ),

                  const SizedBox(height: 12),

                  // 获取 API Key 提示
                  TextButton.icon(
                    onPressed: () {
                      final providerInfo = _providers.firstWhere(
                        (p) => p['provider'] == _selectedProvider,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('请访问: ${providerInfo['url']}'),
                          action: SnackBarAction(
                            label: '知道了',
                            onPressed: () {},
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('如何获取 API Key？'),
                  ),

                  const SizedBox(height: 24),

                  // 提示信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                            const SizedBox(width: 8),
                            Text(
                              '为什么推荐配置 AI？',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[900],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 自动识别账单分类，准确率 90%+\n'
                          '• 支持复杂交易描述的理解\n'
                          '• 持续学习，越用越准确\n'
                          '• API Key 加密存储，安全可靠',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Row(
            children: [
              // 返回按钮
              OutlinedButton(
                onPressed: _isSaving ? null : widget.onBack,
                child: const Text('返回'),
              ),

              const SizedBox(width: 12),

              // 跳过按钮
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : widget.onSkip,
                  child: const Text('暂时跳过'),
                ),
              ),

              const SizedBox(width: 12),

              // 保存并继续按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfig,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存并继续'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
