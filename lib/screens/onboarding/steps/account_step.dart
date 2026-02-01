import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/account_provider.dart';
import '../../../constants/db_constants.dart';

/// 账户创建步骤
class AccountStep extends StatefulWidget {
  final int? familyMemberId;
  final Function(int accountId) onNext;
  final VoidCallback onBack;

  const AccountStep({
    super.key,
    required this.familyMemberId,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<AccountStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = AccountType.alipay;
  bool _isCreating = false;

  // 账户类型选项
  final List<Map<String, dynamic>> _accountTypes = [
    {
      'type': AccountType.alipay,
      'name': '支付宝',
      'icon': Icons.payment,
      'color': Colors.blue,
    },
    {
      'type': AccountType.wechat,
      'name': '微信',
      'icon': Icons.chat,
      'color': Colors.green,
    },
    {
      'type': AccountType.bank,
      'name': '银行卡',
      'icon': Icons.account_balance,
      'color': Colors.red,
    },
    {
      'type': AccountType.cash,
      'name': '现金',
      'icon': Icons.money,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    // 根据选择的类型设置默认名称
    _updateDefaultName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateDefaultName() {
    final typeInfo = _accountTypes.firstWhere(
      (t) => t['type'] == _selectedType,
      orElse: () => _accountTypes.first,
    );
    _nameController.text = '我的${typeInfo['name']}';
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.familyMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('家庭成员ID不存在，请返回重新创建'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final accountProvider = context.read<AccountProvider>();
      final success = await accountProvider.createAccount(
        name: _nameController.text.trim(),
        type: _selectedType,
        familyMemberId: widget.familyMemberId!,
      );

      if (!mounted) return;

      if (success) {
        // 获取刚创建的账户ID
        await accountProvider.loadAccounts();
        final accounts = accountProvider.accounts;
        if (accounts.isNotEmpty) {
          widget.onNext(accounts.last.id!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('创建账户失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isCreating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题
          Text(
            '第 3 步',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            '创建第一个账户',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            '选择你最常用的账户类型',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 32),

          // 表单
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 账户类型选择
                  Text(
                    '账户类型',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _accountTypes.length,
                    itemBuilder: (context, index) {
                      final typeInfo = _accountTypes[index];
                      final isSelected = _selectedType == typeInfo['type'];

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedType = typeInfo['type'];
                            _updateDefaultName();
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                typeInfo['icon'],
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : typeInfo['color'],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                typeInfo['name'],
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // 账户名称输入
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isCreating,
                    decoration: const InputDecoration(
                      labelText: '账户名称 *',
                      hintText: '例如：我的支付宝',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance_wallet),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入账户名称';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _createAccount(),
                  ),

                  const SizedBox(height: 24),

                  // 提示信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '后续可以添加更多账户，支持导入账单',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部按钮
          Row(
            children: [
              // 返回按钮
              OutlinedButton(
                onPressed: _isCreating ? null : widget.onBack,
                child: const Text('返回'),
              ),

              const SizedBox(width: 12),

              // 下一步按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createAccount,
                  child: _isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('下一步'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
