import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/family_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/budget_provider.dart';
import 'screens/account/account_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/transaction/transaction_list_screen.dart';
import 'screens/transaction/transaction_form_screen.dart';
import 'screens/category/category_list_screen.dart';
import 'screens/import/bill_import_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/quick_action_settings_screen.dart';
import 'screens/settings/ai_settings_screen.dart';
import 'screens/settings/email_config_screen.dart';
import 'screens/member/member_list_screen.dart';
import 'screens/category/category_rule_list_screen.dart';
import 'screens/import/email_bill_select_screen.dart';
import 'screens/budget/budget_overview_screen.dart';
import 'services/database/transaction_db_service.dart';
import 'services/database/email_config_db_service.dart';
import 'services/database/annual_budget_db_service.dart';
import 'services/quick_action_service.dart';
import 'models/quick_action.dart';
import 'utils/app_logger.dart';

void main() {
  runApp(const FamilyBankApp());
}

class FamilyBankApp extends StatelessWidget {
  const FamilyBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: '账清',
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

/// 主页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInitialized = false;
  Map<String, dynamic>? _homeStatistics;
  bool _isLoadingStats = false;
  late Future<List<QuickAction>> _quickActionsFuture;
  final QuickActionService _quickActionService = QuickActionService();

  // 预算进度数据
  Map<String, dynamic>? _yearlyIncomeBudget;
  Map<String, dynamic>? _yearlyExpenseBudget;
  Map<String, dynamic>? _monthlyIncomeBudget;
  Map<String, dynamic>? _monthlyExpenseBudget;

