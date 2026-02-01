import 'package:flutter/material.dart';
import '../services/onboarding/onboarding_service.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_page.dart';
import '../utils/app_logger.dart';

/// 应用初始化页面
/// 检查引导状态并决定显示引导页面还是主页
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _isChecking = true;
  bool _shouldShowOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    AppLogger.i('[AppInitializer] 🚀 应用启动，检查引导状态');

    try {
      final isCompleted = await _onboardingService.isOnboardingCompleted();
      AppLogger.i('[AppInitializer] 引导状态检查结果: ${isCompleted ? "已完成" : "未完成"}');

      setState(() {
        _shouldShowOnboarding = !isCompleted;
        _isChecking = false;
      });

      if (_shouldShowOnboarding) {
        AppLogger.i('[AppInitializer] ➡️ 将显示新手引导页面');
      } else {
        AppLogger.i('[AppInitializer] ➡️ 将显示主页');
      }
    } catch (e, stackTrace) {
      // 如果检查失败，默认显示引导
      AppLogger.e('[AppInitializer] 检查引导状态失败，默认显示引导', error: e, stackTrace: stackTrace);
      setState(() {
        _shouldShowOnboarding = true;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // 显示加载页面
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化...'),
            ],
          ),
        ),
      );
    }

    // 根据引导状态显示对应页面
    return _shouldShowOnboarding
        ? const OnboardingScreen()
        : const HomePage();
  }
}
