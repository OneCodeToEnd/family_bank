import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/bill_email_item.dart';
import '../../models/import_result.dart';
import '../../services/database/email_config_db_service.dart';
import '../../services/import/email_service.dart';
import '../../services/import/unzip_service.dart';
import '../../services/import/bill_import_service.dart';
import '../../services/bill_validation_service.dart';
import '../../services/ai/ai_classifier_factory.dart';
import '../../services/ai/ai_config_service.dart';
import 'import_confirmation_screen.dart';
import '../settings/email_config_screen.dart';

/// 邮件账单选择页面
class EmailBillSelectScreen extends StatefulWidget {
  const EmailBillSelectScreen({super.key});

  @override
  State<EmailBillSelectScreen> createState() => _EmailBillSelectScreenState();
}

class _EmailBillSelectScreenState extends State<EmailBillSelectScreen> {
  late final EmailService _emailService;
  final _unzipService = UnzipService();
  late BillImportService _billImportService;
  final _dbService = EmailConfigDbService();

  List<BillEmailItem> _emails = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndSearch();
  }

  /// 初始化服务并搜索邮件
  Future<void> _initializeAndSearch() async {
    await _initServices();
    await _searchEmails();
  }

  /// 初始化服务
  Future<void> _initServices() async {
    try {
      // 加载 AI 配置
      final aiConfigService = AIConfigService();
      final aiConfig = await aiConfigService.loadConfig();

      // 创建 AI 分类服务
      final aiClassifierService = AIClassifierFactory.create(
        aiConfig.provider,
        aiConfig.apiKey,
        aiConfig.modelId,
        aiConfig,
      );

      // 创建验证服务
      final validationService = BillValidationService(aiClassifierService);
      _billImportService = BillImportService(validationService: validationService);
      _emailService = EmailService(billImportService: _billImportService);
    } catch (e) {
      // 如果初始化失败，创建不带验证的导入服务
      _billImportService = BillImportService();
      _emailService = EmailService(billImportService: _billImportService);
    }
  }

  @override
  void dispose() {
    _emailService.disconnect();
    super.dispose();
  }

  /// 搜索账单邮件
  Future<void> _searchEmails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _dbService.getConfig();
      if (config == null) {
        throw Exception('请先配置邮箱');
      }

      await _emailService.connect(config);

      // 搜索最近3天的邮件
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final emails = await _emailService.searchBillEmails(
        limit: 20,
        since: threeDaysAgo,
      );

      if (mounted) {
        setState(() {
          _emails = emails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 处理选中的邮件
  Future<void> _processSelectedEmails() async {
    final selected = _emails.where((e) => e.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个邮件')),
      );
      return;
    }

    // 检查是否都输入了密码
    for (final email in selected) {
      if (email.password == null || email.password!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请为 ${email.attachmentName} 输入解压密码')),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      ImportResult? combinedResult;
      final tempDir = await getTemporaryDirectory();
      final workDir = Directory('${tempDir.path}/bill_import');

      for (final email in selected) {
        File zipFile;

        // 根据是否有下载链接选择不同的下载方式
        if (email.hasDownloadUrl) {
          // 微信富文本邮件：通过 HTTP 下载
          zipFile = await _emailService.downloadFileFromUrl(
            email.downloadUrl!,
            email.attachmentName,
          );
        } else {
          // 传统附件：从邮件下载
          zipFile = await _emailService.downloadAttachment(
            email.messageId,
            email.attachmentName,
          );
        }

        // 解压
        final files = await _unzipService.unzip(
          zipFile,
          email.password!,
          workDir.path,
        );

        // 解析账单
        for (final file in files) {
          final result = await _parseFileWithValidation(file, email.platform);
          if (combinedResult == null) {
            combinedResult = result;
          } else {
            // 合并结果（只保留最后一个验证结果）
            combinedResult = ImportResult(
              transactions: [...combinedResult.transactions, ...result.transactions],
              validationResult: result.validationResult,
              source: combinedResult.source,
            );
          }
        }
      }

      // 清理临时文件
      await _unzipService.cleanupTempFiles(workDir.path);

      if (mounted && combinedResult != null) {
        setState(() => _isProcessing = false);

        // 跳转到确认页面
        final result = await Navigator.push<int>(
          context,
          MaterialPageRoute(
            builder: (context) => ImportConfirmationScreen(
              importResult: combinedResult!,
            ),
          ),
        );

        if (result != null && result > 0 && mounted) {
          Navigator.pop(context, result);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 解析文件（带验证）
  Future<ImportResult> _parseFileWithValidation(File file, String platform) async {
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'csv' && platform == 'alipay') {
      return await _billImportService.importAlipayCSVWithValidation(file, 1);
    } else if ((extension == 'xlsx' || extension == 'xls') &&
        platform == 'wechat') {
      return await _billImportService.importWeChatExcelWithValidation(file, 1);
    }

    throw Exception('不支持的文件格式: $extension');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择账单邮件'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _searchEmails,
            tooltip: '刷新邮件列表',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在搜索邮件...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _searchEmails,
                  child: const Text('重试'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmailConfigScreen(),
                      ),
                    );
                    // 如果配置成功,重新搜索邮件
                    if (result == true && mounted) {
                      _searchEmails();
                    }
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('邮箱配置'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_emails.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('未找到账单邮件'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emails.length,
      itemBuilder: (context, index) => _buildEmailItem(_emails[index]),
    );
  }

  Widget _buildEmailItem(BillEmailItem email) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: email.isSelected,
        onChanged: (value) {
          setState(() => email.isSelected = value ?? false);
        },
        title: Text(email.attachmentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${email.platformName} • ${DateFormat('yyyy-MM-dd').format(email.date)} • ${email.formattedSize}',
              style: const TextStyle(fontSize: 12),
            ),
            if (email.isSelected) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: '解压密码',
                  hintText: '请输入解压密码',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onChanged: (value) => email.password = value,
              ),
            ],
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget? _buildBottomBar() {
    final selectedCount = _emails.where((e) => e.isSelected).length;
    if (selectedCount == 0) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processSelectedEmails,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('导入选中的账单 ($selectedCount)'),
        ),
      ),
    );
  }
}
