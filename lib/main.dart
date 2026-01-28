import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/family_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/account/account_list_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/transaction/transaction_list_screen.dart';
import 'screens/transaction/transaction_form_screen.dart';
import 'screens/category/category_list_screen.dart';
import 'screens/import/bill_import_screen.dart';
import 'screens/analysis/analysis_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/database/transaction_db_service.dart';

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

  @override
  void initState() {
    super.initState();
    // 延迟到 build 之后再初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
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

      await Future.wait([
        familyProvider.initialize(),
        accountProvider.initialize(),
        categoryProvider.initialize(),
        transactionProvider.initialize(),
        settingsProvider.initialize(),
      ]);

      setState(() {
        _isInitialized = true;
      });

      // 加载统计数据
      await _loadHomeStatistics();
    } catch (e) {
      debugPrint('初始化失败: $e');
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

      if (mounted) {
        setState(() {
          _homeStatistics = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('加载统计数据失败: $e');
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('记一笔'),
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

    final incomeCount = _homeStatistics!['income_count'] as int? ?? 0;
    final expenseCount = _homeStatistics!['expense_count'] as int? ?? 0;
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

        // 第三行：收入笔数和支出笔数
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '收入笔数',
                value: '$incomeCount',
                subtitle: '全部记录',
                icon: Icons.receipt,
                color: Colors.blue,
                filterType: 'income',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '支出笔数',
                value: '$expenseCount',
                subtitle: '全部记录',
                icon: Icons.receipt_long,
                color: Colors.orange,
                filterType: 'expense',
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

  /// 快速操作
  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.account_balance_wallet,
                  label: '账户管理',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountListScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.category,
                  label: '分类管理',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategoryListScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.file_upload,
                  label: '导入账单',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BillImportScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.analytics,
                  label: '数据分析',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalysisScreen(),
                      ),
                    );
                  },
                ),
              ],
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
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
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
