import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/family_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/counterparty_provider.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/transaction/transaction_list_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../services/sync/auto_sync_service.dart';
import 'widgets/welcome_card.dart';
import 'widgets/statistics_section.dart';
import 'widgets/quick_actions_section.dart';
import 'widgets/error_view.dart';

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
      // 获取所有 Provider
      final familyProvider = context.read<FamilyProvider>();
      final homeProvider = context.read<HomeProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      final accountProvider = context.read<AccountProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      final settingsProvider = context.read<SettingsProvider>();
      final counterpartyProvider = context.read<CounterpartyProvider>();

      // 并行初始化所有 Provider
      await Future.wait([
        familyProvider.initialize(),
        categoryProvider.initialize(),
        accountProvider.initialize(),
        transactionProvider.initialize(),
        settingsProvider.initialize(),
        counterpartyProvider.initialize(),
      ]);

      // 初始化自动同步服务
      final autoSyncService = AutoSyncService();
      await autoSyncService.initialize();

      setState(() {
        _isInitialized = true;
      });

      // 加载首页统计数据，使用当前家庭ID
      final familyId = familyProvider.currentFamilyGroup?.id;
      await homeProvider.loadStatistics(familyId: familyId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // 错误会在 HomeProvider 中处理
      }
    }
  }

  /// 刷新首页数据
  Future<void> _refreshHomePage() async {
    final familyProvider = context.read<FamilyProvider>();
    final homeProvider = context.read<HomeProvider>();
    final familyId = familyProvider.currentFamilyGroup?.id;
    await homeProvider.refresh(familyId: familyId);
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
          Consumer<HomeProvider>(
            builder: (context, homeProvider, child) {
              return IconButton(
                icon: homeProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: '刷新统计',
                onPressed: homeProvider.isLoading ? null : _refreshHomePage,
              );
            },
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
        child: Consumer2<FamilyProvider, HomeProvider>(
          builder: (context, familyProvider, homeProvider, child) {
            // 显示错误视图
            if (homeProvider.errorMessage != null) {
              return ErrorView(
                errorMessage: homeProvider.errorMessage!,
                onRetry: _refreshHomePage,
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 欢迎卡片
                WelcomeCard(
                  familyProvider: familyProvider,
                  onCreateFamily: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OnboardingScreen(),
                      ),
                    );
                    if (result == true && mounted) {
                      await familyProvider.initialize();
                      await _refreshHomePage();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 统计卡片
                StatisticsSection(
                  statistics: homeProvider.statistics,
                  isLoading: homeProvider.isLoading,
                ),
                const SizedBox(height: 16),

                // 快速操作
                QuickActionsSection(
                  onRefresh: _refreshHomePage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
