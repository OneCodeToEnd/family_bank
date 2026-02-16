import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/family_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/home_provider.dart';
import 'providers/counterparty_provider.dart';
import 'providers/backup/backup_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/app_initializer.dart';
import 'theme/app_colors.dart';

// 条件导入：仅在非 Web 平台导入
import 'services/database/database_init_stub.dart'
    if (dart.library.io) 'services/database/database_init_io.dart';

void main() {
  // 初始化数据库（桌面平台需要 FFI 支持）
  initializeDatabaseFactory();

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
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => CounterpartyProvider()),
        ChangeNotifierProvider(create: (_) => BackupProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
              extensions: const <ThemeExtension<dynamic>>[
                AppColors.light,
              ],
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              extensions: const <ThemeExtension<dynamic>>[
                AppColors.dark,
              ],
            ),
            home: const AppInitializer(),
          );
        },
      ),
    );
  }
}
