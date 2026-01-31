import 'package:flutter/material.dart';
import '../../models/ai_model_config.dart';
import '../../services/ai_model_config_service.dart';
import '../../services/ai/ai_model_test_service.dart';
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
  final AIModelTestService _testService = AIModelTestService();
  List<AIModelConfig> _models = [];
  bool _isLoading = true;
  String? _testingModelId; // 正在测试的模型ID
  final Map<String, String> _testResults = {}; // 模型ID -> 测试结果

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

  Future<void> _testModel(AIModelConfig model) async {
    setState(() {
      _testingModelId = model.id;
      _testResults.remove(model.id); // 清除旧的测试结果
    });

    try {
      // 获取解密后的 API Key
      final decryptedApiKey = _configService.getDecryptedApiKey(model);

      // 执行测试
      final result = await _testService.testModelConfig(
        model,
        decryptedApiKey,
      );

      setState(() {
        _testResults[model.id] = result.message;
        _testingModelId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _testResults[model.id] = '✗ 测试失败: $e';
        _testingModelId = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试失败: $e'),
            backgroundColor: Colors.red,
          ),
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
                            // 显示测试状态
                            if (_testingModelId == model.id)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '测试中...',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_testResults.containsKey(model.id))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _testResults[model.id]!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _testResults[model.id]!
                                            .startsWith('✓')
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
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
                                if (value == 'test') {
                                  _testModel(model);
                                } else if (value == 'edit') {
                                  _editModel(model);
                                } else if (value == 'delete') {
                                  _deleteModel(model);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'test',
                                  child: Row(
                                    children: [
                                      Icon(Icons.wifi_tethering, size: 18),
                                      SizedBox(width: 8),
                                      Text('测试连接'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 18),
                                      SizedBox(width: 8),
                                      Text('编辑'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18),
                                      SizedBox(width: 8),
                                      Text('删除'),
                                    ],
                                  ),
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
