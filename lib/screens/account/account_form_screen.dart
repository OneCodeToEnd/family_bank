import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/account.dart';
import '../../constants/db_constants.dart';
import '../member/member_form_screen.dart';

/// 添加/编辑账户页面
class AccountFormScreen extends StatefulWidget {
  final Account? account;

  const AccountFormScreen({super.key, this.account});

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedMemberId;
  String _selectedType = AccountType.alipay;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _notesController.text = widget.account!.notes ?? '';
      _selectedMemberId = widget.account!.familyMemberId;
      _selectedType = widget.account!.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '编辑账户' : '添加账户'),
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, familyProvider, child) {
          final members = familyProvider.currentGroupMembers;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('请先创建家庭成员'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // 快速添加成员
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemberFormScreen(),
                        ),
                      );
                      if (result == true && mounted) {
                        // 重新加载成员列表
                        await familyProvider.loadFamilyMembers();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('添加成员'),
                  ),
                ],
              ),
            );
          }

          // 如果是新建且没有选择成员，默认选择第一个
          if (!isEditing && _selectedMemberId == null && members.isNotEmpty) {
            _selectedMemberId = members.first.id;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 选择成员
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '账户所属',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                // 快速添加成员
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MemberFormScreen(),
                                  ),
                                );
                                if (result == true && mounted) {
                                  // 重新加载成员列表
                                  await familyProvider.loadFamilyMembers();
                                }
                              },
                              icon: const Icon(Icons.person_add, size: 18),
                              label: const Text('添加成员'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedMemberId,
                          decoration: const InputDecoration(
                            labelText: '选择成员',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: members.map((member) {
                            return DropdownMenuItem(
                              value: member.id,
                              child: Text('${member.name} ${member.role ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMemberId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return '请选择成员';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 账户信息
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '账户信息',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        // 账户名称
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '账户名称',
                            hintText: '例如：爸爸的支付宝',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入账户名称';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 账户类型
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: '账户类型',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: AccountType.all.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  _getAccountTypeIcon(type),
                                  const SizedBox(width: 8),
                                  Text(AccountType.getDisplayName(type)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // 备注
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: '备注（可选）',
                            hintText: '账户的额外说明',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 提交按钮
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? '保存' : '添加'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getAccountTypeIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case AccountType.alipay:
        iconData = Icons.account_balance;
        color = Colors.blue;
        break;
      case AccountType.wechat:
        iconData = Icons.chat;
        color = Colors.green;
        break;
      case AccountType.bank:
        iconData = Icons.account_balance;
        color = Colors.orange;
        break;
      case AccountType.cash:
        iconData = Icons.money;
        color = Colors.brown;
        break;
      default:
        iconData = Icons.account_balance_wallet;
        color = Colors.grey;
    }

    return Icon(iconData, color: color, size: 20);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final accountProvider = context.read<AccountProvider>();
    final isEditing = widget.account != null;

    bool success;
    if (isEditing) {
      // 编辑账户
      final updatedAccount = widget.account!.copyWith(
        familyMemberId: _selectedMemberId!,
        name: _nameController.text.trim(),
        type: _selectedType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      success = await accountProvider.updateAccount(updatedAccount);
    } else {
      // 添加账户
      success = await accountProvider.createAccount(
        familyMemberId: _selectedMemberId!,
        name: _nameController.text.trim(),
        type: _selectedType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '账户已更新' : '账户已添加'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accountProvider.errorMessage ?? '操作失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
