import 'package:flutter/material.dart';
import '../../models/email_config.dart';
import '../../services/database/email_config_db_service.dart';
import '../../services/import/email_service.dart';
import '../../theme/app_colors.dart';

/// 邮箱配置页面
class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key});

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController(text: '993');
  final _passwordController = TextEditingController();

  final _dbService = EmailConfigDbService();
  bool _isLoading = false;
  bool _isTesting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 加载已有配置
  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await _dbService.getConfig();
      if (config != null && mounted) {
        _emailController.text = config.email;
        _serverController.text = config.imapServer;
        _portController.text = config.imapPort.toString();
        _passwordController.text = config.password;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载配置失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 测试连接
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isTesting = true);

    try {
      final config = EmailConfig(
        email: _emailController.text.trim(),
        imapServer: _serverController.text.trim(),
        imapPort: int.parse(_portController.text.trim()),
        password: _passwordController.text,
      );

      final success = await EmailService.testConnection(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接成功！' : '连接失败，请检查配置'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final config = EmailConfig(
        email: _emailController.text.trim(),
        imapServer: _serverController.text.trim(),
        imapPort: int.parse(_portController.text.trim()),
        password: _passwordController.text,
      );

      await _dbService.saveConfig(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 快速填充常见邮箱配置
  void _fillPreset(String email) {
    if (email.contains('@qq.com')) {
      _serverController.text = 'imap.qq.com';
    } else if (email.contains('@163.com')) {
      _serverController.text = 'imap.163.com';
    } else if (email.contains('@126.com')) {
      _serverController.text = 'imap.126.com';
    } else if (email.contains('@gmail.com')) {
      _serverController.text = 'imap.gmail.com';
    } else if (email.contains('@outlook.com') || email.contains('@hotmail.com')) {
      _serverController.text = 'outlook.office365.com';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('邮箱账单同步设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 邮箱配置卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.email, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '邮箱配置',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 邮箱地址
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: '邮箱地址',
                              hintText: 'example@qq.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入邮箱地址';
                              }
                              if (!value.contains('@')) {
                                return '请输入有效的邮箱地址';
                              }
                              return null;
                            },
                            onChanged: _fillPreset,
                          ),
                          const SizedBox(height: 16),

                          // IMAP服务器
                          TextFormField(
                            controller: _serverController,
                            decoration: const InputDecoration(
                              labelText: 'IMAP服务器',
                              hintText: 'imap.qq.com',
                              prefixIcon: Icon(Icons.dns_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入IMAP服务器地址';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 端口
                          TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: '端口',
                              hintText: '993',
                              prefixIcon: Icon(Icons.settings_ethernet),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入端口';
                              }
                              final port = int.tryParse(value);
                              if (port == null || port < 1 || port > 65535) {
                                return '请输入有效的端口号(1-65535)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // 密码/授权码
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: '邮箱密码/授权码',
                              hintText: '请输入密码或授权码',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入密码或授权码';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 常见邮箱设置提示
                  Builder(
                    builder: (context) {
                      final appColors = context.appColors;
                      return Card(
                        color: appColors.infoContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: appColors.onInfoContainer),
                                  const SizedBox(width: 8),
                                  Text(
                                    '常见邮箱IMAP设置',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: appColors.onInfoContainer,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildEmailPreset('QQ邮箱', 'imap.qq.com', '993'),
                              _buildEmailPreset('163邮箱', 'imap.163.com', '993'),
                              _buildEmailPreset('126邮箱', 'imap.126.com', '993'),
                              _buildEmailPreset('Gmail', 'imap.gmail.com', '993'),
                              _buildEmailPreset(
                                  'Outlook', 'outlook.office365.com', '993'),
                              const SizedBox(height: 12),
                              Text(
                                '注意：大部分邮箱需要开启IMAP服务并使用授权码，而非登录密码。',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.warningColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 按钮
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTesting ? null : _testConnection,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: const Text('测试连接'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveConfig,
                          icon: const Icon(Icons.save),
                          label: const Text('保存配置'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmailPreset(String name, String server, String port) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '• $name: $server:$port',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
