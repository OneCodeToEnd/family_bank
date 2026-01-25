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
          SnackBar(content: Text('Failed to save model: $e')),
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
      title: Text(isEditing ? 'Edit AI Model' : 'Add AI Model'),
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
                  labelText: 'Model Name *',
                  hintText: 'e.g., DeepSeek Chat',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a model name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Provider Selection
              DropdownButtonFormField<String>(
                value: _selectedProvider,
                decoration: const InputDecoration(
                  labelText: 'Provider *',
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
                  labelText: 'Model ID *',
                  hintText: 'e.g., deepseek-chat',
                ),
                enabled: !isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a model ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // API Key
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: isEditing ? 'API Key (leave empty to keep current)' : 'API Key *',
                  hintText: 'Enter your API key',
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
                    return 'Please enter an API key';
                  }
                  if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                    return 'API key seems too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Base URL
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL (optional)',
                  hintText: 'e.g., https://api.deepseek.com',
                ),
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      !value.startsWith('http')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Set as Active
              CheckboxListTile(
                title: const Text('Set as active model'),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