  @override
  void initState() {
    super.initState();
    _quickActionsFuture = _quickActionService.loadQuickActions();
    // 延迟到 build 之后再初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  /// 刷新快捷操作配置
  void _refreshQuickActions() {
    setState(() {
      _quickActionsFuture = _quickActionService.loadQuickActions();
    });
  }

  /// 初始化应用数据
  Future<void> _initializeApp() async {
    try {
      // 初始化所有 Provider
      final familyProvider = context.read<FamilyProvider>();
      final accountProvider = context.read<AccountProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final budgetProvider = context.read<BudgetProvider>();

      await Future.wait([
        familyProvider.initialize(),
        accountProvider.initialize(),
        categoryProvider.initialize(),
        transactionProvider.initialize(),
        settingsProvider.initialize(),
        budgetProvider.initialize(),
      ]);

      setState(() {
        _isInitialized = true;
      });

      // 加载统计数据
      await _loadHomeStatistics();
    } catch (e) {
      AppLogger.e('初始化失败', error: e);
    }
  }

  /// 加载首页统计数据
  Future<void> _loadHomeStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final dbService = TransactionDbService();
      final stats = await dbService.getHomePageStatistics();

      // 加载预算进度数据
      final budgetDbService = AnnualBudgetDbService();
      final now = DateTime.now();
      final familyId = 1; // TODO: 从 FamilyProvider 获取当前家庭ID

      final yearlyIncome = await budgetDbService.getTotalYearlyBudgetProgress(
        familyId,
        now.year,
        'income',
      );
      final yearlyExpense = await budgetDbService.getTotalYearlyBudgetProgress(
        familyId,
        now.year,
        'expense',
      );
      final monthlyIncome = await budgetDbService.getTotalMonthlyBudgetProgress(
        familyId,
        now.year,
        now.month,
        'income',
      );
      final monthlyExpense = await budgetDbService.getTotalMonthlyBudgetProgress(
        familyId,
        now.year,
        now.month,
        'expense',
      );

      // 调试日志
      AppLogger.d('年度收入预算: $yearlyIncome');
      AppLogger.d('年度支出预算: $yearlyExpense');
      AppLogger.d('月度收入预算: $monthlyIncome');
      AppLogger.d('月度支出预算: $monthlyExpense');

      if (mounted) {
        setState(() {
          _homeStatistics = stats;
          _yearlyIncomeBudget = yearlyIncome;
          _yearlyExpenseBudget = yearlyExpense;
          _monthlyIncomeBudget = monthlyIncome;
          _monthlyExpenseBudget = monthlyExpense;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      AppLogger.e('加载统计数据失败', error: e);
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  /// 刷新首页数据
  Future<void> _refreshHomePage() async {
    await _loadHomeStatistics();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化数据...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('账清'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoadingStats
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: '刷新统计',
            onPressed: _isLoadingStats ? null : _refreshHomePage,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: '账单列表',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransactionListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHomePage,
        child: Consumer4<FamilyProvider, AccountProvider, CategoryProvider,
            TransactionProvider>(
        builder: (context, familyProvider, accountProvider, categoryProvider,
            transactionProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 欢迎卡片
              _buildWelcomeCard(familyProvider),
              const SizedBox(height: 16),

              // 统计卡片
              _buildStatisticsCards(),
              const SizedBox(height: 16),

              // 快速操作
              _buildQuickActions(),
              const SizedBox(height: 16),

              // 数据概览
              _buildDataOverview(
                familyProvider,
                accountProvider,
                categoryProvider,
                transactionProvider,
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  /// 欢迎卡片
  Widget _buildWelcomeCard(FamilyProvider familyProvider) {
    final currentGroup = familyProvider.currentFamilyGroup;
    final memberCount = familyProvider.currentGroupMembers.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.waving_hand, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '你好！',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (currentGroup != null) ...[
              Text('当前家庭组: ${currentGroup.name}'),
              Text('成员数: $memberCount'),
            ] else ...[
              const Text('还没有创建家庭组'),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    // 重新初始化数据
                    await context.read<FamilyProvider>().initialize();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('立即创建'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 统计卡片 - 直接从数据库查询
  Widget _buildStatisticsCards() {
    if (_isLoadingStats) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_homeStatistics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('暂无统计数据')),
        ),
      );
    }

    final yearIncome = _homeStatistics!['year_income'] as double? ?? 0.0;
    final yearExpense = _homeStatistics!['year_expense'] as double? ?? 0.0;
    final monthIncome = _homeStatistics!['month_income'] as double? ?? 0.0;
    final monthExpense = _homeStatistics!['month_expense'] as double? ?? 0.0;

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final monthStart = DateTime(now.year, now.month, 1);

    return Column(
      children: [
        // 第一行：当年收入和支出
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '当年总收入',
                value: '¥${yearIncome.toStringAsFixed(2)}',
                subtitle: '${DateTime.now().year}年至今',
                icon: Icons.trending_up,
                color: Colors.green,
                filterType: 'income',
                filterStartDate: yearStart,
                filterEndDate: now,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '当年总支出',
                value: '¥${yearExpense.toStringAsFixed(2)}',
                subtitle: '${DateTime.now().year}年至今',
                icon: Icons.trending_down,
                color: Colors.red,
                filterType: 'expense',
                filterStartDate: yearStart,
                filterEndDate: now,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第二行：当月收入和支出
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '当月收入',
                value: '¥${monthIncome.toStringAsFixed(2)}',
                subtitle: '本月至今',
                icon: Icons.arrow_upward,
                color: Colors.green,
                filterType: 'income',
                filterStartDate: monthStart,
                filterEndDate: now,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '当月支出',
                value: '¥${monthExpense.toStringAsFixed(2)}',
                subtitle: '本月至今',
                icon: Icons.arrow_downward,
                color: Colors.red,
                filterType: 'expense',
                filterStartDate: monthStart,
                filterEndDate: now,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第三行：当年预算进度
        Row(
          children: [
            Expanded(
              child: _buildBudgetProgressCard(
                title: '当年收入预算',
                budgetData: _yearlyIncomeBudget,
                type: 'income',
                isYearly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBudgetProgressCard(
                title: '当年支出预算',
                budgetData: _yearlyExpenseBudget,
                type: 'expense',
                isYearly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 第四行：当月预算进度
        Row(
          children: [
            Expanded(
              child: _buildBudgetProgressCard(
                title: '当月收入预算',
                budgetData: _monthlyIncomeBudget,
                type: 'income',
                isYearly: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBudgetProgressCard(
                title: '当月支出预算',
                budgetData: _monthlyExpenseBudget,
                type: 'expense',
                isYearly: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建单个统计卡片
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? filterType,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionListScreen(
                initialType: filterType,
                initialStartDate: filterStartDate,
                initialEndDate: filterEndDate,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建预算进度卡片
  Widget _buildBudgetProgressCard({
    required String title,
    required Map<String, dynamic>? budgetData,
    required String type,
    required bool isYearly,
  }) {
    final color = type == 'income' ? Colors.green : Colors.red;
    final icon = isYearly
        ? (type == 'income' ? Icons.trending_up : Icons.trending_down)
        : (type == 'income' ? Icons.arrow_upward : Icons.arrow_downward);

    // 检查是否有预算
    final hasBudget = budgetData?['has_budget'] == true;

    if (!hasBudget) {
      // 无预算时显示引导设置
      return Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BudgetOverviewScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '未设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击设置预算',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 有预算时显示进度
    final totalBudget = budgetData!['total_budget'] as double;
    final totalActual = budgetData['total_actual'] as double;
    final percentage = budgetData['percentage'] as double;

    // 判断是否超预算
    final isOverBudget = totalActual > totalBudget;
    final displayColor = isOverBudget ? Colors.orange : color;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BudgetOverviewScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: displayColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: displayColor,
                    ),
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '¥${totalActual.toStringAsFixed(0)} / ¥${totalBudget.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 快速操作
  Widget _buildQuickActions() {
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
              style: const TextStyle(fontSize: 11),
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
  void _navigateToScreen(String routeName) {
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
      case 'EmailBillSelectScreen':
        // 邮箱同步需要特殊处理
        _navigateToEmailSync();
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未知的页面: $routeName')),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// 邮箱同步特殊处理（需要检查配置）
  Future<void> _navigateToEmailSync() async {
    final dbService = EmailConfigDbService();
    final hasConfig = await dbService.hasConfig();

    if (!mounted) return;

    if (hasConfig) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailBillSelectScreen(),
        ),
      );
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const EmailConfigScreen(),
        ),
      );

      if (result == true && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmailBillSelectScreen(),
          ),
        );
      }
    }
  }

  /// 数据概览
  Widget _buildDataOverview(
    FamilyProvider familyProvider,
    AccountProvider accountProvider,
    CategoryProvider categoryProvider,
    TransactionProvider transactionProvider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据概览',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildDataRow('家庭组', '${familyProvider.familyGroups.length}'),
            _buildDataRow('家庭成员', '${familyProvider.familyMembers.length}'),
            _buildDataRow('账户', '${accountProvider.accounts.length}'),
            _buildDataRow('分类', '${categoryProvider.categories.length}'),
            _buildDataRow('账单', '${transactionProvider.transactions.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
