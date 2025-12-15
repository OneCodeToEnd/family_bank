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
    } catch (e) {
      debugPrint('初始化失败: $e');
    }
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
      body: Consumer4<FamilyProvider, AccountProvider, CategoryProvider,
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
              _buildStatisticsCards(transactionProvider),
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

  /// 统计卡片
  Widget _buildStatisticsCards(TransactionProvider transactionProvider) {
    final transactions = transactionProvider.transactions;
    final incomeCount = transactions.where((t) => t.type == 'income').length;
    final expenseCount = transactions.where((t) => t.type == 'expense').length;

    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.arrow_downward, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text('收入笔数'),
                  Text(
                    '$incomeCount',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.arrow_upward, color: Colors.red),
                  const SizedBox(height: 8),
                  const Text('支出笔数'),
                  Text(
                    '$expenseCount',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
