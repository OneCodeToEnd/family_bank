import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/family_provider.dart';
import '../../services/database/database_service.dart';
import '../member/member_list_screen.dart';
import '../budget/budget_overview_screen.dart';
import 'ai_settings_screen.dart';
import '../category/category_rule_list_screen.dart';
import 'email_config_screen.dart';
import '../import/email_bill_select_screen.dart';
import '../../services/database/email_config_db_service.dart';
import 'quick_action_settings_screen.dart';
import '../../services/quick_action_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../../services/onboarding/onboarding_service.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  String _appBuildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _appBuildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // 如果获取失败，使用默认值
      setState(() {
        _appVersion = '1.0.0';
        _appBuildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return ListView(
            children: [
              // 外观设置
              _buildSectionHeader('外观设置'),
              _buildThemeTile(settingsProvider),

              const Divider(),

              // 家庭管理
              _buildSectionHeader('家庭管理'),
              _buildMemberManagementTile(),

              const Divider(),

              // 功能设置
              _buildSectionHeader('功能设置'),
              _buildBudgetManagementTile(),
              _buildQuickActionSettingsTile(),
              _buildAISettingsTile(),
              _buildCategoryRulesTile(),
              // TODO: 自动备份功能待实现，暂时隐藏
              // _buildAutoBackupTile(settingsProvider),
              _buildDefaultAccountTile(),
              _buildDefaultCategoryTile(),

              const Divider(),

              // 数据管理
              _buildSectionHeader('数据管理'),
              _buildEmailSyncTile(),
              _buildDataStatsTile(),
              _buildClearDataTile(),

              const Divider(),

              // 关于
              _buildSectionHeader('关于'),
              _buildOnboardingTile(),
              _buildAboutTile(),
              _buildVersionTile(),
            ],
          );
        },
      ),
    );
  }

  /// 章节标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  /// 主题设置
  Widget _buildThemeTile(SettingsProvider provider) {
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('主题模式'),
      subtitle: Text(_getThemeModeText(provider.themeMode)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(provider),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  /// 主题选择对话框
  void _showThemeDialog(SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('浅色'),
                value: ThemeMode.light,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('深色'),
                value: ThemeMode.dark,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
                groupValue: provider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    provider.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 家庭成员管理
  Widget _buildMemberManagementTile() {
    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, child) {
        final memberCount = familyProvider.currentGroupMembers.length;
        return ListTile(
          leading: const Icon(Icons.people),
          title: const Text('家庭成员管理'),
          subtitle: Text('$memberCount 位成员'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MemberListScreen(),
              ),
            );
          },
        );
      },
    );
  }

  /// 首页快捷操作设置
  Widget _buildQuickActionSettingsTile() {
    return FutureBuilder<List<dynamic>>(
      future: QuickActionService().loadQuickActions(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return ListTile(
          leading: const Icon(Icons.dashboard_customize),
          title: const Text('首页快捷操作'),
          subtitle: Text('已选择 $count 个快捷操作'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuickActionSettingsScreen(),
              ),
            );
          },
        );
      },
    );
  }

  /// 预算管理
  Widget _buildBudgetManagementTile() {
    return ListTile(
      leading: const Icon(Icons.account_balance_wallet),
      title: const Text('预算管理'),
      subtitle: const Text('设置和管理年度预算'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BudgetOverviewScreen(),
          ),
        );
      },
    );
  }

  /// AI 分类设置
  Widget _buildAISettingsTile() {
    return ListTile(
      leading: const Icon(Icons.smart_toy),
      title: const Text('AI 分类设置'),
      subtitle: const Text('配置智能分类功能'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AISettingsScreen(),
          ),
        );
      },
    );
  }

  /// 分类规则管理
  Widget _buildCategoryRulesTile() {
    return ListTile(
      leading: const Icon(Icons.rule),
      title: const Text('分类规则管理'),
      subtitle: const Text('查看和管理分类规则'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoryRuleListScreen(),
          ),
        );
      },
    );
  }

  /// 自动备份开关
  /// TODO: 功能待实现，暂时隐藏。需要实现：
  /// 1. BackupService - 数据库导出服务
  /// 2. 定时任务调度（workmanager）
  /// 3. 备份文件管理和恢复功能
  Widget _buildAutoBackupTile(SettingsProvider provider) {
    return SwitchListTile(
      secondary: const Icon(Icons.backup),
      title: const Text('自动备份'),
      subtitle: const Text('每天自动备份数据'),
      value: provider.autoBackup,
      onChanged: (value) {
        provider.setAutoBackup(value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? '自动备份已启用' : '自动备份已关闭'),
          ),
        );
      },
    );
  }

  /// 默认账户
  Widget _buildDefaultAccountTile() {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        final defaultAccountId =
            context.watch<SettingsProvider>().defaultAccountId;
        final defaultAccount = defaultAccountId != null
            ? accountProvider.accounts
                .where((a) => a.id == defaultAccountId)
                .firstOrNull
            : null;

        return ListTile(
          leading: const Icon(Icons.account_balance_wallet),
          title: const Text('默认账户'),
          subtitle: Text(defaultAccount?.name ?? '未设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAccountSelector(accountProvider),
        );
      },
    );
  }

  void _showAccountSelector(AccountProvider accountProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final settingsProvider = context.read<SettingsProvider>();
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择默认账户',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('不设置'),
                selected: settingsProvider.defaultAccountId == null,
                onTap: () {
                  settingsProvider.setDefaultAccount(null);
                  Navigator.pop(context);
                },
              ),
              ...accountProvider.accounts.map((account) {
                return ListTile(
                  title: Text(account.name),
                  subtitle: Text(account.type),
                  selected: settingsProvider.defaultAccountId == account.id,
                  onTap: () {
                    settingsProvider.setDefaultAccount(account.id);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// 默认分类
  Widget _buildDefaultCategoryTile() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final defaultCategoryId =
            context.watch<SettingsProvider>().defaultCategoryId;
        final defaultCategory = defaultCategoryId != null
            ? categoryProvider.categories
                .where((c) => c.id == defaultCategoryId)
                .firstOrNull
            : null;

        return ListTile(
          leading: const Icon(Icons.category),
          title: const Text('默认分类'),
          subtitle: Text(defaultCategory?.name ?? '未设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showCategorySelector(categoryProvider),
        );
      },
    );
  }

  void _showCategorySelector(CategoryProvider categoryProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final settingsProvider = context.read<SettingsProvider>();
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '选择默认分类',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('不设置'),
                selected: settingsProvider.defaultCategoryId == null,
                onTap: () {
                  settingsProvider.setDefaultCategory(null);
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: ListView(
                  children: categoryProvider.categories.map((category) {
                    return ListTile(
                      title: Text(category.name),
                      subtitle: Text(category.type == 'income' ? '收入' : '支出'),
                      selected:
                          settingsProvider.defaultCategoryId == category.id,
                      onTap: () {
                        settingsProvider.setDefaultCategory(category.id);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 邮箱账单同步
  Widget _buildEmailSyncTile() {
    return ListTile(
      leading: const Icon(Icons.email),
      title: const Text('邮箱账单同步'),
      subtitle: const Text('从邮箱自动导入账单'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final dbService = EmailConfigDbService();
        final hasConfig = await dbService.hasConfig();

        if (!mounted) return;

        if (hasConfig) {
          // 已配置，直接进入邮件选择页面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmailBillSelectScreen(),
            ),
          );
        } else {
          // 未配置，先进入配置页面
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const EmailConfigScreen(),
            ),
          );

          // 配置成功后，进入邮件选择页面
          if (result == true && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmailBillSelectScreen(),
              ),
            );
          }
        }
      },
    );
  }

  /// 数据统计
  Widget _buildDataStatsTile() {
    return ListTile(
      leading: const Icon(Icons.storage),
      title: const Text('数据统计'),
      subtitle: Consumer4<FamilyProvider, AccountProvider, CategoryProvider,
          TransactionProvider>(
        builder: (context, familyProvider, accountProvider, categoryProvider,
            transactionProvider, child) {
          final stats =
              '${familyProvider.familyGroups.length} 个家庭组 · ${accountProvider.accounts.length} 个账户 · ${transactionProvider.transactions.length} 条账单';
          return Text(stats);
        },
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showDataStatsDialog();
      },
    );
  }

  void _showDataStatsDialog() {
    final familyProvider = context.read<FamilyProvider>();
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('数据统计'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('家庭组', familyProvider.familyGroups.length),
              _buildStatRow('家庭成员', familyProvider.familyMembers.length),
              _buildStatRow('账户', accountProvider.accounts.length),
              _buildStatRow('分类', categoryProvider.categories.length),
              _buildStatRow('账单', transactionProvider.transactions.length),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 清空数据
  Widget _buildClearDataTile() {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('清空数据', style: TextStyle(color: Colors.red)),
      subtitle: const Text('删除所有本地数据'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showClearDataWarning,
    );
  }

  void _showClearDataWarning() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空数据'),
          content: const Text(
            '此操作将删除所有本地数据，包括：\n\n'
            '• 所有账单记录\n'
            '• 所有账户信息\n'
            '• 所有分类信息\n'
            '• 所有家庭组和成员\n\n'
            '此操作不可恢复，确定要继续吗？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmClearData();
              },
              child: const Text('确定', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('最后确认'),
          content: const Text('请再次确认是否要清空所有数据？此操作不可撤销！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearAllData();
              },
              child: const Text('确定清空', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearAllData() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在清空数据...'),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      // 清空数据库
      final dbService = DatabaseService();
      await dbService.deleteDatabase();

      // 重新初始化所有 Provider
      if (mounted) {
        final familyProvider = context.read<FamilyProvider>();
        final accountProvider = context.read<AccountProvider>();
        final categoryProvider = context.read<CategoryProvider>();
        final transactionProvider = context.read<TransactionProvider>();

        await familyProvider.initialize();
        await accountProvider.initialize();
        await categoryProvider.initialize();
        await transactionProvider.initialize();
      }

      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据已清空'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清空数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 新手引导
  Widget _buildOnboardingTile() {
    return ListTile(
      leading: const Icon(Icons.school),
      title: const Text('新手引导'),
      subtitle: const Text('重新查看应用使用教程'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showOnboarding,
    );
  }

  /// 关于
  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('关于账清'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showAboutDialog,
    );
  }

  /// 显示新手引导
  void _showOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新查看引导'),
        content: const Text('这将重新显示新手引导教程，帮助你了解应用的使用方法。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              // 重置引导状态
              final onboardingService = OnboardingService();
              await onboardingService.resetOnboarding();

              if (!mounted) return;
              navigator.pop(); // 关闭对话框

              // 跳转到引导页面
              navigator.push(
                MaterialPageRoute(
                  builder: (_) => const OnboardingScreen(),
                ),
              );
            },
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '账清',
      applicationVersion: '$_appVersion ($_appBuildNumber)',
      applicationIcon: const Icon(Icons.account_balance, size: 48),
      applicationLegalese: '© 2024 账清团队\n保留所有权利',
      children: [
        const SizedBox(height: 16),
        const Text('个人账单流水分析APP'),
        const SizedBox(height: 8),
        const Text('帮助您轻松管理家庭账务'),
      ],
    );
  }

  /// 版本信息
  Widget _buildVersionTile() {
    return ListTile(
      leading: const Icon(Icons.update),
      title: const Text('版本信息'),
      subtitle: Text('v$_appVersion (Build $_appBuildNumber)'),
    );
  }
}
