import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/account_provider.dart';
import '../../services/import/bill_import_service.dart';
import '../../services/bill_validation_service.dart';
import '../../services/ai/ai_classifier_factory.dart';
import '../../services/ai/ai_config_service.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import '../../models/import_result.dart';
import '../../widgets/transaction_detail_sheet.dart';
import 'import_confirmation_screen.dart';

/// 账单导入页面
class BillImportScreen extends StatefulWidget {
  const BillImportScreen({super.key});

  @override
  State<BillImportScreen> createState() => _BillImportScreenState();
}

class _BillImportScreenState extends State<BillImportScreen> {
  late final BillImportService _importService;
  late final BillValidationService _validationService;

  String? _selectedFilePath;
  String? _selectedPlatform; // alipay, wechat
  int? _selectedAccountId;
  bool _isImporting = false;
  ImportResult? _importResult;
  bool _isPreviewExpanded = false; // 预览是否展开

  @override
  void initState() {
    super.initState();
    // 初始化服务（异步）
    _initServices();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts();
    });
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
      _validationService = BillValidationService(aiClassifierService);
      _importService = BillImportService(validationService: _validationService);
    } catch (e) {
      // 如果初始化失败，创建不带验证的导入服务
      _importService = BillImportService();
    }
  }

  Future<void> _loadAccounts() async {
    await context.read<AccountProvider>().loadAccounts();
  }

  /// 更新平台选择
  void _updatePlatform(String platform) {
    setState(() {
      _selectedPlatform = platform;
      _selectedFilePath = null;
      _importResult = null;
      _isPreviewExpanded = false; // 重置预览展开状态

      // 同步更新账户选择
      final provider = context.read<AccountProvider>();
      final accounts = provider.visibleAccounts
          .where((account) => account.type == platform)
          .toList();

      // 如果当前选择的账户不在新平台的列表中，或者没有选择账户，选择第一个
      if (accounts.isNotEmpty &&
          (_selectedAccountId == null ||
              !accounts.any((account) => account.id == _selectedAccountId))) {
        _selectedAccountId = accounts.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入账单'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 平台选择
          _buildPlatformSelector(),
          const SizedBox(height: 16),

          // 账户选择
          _buildAccountSelector(),
          const SizedBox(height: 16),

          // 文件选择
          _buildFileSelector(),
          const SizedBox(height: 16),

          // 使用说明
          _buildInstructions(),
          const SizedBox(height: 16),

          // 预览区域
          if (_importResult != null) _buildPreview(),

          // 导入按钮
          if (_importResult != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _handleImport,
                child: _isImporting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('确认导入 ${_importResult!.transactions.length} 笔账单'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 平台选择
  Widget _buildPlatformSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. 选择平台',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.payment, color: Colors.blue),
                          SizedBox(height: 4),
                          Text('支付宝'),
                          Text('(.csv)', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    selected: _selectedPlatform == 'alipay',
                    onSelected: (selected) {
                      if (selected) {
                        _updatePlatform('alipay');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.chat, color: Colors.green),
                          SizedBox(height: 4),
                          Text('微信'),
                          Text('(.xlsx)', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                    selected: _selectedPlatform == 'wechat',
                    onSelected: (selected) {
                      if (selected) {
                        _updatePlatform('wechat');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 账户选择
  Widget _buildAccountSelector() {
    return Consumer<AccountProvider>(
      builder: (context, provider, child) {
        // 根据选择的平台过滤账户
        List<Account> accounts;
        if (_selectedPlatform != null) {
          accounts = provider.visibleAccounts
              .where((account) => account.type == _selectedPlatform)
              .toList();
        } else {
          accounts = provider.visibleAccounts;
        }

        if (accounts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(_selectedPlatform != null
                      ? '还没有${_selectedPlatform == 'alipay' ? '支付宝' : '微信'}账户'
                      : '还没有可用的账户'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('先去添加账户'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. 选择账户',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _selectedPlatform != null
                      ? '仅显示${_selectedPlatform == 'alipay' ? '支付宝' : '微信'}账户'
                      : '导入的账单将关联到此账户',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                  items: accounts.map((account) {
                    return DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAccountId = value;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 文件选择
  Widget _buildFileSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3. 选择文件',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectedPlatform == null ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedFilePath == null
                  ? '点击选择文件'
                  : '已选择: ${_selectedFilePath!.split('/').last}'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_selectedFilePath != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _parseFile,
                icon: const Icon(Icons.preview),
                label: const Text('解析并验证'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用说明
  Widget _buildInstructions() {
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
                  '使用说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: appColors.onInfoContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '支付宝账单导出：\n'
              '1. 打开支付宝APP → 我的 → 账单\n'
              '2. 右上角设置 → 开具交易流水证明\n'
              '3. 选择时间范围 → 申请邮箱接收\n'
              '4. 下载CSV文件',
              style: TextStyle(fontSize: 12, color: appColors.onInfoContainer),
            ),
            const SizedBox(height: 12),
            Text(
              '微信账单导出：\n'
              '1. 打开微信 → 我 → 服务 → 钱包\n'
              '2. 账单 → 常见问题 → 下载账单\n'
              '3. 选择时间范围 → 申请邮箱接收\n'
              '4. 下载XLSX文件（需解压）',
              style: TextStyle(fontSize: 12, color: appColors.onInfoContainer),
            ),
          ],
        ),
      ),
    );
  }

  /// 预览区域
  Widget _buildPreview() {
    final transactions = _importResult!.transactions;
    final displayCount = _isPreviewExpanded ? transactions.length : (transactions.length > 10 ? 10 : transactions.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '预览',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '共 ${transactions.length} 笔',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayCount,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final isIncome = transaction.type == 'income';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                  title: Text(transaction.description ?? '无描述'),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd HH:mm').format(transaction.transactionTime),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}¥${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () => _showTransactionDetail(transaction),
                );
              },
            ),
            if (transactions.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isPreviewExpanded = !_isPreviewExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isPreviewExpanded
                            ? '收起'
                            : '... 还有 ${transactions.length - 10} 笔未显示，点击展开',
                          style: const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isPreviewExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 选择文件
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _selectedPlatform == 'alipay' ? ['csv'] : ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _importResult = null;
          _isPreviewExpanded = false; // 重置预览展开状态
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 解析文件
  Future<void> _parseFile() async {
    if (_selectedFilePath == null || _selectedAccountId == null) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final file = File(_selectedFilePath!);
      ImportResult importResult;

      if (_selectedPlatform == 'alipay') {
        importResult = await _importService.importAlipayCSVWithValidation(
          file,
          _selectedAccountId!,
        );
      } else {
        importResult = await _importService.importWeChatExcelWithValidation(
          file,
          _selectedAccountId!,
        );
      }

      setState(() {
        _importResult = importResult;
        _isImporting = false;
        _isPreviewExpanded = false; // 重置预览展开状态
      });

      if (mounted) {
        // 显示解析结果和验证状态
        String message = '解析成功，共 ${importResult.transactions.length} 笔账单';
        if (importResult.validationResult != null) {
          final validation = importResult.validationResult!;
          if (validation.isValid) {
            message += '\n✓ 验证通过';
          } else {
            message += '\n⚠ 发现 ${validation.issues.length} 个问题';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: importResult.validationResult?.isValid == false
                ? Colors.orange
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示流水详情
  void _showTransactionDetail(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(transaction: transaction),
    );
  }

  /// 导入账单
  Future<void> _handleImport() async {
    if (_importResult == null || _importResult!.transactions.isEmpty) return;

    setState(() {
      _isImporting = true;
    });

    try {
      // 跳转到确认页面（会自动进行 AI 分类）
      if (!mounted) return;

      final savedCount = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => ImportConfirmationScreen(
            importResult: _importResult!,
          ),
        ),
      );

      setState(() {
        _isImporting = false;
      });

      if (!mounted) return;

      if (savedCount != null && savedCount > 0) {
        // 显示导入成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功导入 $savedCount 笔账单'),
            backgroundColor: Colors.green,
          ),
        );

        // 返回上一页
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
