import 'package:flutter/material.dart';
import '../../models/ai_classification_config.dart';
import '../../models/ai_model.dart';
import '../../models/ai_provider.dart';
import '../../models/ai_model_config.dart';
import '../../constants/ai_model_constants.dart';
import '../../services/ai/ai_config_service.dart';
import '../../services/ai/ai_classifier_factory.dart';
import '../../services/ai/ai_model_test_service.dart';
import '../../services/ai_model_config_service.dart';
import '../../theme/app_colors.dart';
import 'ai_prompt_edit_screen.dart';
import 'ai_model_management_screen.dart';
import 'agent_memory_screen.dart';
import 'quick_question_screen.dart';

/// AI分类设置界面
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final AIConfigService _configService = AIConfigService();
  final AIModelConfigService _modelConfigService = AIModelConfigService();
  final AIModelTestService _testService = AIModelTestService();
  AIClassificationConfig? _config;
  List<AIModel>? _availableModels;
  bool _loading = true;
  bool _loadingModels = false;
  bool _testing = false;
  String? _testResult;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 避免在 build 期间调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConfig();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _configService.loadConfig();
      setState(() {
        _config = config;
        _apiKeyController.text = config.apiKey;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        _showError('加载配置失败: $e');
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_config == null) return;

    try {
      // 保存前更新 apiKey
      final updatedConfig = _config!.copyWith(
        apiKey: _apiKeyController.text,
      );

      await _configService.saveConfig(updatedConfig);

      setState(() {
        _config = updatedConfig;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('保存配置失败: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 助手设置')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI 助手设置')),
        body: const Center(child: Text('加载配置失败')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveConfig,
            tooltip: '保存',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildEnableSwitch(),
          if (_config!.enabled) ...[
            const Divider(height: 32),
            _buildProviderSelection(),
            const SizedBox(height: 16),
            _buildApiKeyInput(),
            const SizedBox(height: 8),
            _buildLoadSavedModelButton(),
            const SizedBox(height: 16),
            _buildModelSelection(),
            const SizedBox(height: 16),
            _buildTestButton(),
            if (_testResult != null) _buildTestResult(),
            const Divider(height: 32),
            _buildConfidenceSlider(),
            const SizedBox(height: 16),
            _buildAutoLearnSwitch(),
            const Divider(height: 32),
            _buildPromptConfigButton(),
            const SizedBox(height: 16),
            _buildModelManagementButton(),
            const SizedBox(height: 16),
            _buildMemoryManagementButton(),
            const SizedBox(height: 16),
            _buildQuickQuestionButton(),
            if (_availableModels != null &&
                _config!.modelId.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildModelPriceCard(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final appColors = context.appColors;
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
                  'AI 自动分类说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appColors.onInfoContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '启用后，系统将使用AI自动为导入的交易分类',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
            Text(
              '支持 DeepSeek 和通义千问两大AI服务商',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
            Text(
              '需要您提供相应的 API Key',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSwitch() {
    return SwitchListTile(
      title: const Text('启用 AI 分类'),
      subtitle: const Text('使用人工智能自动分类交易'),
      value: _config!.enabled,
      onChanged: (value) {
        setState(() {
          _config = _config!.copyWith(enabled: value);
        });
      },
    );
  }

  Widget _buildProviderSelection() {
    return ListTile(
      title: const Text('AI 提供商'),
      subtitle: Text(_config!.provider.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: _selectProvider,
    );
  }

  Widget _buildApiKeyInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'API Key',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showApiKeyHelp,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            hintText: '请输入 ${_config!.provider.displayName} 的 API Key',
            border: const OutlineInputBorder(),
            suffixIcon: _apiKeyController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _apiKeyController.clear();
                      });
                    },
                  )
                : null,
          ),
          obscureText: true,
          onChanged: (value) {
            setState(() {
              // API Key 改变时，清空模型列表
              _availableModels = null;
              _testResult = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLoadSavedModelButton() {
    return OutlinedButton.icon(
      onPressed: _loadSavedModel,
      icon: const Icon(Icons.folder_open, size: 18),
      label: const Text('从已保存的模型中选择'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }

  Widget _buildModelSelection() {
    if (_apiKeyController.text.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('请先输入 API Key'),
        ),
      );
    }

    return ListTile(
      title: const Text('选择模型'),
      subtitle: _config!.modelId.isEmpty
          ? const Text('请选择模型')
          : Text(_config!.modelId),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loadingModels)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadModels,
              tooltip: '刷新模型列表',
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: _loadingModels ? null : _selectModel,
    );
  }

  Widget _buildTestButton() {
    final canTest =
        _apiKeyController.text.isNotEmpty && _config!.modelId.isNotEmpty;

    return ElevatedButton.icon(
      onPressed: (_testing || !canTest) ? null : _testConnection,
      icon: _testing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_tethering),
      label: const Text('测试连接'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildTestResult() {
    final isSuccess = _testResult!.contains('成功');
    final appColors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSuccess ? appColors.successContainer : Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSuccess ? appColors.successColor : Theme.of(context).colorScheme.error,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? appColors.successColor : Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: isSuccess ? appColors.onSuccessContainer : Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('置信度阈值'),
          subtitle: Text(
            '低于此阈值的分类需要用户确认 (${(_config!.confidenceThreshold * 100).toInt()}%)',
          ),
          trailing: Text(
            '${(_config!.confidenceThreshold * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Slider(
          value: _config!.confidenceThreshold,
          min: 0.5,
          max: 0.95,
          divisions: 9,
          label: '${(_config!.confidenceThreshold * 100).toInt()}%',
          onChanged: (value) {
            setState(() {
              _config = _config!.copyWith(confidenceThreshold: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAutoLearnSwitch() {
    return SwitchListTile(
      title: const Text('自动学习规则'),
      subtitle: const Text('从 AI 分类结果中自动学习并创建规则'),
      value: _config!.autoLearn,
      onChanged: (value) {
        setState(() {
          _config = _config!.copyWith(autoLearn: value);
        });
      },
    );
  }

  Widget _buildPromptConfigButton() {
    return ListTile(
      title: const Text('提示词配置'),
      subtitle: const Text('自定义 AI 分类的提示词'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _editPrompts,
    );
  }

  Widget _buildModelManagementButton() {
    return ListTile(
      title: const Text('模型管理'),
      subtitle: const Text('管理自定义 AI 模型配置'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _navigateToModelManagement,
    );
  }

  Widget _buildMemoryManagementButton() {
    return ListTile(
      title: const Text('智能问答记忆'),
      subtitle: const Text('查看和管理 AI 助手的记忆'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgentMemoryScreen()),
      ),
    );
  }

  Widget _buildQuickQuestionButton() {
    return ListTile(
      title: const Text('常见问题'),
      subtitle: const Text('管理智能问答的快捷问题'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuickQuestionScreen()),
      ),
    );
  }

  Widget _buildModelPriceCard() {
    final currentModel = _availableModels?.firstWhere(
      (m) => m.id == _config!.modelId,
      orElse: () => AIModel(id: '', name: ''),
    );

    if (currentModel == null || currentModel.id.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  '当前模型费用',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appColors.onInfoContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '模型: ${currentModel.name}',
              style: TextStyle(color: appColors.onInfoContainer),
            ),
            if (currentModel.inputPrice != null)
              Text(
                '• 输入: ¥${currentModel.inputPrice}/千tokens',
                style: TextStyle(color: appColors.onInfoContainer),
              ),
            if (currentModel.outputPrice != null)
              Text(
                '• 输出: ¥${currentModel.outputPrice}/千tokens',
                style: TextStyle(color: appColors.onInfoContainer),
              ),
            const SizedBox(height: 4),
            Text(
              '注：实际费用取决于交易描述长度和分类数量',
              style: textTheme.bodySmall?.copyWith(
                color: appColors.onInfoContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadModels() async {
    if (_apiKeyController.text.isEmpty) {
      _showError('请先输入 API Key');
      return;
    }

    setState(() {
      _loadingModels = true;
      _testResult = null;
    });

    try {
      final service = AIClassifierFactory.create(
        _config!.provider,
        _apiKeyController.text,
        'temp', // 临时模型 ID
        _config!,
      );

      final models = await service.getAvailableModels();

      setState(() {
        _availableModels = models;
        _loadingModels = false;
      });

      if (models.isEmpty) {
        _showError('未找到可用模型');
      }
    } catch (e) {
      setState(() {
        _loadingModels = false;
      });
      _showError('获取模型列表失败: $e');
    }
  }

  Future<void> _selectModel() async {
    if (_availableModels == null || _availableModels!.isEmpty) {
      await _loadModels();
      if (_availableModels == null || _availableModels!.isEmpty) return;
    }

    if (!mounted) return;

    final textTheme = Theme.of(context).textTheme;

    final selected = await showDialog<AIModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择模型'),
        children: _availableModels!.map((model) {
          return SimpleDialogOption(
            child: ListTile(
              title: Text(model.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.description != null) Text(model.description!),
                  if (model.inputPrice != null)
                    Text(
                      '输入: ¥${model.inputPrice}/千tokens',
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
              selected: _config!.modelId == model.id,
            ),
            onPressed: () => Navigator.pop(context, model),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      setState(() {
        _config = _config!.copyWith(modelId: selected.id);
        _testResult = null;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    try {
      final result = await _testService.testWithCredentials(
        provider: _config!.provider,
        apiKey: _apiKeyController.text,
        modelId: _config!.modelId,
        config: _config,
      );

      setState(() {
        _testResult = result.message;
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ 连接失败: $e';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  void _selectProvider() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择 AI 提供商'),
        children: AIProvider.values.map((provider) {
          return SimpleDialogOption(
            child: ListTile(
              title: Text(provider.displayName),
              selected: _config!.provider == provider,
            ),
            onPressed: () {
              setState(() {
                _config = _config!.copyWith(
                  provider: provider,
                  modelId: '', // 切换提供商时清空模型选择
                );
                _availableModels = null; // 清空模型列表
                _testResult = null;
              });
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showApiKeyHelp() {
    final provider = _config!.provider;
    String helpText = '';
    String? url;

    switch (provider) {
      case AIProvider.deepseek:
        helpText = '1. 访问 https://platform.deepseek.com\n'
            '2. 注册并登录账号\n'
            '3. 进入 API Keys 页面\n'
            '4. 创建新的 API Key 并复制';
        url = 'https://platform.deepseek.com';
        break;
      case AIProvider.qwen:
        helpText = '1. 访问阿里云控制台\n'
            '2. 开通 DashScope 服务\n'
            '3. 获取 API Key\n'
            '4. 复制到此处';
        url = 'https://dashscope.console.aliyun.com/';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何获取 API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(helpText),
            if (url != null) ...[
              const SizedBox(height: 16),
              Text(
                '官网地址：',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(url),
            ],
          ],
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

  Future<void> _editPrompts() async {
    final result = await Navigator.push<AIClassificationConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => AIPromptEditScreen(config: _config!),
      ),
    );

    if (result != null) {
      setState(() {
        _config = result;
      });
    }
  }

  Future<void> _navigateToModelManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIModelManagementScreen(),
      ),
    );
  }

  Future<void> _loadSavedModel() async {
    try {
      final savedModels = await _modelConfigService.getAllModels();

      if (savedModels.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('暂无已保存的模型，请先在模型管理中添加')),
        );
        return;
      }

      if (!mounted) return;

      final selected = await showDialog<AIModelConfig>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('选择已保存的模型'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: savedModels.length,
              itemBuilder: (context, index) {
                final model = savedModels[index];
                return ListTile(
                  title: Text(model.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('提供商: ${AIModelConstants.getProviderDisplayName(model.provider)}'),
                      Text('模型: ${model.modelName}'),
                      if (model.baseUrl != null) Text('端点: ${model.baseUrl}'),
                      if (model.isActive)
                        const Text(
                          '当前激活',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, model),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      );

      if (selected != null) {
        // 应用选中的模型配置
        // 根据 provider 字符串映射到 AIProvider 枚举
        AIProvider? provider;
        switch (selected.provider.toLowerCase()) {
          case 'deepseek':
            provider = AIProvider.deepseek;
            break;
          case 'qwen':
            provider = AIProvider.qwen;
            break;
          default:
            provider = null;
        }

        if (provider != null) {
          // 解密 API Key
          final decryptedApiKey = _modelConfigService.getDecryptedApiKey(selected);

          setState(() {
            _config = _config!.copyWith(
              provider: provider,
              modelId: selected.modelName,
            );
            _apiKeyController.text = decryptedApiKey;
            _availableModels = null;
            _testResult = null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已加载模型: ${selected.name}')),
            );
          }
        } else {
          if (mounted) {
            _showError('不支持的提供商: ${selected.provider}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('加载已保存的模型失败: $e');
      }
    }
  }
}
