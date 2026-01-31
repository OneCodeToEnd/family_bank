import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/family_provider.dart';
import 'providers/account_provider.dart';
import 'providers/category_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/home_provider.dart';
import 'screens/home/home_page.dart';
import 'theme/app_colors.dart';

void main() {
  // 初始化桌面平台的数据库工厂
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // 初始化 FFI
    sqfliteFfiInit();
    // 设置全局数据库工厂为 FFI 实现
    databaseFactory = databaseFactoryFfi;
  }

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
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
