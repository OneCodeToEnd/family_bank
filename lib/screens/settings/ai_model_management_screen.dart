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
          SnackBar(content: Text('加载模型失败: $e')),
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
        title: const Text('删除模型'),
        content: Text('确定要删除"${model.name}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
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
            const SnackBar(content: Text('模型已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除模型失败: $e')),
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
          SnackBar(content: Text('已将 ${model.name} 设为活跃模型')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置活跃模型失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI模型管理'),
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
                        '暂无AI模型配置',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addModel,
                        icon: const Icon(Icons.add),
                        label: const Text('添加模型'),
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
                                label: Text('活跃',
                                    style: TextStyle(fontSize: 10)),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            else
                              TextButton(
                                onPressed: () => _setActiveModel(model),
                                child: const Text('设为活跃'),
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
                                  child: Text('编辑'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('删除'),
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
