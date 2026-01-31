import 'package:flutter/material.dart';
import '../../models/ai_model_config.dart';
import '../../services/ai_model_config_service.dart';
import '../../constants/ai_model_constants.dart';

class AIModelDialog extends StatefulWidget {
  final AIModelConfig? model;

  const AIModelDialog({super.key, this.model});

  @override
  State<AIModelDialog> createState() => _AIModelDialogState();
}

class _AIModelDialogState extends State<AIModelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _configService = AIModelConfigService();

  late TextEditingController _nameController;
  late TextEditingController _modelNameController;
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;

  String _selectedProvider = AIModelConstants.providerDeepSeek;
  bool _isActive = false;
  bool _obscureApiKey = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.model?.name ?? '');
    _modelNameController =
        TextEditingController(text: widget.model?.modelName ?? '');
    _apiKeyController = TextEditingController();
    _baseUrlController =
        TextEditingController(text: widget.model?.baseUrl ?? '');

    if (widget.model != null) {
      _selectedProvider = widget.model!.provider;
      _isActive = widget.model!.isActive;
    } else {
      // Set default values for new model
      _updateDefaultValues();
    }
  }

  void _updateDefaultValues() {
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.model == null) {
        // Create new model
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
      } else {
        // Update existing model
        await _configService.updateModel(
          id: widget.model!.id,
          name: _nameController.text.trim(),
          apiKey: _apiKeyController.text.trim().isEmpty
              ? null
              : _apiKeyController.text.trim(),
          baseUrl: _baseUrlController.text.trim().isEmpty
              ? null
              : _baseUrlController.text.trim(),
          isActive: _isActive,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模型失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.model != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑AI模型' : '添加AI模型'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '模型名称 *',
                  hintText: '例如：DeepSeek Chat',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入模型名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Provider Selection
              DropdownButtonFormField<String>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: '服务商 *',
                ),
                items: AIModelConstants.providerDisplayNames.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (value) {
                        setState(() {
                          _selectedProvider = value!;
                          _updateDefaultValues();
                        });
                      },
              ),
              const SizedBox(height: 16),

              // Model ID
              TextFormField(
                controller: _modelNameController,
                decoration: const InputDecoration(
                  labelText: '模型ID *',
                  hintText: '例如：deepseek-chat',
                ),
                enabled: !isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入模型ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'API密钥（留空保持不变）' : 'API密钥 *',
                  hintText: '请输入API密钥',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureApiKey = !_obscureApiKey;
                      });
                    },
                  ),
                ),
                obscureText: _obscureApiKey,
                validator: (value) {
                  if (!isEditing && (value == null || value.trim().isEmpty)) {
                    return '请输入API密钥';
                  }
                  if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                    return 'API密钥长度过短';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Base URL
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: '基础URL（可选）',
                  hintText: '例如：https://api.deepseek.com',
                ),
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      !value.startsWith('http')) {
                    return 'URL必须以http://或https://开头';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Set as Active
              CheckboxListTile(
                title: const Text('设为活跃模型'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '更新' : '添加'),
        ),
      ],
    );
  }
}
