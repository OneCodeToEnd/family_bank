import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/sync/webdav_config.dart';
import '../../../services/sync/webdav_config_service.dart';
import '../../../services/sync/auto_sync_service.dart';

/// WebDAV 配置界面
class WebDAVSetupScreen extends StatefulWidget {
  final WebDAVConfig? existingConfig;

  const WebDAVSetupScreen({
    super.key,
    this.existingConfig,
  });

  @override
  State<WebDAVSetupScreen> createState() => _WebDAVSetupScreenState();
}

class _WebDAVSetupScreenState extends State<WebDAVSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _configService = WebDAVConfigService();

  // 表单控制器
  late final TextEditingController _serverUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _remotePathController;

  // 配置选项
  bool _autoSync = false;
  int _syncInterval = 60;
  bool _syncOnStart = false;
  bool _syncOnChange = false;
  bool _allowSelfSignedCert = false;
  bool _allowInsecureConnection = false;

  // 状态
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    final config = widget.existingConfig;
    _serverUrlController = TextEditingController(text: config?.serverUrl ?? '');
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    _remotePathController =
        TextEditingController(text: config?.remotePath ?? '/FamilyBank/');

    // 初始化配置选项
    if (config != null) {
      _autoSync = config.autoSync;
      _syncInterval = config.syncInterval;
      _syncOnStart = config.syncOnStart;
      _syncOnChange = config.syncOnChange;
      _allowSelfSignedCert = config.allowSelfSignedCert;
      _allowInsecureConnection = config.allowInsecureConnection;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingConfig == null ? '配置 WebDAV' : '编辑 WebDAV 配置'),
        actions: [
          if (widget.existingConfig != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteConfig,
              tooltip: '删除配置',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 服务器配置
            _buildSectionHeader('服务器配置'),
            const SizedBox(height: 8),
            _buildServerUrlField(),
            const SizedBox(height: 16),
            _buildUsernameField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 16),
            _buildRemotePathField(),
            const SizedBox(height: 24),

            // 连接测试
            _buildTestConnectionButton(),
            const SizedBox(height: 24),

            // 同步选项
            _buildSectionHeader('同步选项'),
            const SizedBox(height: 8),
            _buildAutoSyncSwitch(),
            if (_autoSync) ...[
              _buildSyncIntervalField(),
              _buildSyncOnStartSwitch(),
              _buildSyncOnChangeSwitch(),
            ],
            const SizedBox(height: 24),

            // 高级选项
            _buildSectionHeader('高级选项'),
            const SizedBox(height: 8),
            _buildAllowSelfSignedCertSwitch(),
            _buildAllowInsecureConnectionSwitch(),
            const SizedBox(height: 24),

            // 安全提示
            _buildSecurityWarning(),
            const SizedBox(height: 24),

            // 保存按钮
            _buildSaveButton(),
            const SizedBox(height: 16),

            // 配置示例
            _buildConfigExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildServerUrlField() {
    return TextFormField(
      controller: _serverUrlController,
      decoration: const InputDecoration(
        labelText: '服务器地址',
        hintText: 'https://cloud.example.com/remote.php/dav/files/username/',
        prefixIcon: Icon(Icons.cloud),
        border: OutlineInputBorder(),
        helperText: '必须以 https:// 开头（除非允许非安全连接）',
      ),
      keyboardType: TextInputType.url,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入服务器地址';
        }
        if (!value.startsWith('http://') && !value.startsWith('https://')) {
          return '请输入有效的 URL';
        }
        if (!value.startsWith('https://') && !_allowInsecureConnection) {
          return '必须使用 HTTPS，或在高级选项中允许非安全连接';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: '用户名',
        hintText: '您的 WebDAV 用户名',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入用户名';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: '密码',
        hintText: '您的 WebDAV 密码',
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        helperText: '密码将使用 AES 加密后存储在本地数据库中',
        helperStyle: const TextStyle(color: Colors.green, fontSize: 12),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入密码';
        }
        return null;
      },
    );
  }

  Widget _buildRemotePathField() {
    return TextFormField(
      controller: _remotePathController,
      decoration: const InputDecoration(
        labelText: '远程路径',
        hintText: '/FamilyBank/',
        prefixIcon: Icon(Icons.folder),
        border: OutlineInputBorder(),
        helperText: '备份文件将存储在此路径下',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入远程路径';
        }
        if (!value.startsWith('/')) {
          return '路径必须以 / 开头';
        }
        return null;
      },
    );
  }

  Widget _buildTestConnectionButton() {
    return ElevatedButton.icon(
      onPressed: _isTesting ? null : _testConnection,
      icon: _isTesting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.wifi_find),
      label: Text(_isTesting ? '测试中...' : '测试连接'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildAutoSyncSwitch() {
    return SwitchListTile(
      title: const Text('启用自动同步'),
      subtitle: const Text('自动在后台同步数据'),
      value: _autoSync,
      onChanged: (value) {
        setState(() {
          _autoSync = value;
        });
      },
    );
  }

  Widget _buildSyncIntervalField() {
    return ListTile(
      title: const Text('同步间隔'),
      subtitle: Text('每 $_syncInterval 分钟同步一次'),
      trailing: DropdownButton<int>(
        value: _syncInterval,
        items: const [
          DropdownMenuItem(value: 15, child: Text('15 分钟')),
          DropdownMenuItem(value: 30, child: Text('30 分钟')),
          DropdownMenuItem(value: 60, child: Text('1 小时')),
          DropdownMenuItem(value: 120, child: Text('2 小时')),
          DropdownMenuItem(value: 360, child: Text('6 小时')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _syncInterval = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildSyncOnStartSwitch() {
    return SwitchListTile(
      title: const Text('启动时同步'),
      subtitle: const Text('应用启动时自动检查并同步'),
      value: _syncOnStart,
      onChanged: (value) {
        setState(() {
          _syncOnStart = value;
        });
      },
    );
  }

  Widget _buildSyncOnChangeSwitch() {
    return SwitchListTile(
      title: const Text('数据变化时同步'),
      subtitle: const Text('数据修改后自动同步（实验性功能）'),
      value: _syncOnChange,
      onChanged: (value) {
        setState(() {
          _syncOnChange = value;
        });
      },
    );
  }

  Widget _buildAllowSelfSignedCertSwitch() {
    return SwitchListTile(
      title: const Text('允许自签名证书'),
      subtitle: const Text('用于自建服务器（功能开发中，暂不可用）'),
      value: _allowSelfSignedCert,
      onChanged: (value) {
        setState(() {
          _allowSelfSignedCert = value;
        });
      },
    );
  }

  Widget _buildAllowInsecureConnectionSwitch() {
    return SwitchListTile(
      title: const Text('允许非安全连接 (HTTP)'),
      subtitle: const Text('允许使用 HTTP 而非 HTTPS（不推荐）'),
      value: _allowInsecureConnection,
      onChanged: (value) {
        setState(() {
          _allowInsecureConnection = value;
        });
      },
    );
  }

  Widget _buildSecurityWarning() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.security, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '密码使用 AES 加密存储在本地数据库中。请妥善保管您的设备，避免未授权访问。',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveConfig,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('保存配置', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildConfigExamples() {
    return ExpansionTile(
      title: const Text('配置示例'),
      children: [
        ListTile(
          title: const Text('Nextcloud'),
          subtitle: const Text(
            'https://cloud.example.com/remote.php/dav/files/username/',
          ),
          dense: true,
        ),
        ListTile(
          title: const Text('坚果云'),
          subtitle: const Text('https://dav.jianguoyun.com/dav/'),
          dense: true,
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final config = _buildConfig();
      final isConnected = await _configService.testConnection(config);

      if (!mounted) return;

      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接成功！'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接失败，请检查配置'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接测试失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final config = _buildConfig();

      // 验证配置
      if (!_configService.validateConfig(config)) {
        throw Exception('配置验证失败');
      }

      // 保存配置
      await _configService.saveConfig(config);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置保存成功'),
          backgroundColor: Colors.green,
        ),
      );

      // 重新加载自动同步服务配置
      final autoSyncService = AutoSyncService();
      await autoSyncService.reloadConfig();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteConfig() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除配置'),
        content: const Text('确定要删除 WebDAV 配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _configService.deleteConfig();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置已删除'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  WebDAVConfig _buildConfig() {
    return WebDAVConfig(
      id: widget.existingConfig?.id ?? const Uuid().v4(),
      serverUrl: _serverUrlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      remotePath: _remotePathController.text.trim(),
      autoSync: _autoSync,
      syncInterval: _syncInterval,
      syncOnStart: _syncOnStart,
      syncOnChange: _syncOnChange,
      allowSelfSignedCert: _allowSelfSignedCert,
      allowInsecureConnection: _allowInsecureConnection,
    );
  }
}
