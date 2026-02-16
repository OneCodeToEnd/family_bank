import 'package:flutter/material.dart';
import '../../../models/quick_action.dart';
import '../../../services/quick_action_service.dart';
import '../../../services/database/email_config_db_service.dart';
import '../../../screens/account/account_list_screen.dart';
import '../../../screens/category/category_list_screen.dart';
import '../../../screens/import/bill_import_screen.dart';
import '../../../screens/analysis/analysis_screen.dart';
import '../../../screens/transaction/transaction_form_screen.dart';
import '../../../screens/transaction/transaction_list_screen.dart';
import '../../../screens/member/member_list_screen.dart';
import '../../../screens/settings/ai_settings_screen.dart';
import '../../../screens/category/category_rule_list_screen.dart';
import '../../../screens/budget/budget_overview_screen.dart';
import '../../../screens/counterparty/counterparty_management_screen.dart';
import '../../../screens/chat/chat_screen.dart';
import '../../../screens/import/email_bill_select_screen.dart';
import '../../../screens/settings/email_config_screen.dart';
import '../../../screens/settings/quick_action_settings_screen.dart';

/// 快速操作区域组件
class QuickActionsSection extends StatefulWidget {
  final VoidCallback onRefresh;

  const QuickActionsSection({
    super.key,
    required this.onRefresh,
  });

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  late Future<List<QuickAction>> _quickActionsFuture;
  final QuickActionService _quickActionService = QuickActionService();

  @override
  void initState() {
    super.initState();
    _quickActionsFuture = _quickActionService.loadQuickActions();
  }

  /// 刷新快捷操作配置
  void _refreshQuickActions() {
    setState(() {
      _quickActionsFuture = _quickActionService.loadQuickActions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '快速操作',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  tooltip: '设置快捷操作',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickActionSettingsScreen(),
                      ),
                    );
                    // 返回后刷新快捷操作
                    _refreshQuickActions();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 使用 FutureBuilder 实时查询快捷操作配置
            FutureBuilder<List<QuickAction>>(
              future: _quickActionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败: ${snapshot.error}'),
                  );
                }

                final actions = snapshot.data ?? [];

                // 使用 GridView 支持 4-8 个按钮
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _buildQuickActionButton(
                      icon: action.icon,
                      label: action.name,
                      onTap: () => _navigateToScreen(action.routeName),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 根据路由名称导航到对应页面
  void _navigateToScreen(String routeName) async {
    late Widget screen;

    switch (routeName) {
      case 'AccountListScreen':
        screen = const AccountListScreen();
        break;
      case 'CategoryListScreen':
        screen = const CategoryListScreen();
        break;
      case 'BillImportScreen':
        screen = const BillImportScreen();
        break;
      case 'AnalysisScreen':
        screen = const AnalysisScreen();
        break;
      case 'TransactionFormScreen':
        screen = const TransactionFormScreen();
        break;
      case 'TransactionListScreen':
        screen = const TransactionListScreen();
        break;
      case 'MemberListScreen':
        screen = const MemberListScreen();
        break;
      case 'AISettingsScreen':
        screen = const AISettingsScreen();
        break;
      case 'CategoryRuleListScreen':
        screen = const CategoryRuleListScreen();
        break;
      case 'BudgetOverviewScreen':
        screen = const BudgetOverviewScreen();
        break;
      case 'CounterpartyManagementScreen':
        screen = const CounterpartyManagementScreen();
        break;
      case 'ChatScreen':
        screen = const ChatScreen();
        break;
      case 'EmailBillSelectScreen':
        // 邮箱同步需要特殊处理
        await _navigateToEmailSync();
        return;
      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('未知的页面: $routeName')),
          );
        }
        return;
    }

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
      // 返回后刷新首页数据
      widget.onRefresh();
    }
  }

  /// 邮箱同步特殊处理（需要检查配置）
  Future<void> _navigateToEmailSync() async {
    final dbService = EmailConfigDbService();
    final hasConfig = await dbService.hasConfig();

    if (!mounted) return;

    if (hasConfig) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailBillSelectScreen(),
        ),
      );
      widget.onRefresh();
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailConfigScreen(),
        ),
      );

      if (result == true && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailBillSelectScreen(),
          ),
        );
        widget.onRefresh();
      }
    }
  }
}
