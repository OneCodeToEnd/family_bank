import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/account_provider.dart';
import '../../services/import/bill_import_service.dart';
import '../../models/transaction.dart' as model;
import 'import_confirmation_screen.dart';

/// 账单导入页面
class BillImportScreen extends StatefulWidget {
  const BillImportScreen({super.key});

  @override
  State<BillImportScreen> createState() => _BillImportScreenState();
}

class _BillImportScreenState extends State<BillImportScreen> {
  final _importService = BillImportService();

  String? _selectedFilePath;
  String? _selectedPlatform; // alipay, wechat
  int? _selectedAccountId;
  bool _isImporting = false;
  List<model.Transaction>? _previewTransactions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts();
    });
  }

  Future<void> _loadAccounts() async {
    await context.read<AccountProvider>().loadAccounts();
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
          if (_previewTransactions != null) _buildPreview(),

          // 导入按钮
          if (_previewTransactions != null) ...[
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
                    : Text('确认导入 ${_previewTransactions!.length} 笔账单'),
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
                        setState(() {
                          _selectedPlatform = 'alipay';
                          _selectedFilePath = null;
                          _previewTransactions = null;
                        });
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
                        setState(() {
                          _selectedPlatform = 'wechat';
                          _selectedFilePath = null;
                          _previewTransactions = null;
                        });
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
        final accounts = provider.visibleAccounts;

        if (accounts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('还没有可用的账户'),
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

        // 默认选择第一个
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedAccountId = accounts.first.id;
              });
            }
          });
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
                const Text(
                  '导入的账单将关联到此账户',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                label: const Text('解析预览'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 使用说明
  Widget _buildInstructions() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '使用说明',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '支付宝账单导出：\n'
              '1. 打开支付宝APP → 我的 → 账单\n'
              '2. 右上角设置 → 开具交易流水证明\n'
              '3. 选择时间范围 → 申请邮箱接收\n'
              '4. 下载CSV文件',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              '微信账单导出：\n'
              '1. 打开微信 → 我 → 服务 → 钱包\n'
              '2. 账单 → 常见问题 → 下载账单\n'
              '3. 选择时间范围 → 申请邮箱接收\n'
              '4. 下载XLSX文件（需解压）',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// 预览区域
  Widget _buildPreview() {
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
                  '共 ${_previewTransactions!.length} 笔',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _previewTransactions!.take(10).length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final transaction = _previewTransactions![index];
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
                );
              },
            ),
            if (_previewTransactions!.length > 10) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '... 还有 ${_previewTransactions!.length - 10} 笔未显示',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
          _previewTransactions = null;
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
      List<model.Transaction> transactions;

      if (_selectedPlatform == 'alipay') {
        transactions = await _importService.importAlipayCSV(file, _selectedAccountId!);
      } else {
        transactions = await _importService.importWeChatExcel(file, _selectedAccountId!);
      }

      setState(() {
        _previewTransactions = transactions;
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('解析成功，共 ${transactions.length} 笔账单'),
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

  /// 导入账单
  Future<void> _handleImport() async {
    if (_previewTransactions == null || _previewTransactions!.isEmpty) return;

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
            transactions: _previewTransactions!,
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
