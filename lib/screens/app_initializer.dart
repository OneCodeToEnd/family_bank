import 'package:flutter/material.dart';
import '../services/onboarding/onboarding_service.dart';
import 'onboarding/onboarding_screen.dart';
import 'home/home_page.dart';

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
    try {
      final isCompleted = await _onboardingService.isOnboardingCompleted();
      setState(() {
        _shouldShowOnboarding = !isCompleted;
        _isChecking = false;
      });
    } catch (e) {
      // 如果检查失败，默认显示引导
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
