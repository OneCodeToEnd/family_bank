import 'package:flutter/material.dart';
import '../../models/ai_model_config.dart';
import '../../services/ai_model_config_service.dart';
import '../../constants/ai_model_constants.dart';
import '../../widgets/ai/ai_model_dialog.dart';

class AIModelManagementScreen extends StatefulWidget {
  const AIModelManagementScreen({super.key});

  @override
  State<AIModelManagementScreen> createState() =>
      _AIModelManagementScreenState();
}

class _AIModelManagementScreenState extends State<AIModelManagementScreen> {
  final AIModelConfigService _configService = AIModelConfigService();
  List<AIModelConfig> _models = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _configService.initialize();
      final models = await _configService.getAllModels();
      setState(() {
        _models = models;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load models: $e')),
        );
      }
    }
  }

  Future<void> _addModel() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AIModelDialog(),
    );

    if (result == true) {
      _loadModels();
    }
  }

  Future<void> _editModel(AIModelConfig model) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AIModelDialog(model: model),
    );

    if (result == true) {
      _loadModels();
    }
  }

  Future<void> _deleteModel(AIModelConfig model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete "${model.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _configService.deleteModel(model.id);
        _loadModels();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Model deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete model: $e')),
          );
        }
      }
    }
  }

  Future<void> _setActiveModel(AIModelConfig model) async {
    try {
      await _configService.setActiveModel(model.id);
      _loadModels();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${model.name} set as active')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set active model: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _models.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.smart_toy_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No AI models configured',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addModel,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Model'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _models.length,
                  itemBuilder: (context, index) {
                    final model = _models[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            AIModelConstants.getProviderDisplayName(
                                    model.provider)
                                .substring(0, 1),
                          ),
                        ),
                        title: Text(model.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AIModelConstants.getProviderDisplayName(model.provider)} - ${model.modelName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (model.baseUrl != null)
                              Text(
                                model.baseUrl!,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (model.isActive)
                              const Chip(
                                label: Text('Active',
                                    style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            else
                              TextButton(
                                onPressed: () => _setActiveModel(model),
                                child: const Text('Set Active'),
                              ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editModel(model);
                                } else if (value == 'delete') {
                                  _deleteModel(model);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: _models.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addModel,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
