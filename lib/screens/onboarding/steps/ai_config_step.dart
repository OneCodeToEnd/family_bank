import 'package:flutter/material.dart';
import '../../../services/ai_model_config_service.dart';
import '../../../constants/ai_model_constants.dart';
import '../../../models/ai_model_config.dart';

/// AI 配置步骤（可选）
class AIConfigStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const AIConfigStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AIConfigStep> createState() => _AIConfigStepState();
}

class _AIConfigStepState extends State<AIConfigStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelNameController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final AIModelConfigService _configService = AIModelConfigService();

  String _selectedProvider = AIModelConstants.providerDeepSeek;
  bool _isSaving = false;
  bool _apiKeyVisible = false;
  bool _isActive = true;
  bool _isLoading = true;
  bool _hasExistingModels = false;
  List<AIModelConfig> _existingModels = [];

  // AI 提供商选项
  final List<Map<String, dynamic>> _providers = [
    {
      'provider': AIModelConstants.providerDeepSeek,
      'name': 'DeepSeek',
      'description': '高性价比，推荐使用',
      'icon': Icons.psychology,
      'color': Colors.blue,
      'url': 'https://platform.deepseek.com/',
    },
    {
      'provider': AIModelConstants.providerQwen,
      'name': '通义千问',
      'description': '阿里云提供',
      'icon': Icons.cloud,
      'color': Colors.orange,
      'url': 'https://dashscope.aliyun.com/',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingModels();
    });
  }

  Future<void> _loadExistingModels() async {
    try {
      final models = await _configService.getAllModels();
      setState(() {
        _existingModels = models;
        _hasExistingModels = models.isNotEmpty;
        _isLoading = false;
      });

      if (!_hasExistingModels) {
        _updateDefaultValues();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _updateDefaultValues();
    }
  }

  void _updateDefaultValues() {
    _nameController.text = _selectedProvider == AIModelConstants.providerDeepSeek
        ? 'DeepSeek Chat'
        : '通义千问';
    _modelNameController.text =
        AIModelConstants.getDefaultModelName(_selectedProvider) ?? '';
    _baseUrlController.text =
        AIModelConstants.getDefaultBaseUrl(_selectedProvider) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelNameController.dispose();
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  Future<void> _skipStep() async {
    // 直接跳过，不保存任何配置
    widget.onNext();
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _configService.createModel(
        name: _nameController.text.trim(),
        provider: _selectedProvider,
        modelName: _modelNameController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim().isEmpty
            ? null
            : _baseUrlController.text.trim(),
        isActive: _isActive,
      );

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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text(
            '第 4 步',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            '配置 AI 智能分类（可选）',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            _hasExistingModels
                ? '你已经配置了 AI 模型，可以跳过此步骤或添加新的模型'
                : 'AI 用于自动识别账单分类和提取流水信息，可以稍后在设置中配置',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 24),

          // 如果已有模型，显示提示信息
          if (_hasExistingModels) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已配置 ${_existingModels.length} 个 AI 模型',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '你可以直接跳过此步骤，或添加新的模型配置',
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
            const SizedBox(height: 24),
          ],

          // 表单
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 模型名称输入
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: '模型名称 *',
                      hintText: '例如：DeepSeek Chat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入模型名称';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // AI 提供商选择（紧凑型）
                  DropdownButtonFormField<String>(
                    value: _selectedProvider,
                    decoration: const InputDecoration(
                      labelText: 'AI 提供商 *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud),
                    ),
                    items: _providers.map((providerInfo) {
                      return DropdownMenuItem<String>(
                        value: providerInfo['provider'],
                        child: Row(
                          children: [
                            Icon(
                              providerInfo['icon'],
                              color: providerInfo['color'],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(providerInfo['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedProvider = value;
                          _updateDefaultValues();
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // 模型 ID 输入
                  TextFormField(
                    controller: _modelNameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: '模型ID *',
                      hintText: '例如：deepseek-chat',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.model_training),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入模型ID';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // API Key 输入
                  TextFormField(
                    controller: _apiKeyController,
                    enabled: !_isSaving,
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
                      if (value.trim().length < 10) {
                        return 'API Key 长度过短';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // 基础 URL 输入
                  TextFormField(
                    controller: _baseUrlController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: '基础URL（可选）',
                      hintText: '例如：https://api.deepseek.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          !value.startsWith('http')) {
                        return 'URL必须以http://或https://开头';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _saveConfig(),
                  ),

                  const SizedBox(height: 16),

                  // 设为活跃模型
                  CheckboxListTile(
                    title: const Text('设为活跃模型'),
                    subtitle: const Text('启用此模型进行 AI 分类'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? true;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
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

                  // 简化的提示信息
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI 用于自动分类账单，可稍后在设置中配置',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
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
                  onPressed: _isSaving ? null : _skipStep,
                  child: const Text('跳过'),
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
