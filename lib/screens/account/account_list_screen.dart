import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/family_provider.dart';
import '../../models/account.dart';
import '../../constants/db_constants.dart';
import 'account_form_screen.dart';

/// 账户列表页面
class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    // 使用 addPostFrameCallback 避免在 build 期间调用 setState
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
        title: const Text('账户管理'),
        actions: [
          IconButton(
            icon: Icon(_showHidden ? Icons.visibility_off : Icons.visibility),
            tooltip: _showHidden ? '隐藏已隐藏账户' : '显示已隐藏账户',
            onPressed: () {
              setState(() {
                _showHidden = !_showHidden;
              });
            },
          ),
        ],
      ),
      body: Consumer2<AccountProvider, FamilyProvider>(
        builder: (context, accountProvider, familyProvider, child) {
          if (accountProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (accountProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('错误: ${accountProvider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAccounts,
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final accounts = _showHidden
              ? accountProvider.accounts
              : accountProvider.visibleAccounts;

          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('还没有添加账户'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddAccount(context),
                    icon: const Icon(Icons.add),
                    label: const Text('添加账户'),
                  ),
                ],
              ),
            );
          }

          // 按成员分组显示账户
          final memberAccounts = <int, List<Account>>{};
          for (var account in accounts) {
            memberAccounts.putIfAbsent(account.familyMemberId, () => []);
            memberAccounts[account.familyMemberId]!.add(account);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberAccounts.length,
            itemBuilder: (context, index) {
              final memberId = memberAccounts.keys.elementAt(index);
              final member = familyProvider.getMemberById(memberId);
              final memberAccountList = memberAccounts[memberId]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 成员信息头部
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            child: Text(member?.name.substring(0, 1) ?? '?'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member?.name ?? '未知成员',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (member?.role != null)
                                  Text(
                                    member!.role!,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${memberAccountList.length} 个账户',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 账户列表
                    ...memberAccountList.map((account) =>
                        _buildAccountTile(context, account, accountProvider)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddAccount(context),
        icon: const Icon(Icons.add),
        label: const Text('添加账户'),
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    return ListTile(
      leading: _getAccountIcon(account.type),
      title: Text(account.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AccountType.getDisplayName(account.type)),
          if (account.notes != null && account.notes!.isNotEmpty)
            Text(
              account.notes!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (account.isHidden)
            const Icon(Icons.visibility_off, size: 20, color: Colors.grey),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(
              context,
              value,
              account,
              provider,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('编辑'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_visibility',
                child: Row(
                  children: [
                    Icon(account.isHidden
                        ? Icons.visibility
                        : Icons.visibility_off),
                    const SizedBox(width: 8),
                    Text(account.isHidden ? '显示' : '隐藏'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _navigateToEditAccount(context, account),
    );
  }

  Widget _getAccountIcon(String type) {
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

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(iconData, color: color),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Account account,
    AccountProvider provider,
  ) async {
    switch (action) {
      case 'edit':
        _navigateToEditAccount(context, account);
        break;
      case 'toggle_visibility':
        final messenger = ScaffoldMessenger.of(context);
        await provider.toggleAccountVisibility(account.id!);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(account.isHidden ? '账户已显示' : '账户已隐藏'),
            ),
          );
        }
        break;
      case 'delete':
        _confirmDelete(context, account, provider);
        break;
    }
  }

  void _confirmDelete(
    BuildContext context,
    Account account,
    AccountProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除账户"${account.name}"吗？\n\n此操作将同时删除该账户的所有账单记录，且无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final success = await provider.deleteAccount(account.id!);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? '账户已删除' : '删除失败'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddAccount(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountFormScreen(),
      ),
    );
  }

  void _navigateToEditAccount(BuildContext context, Account account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormScreen(account: account),
      ),
    );
  }
}
