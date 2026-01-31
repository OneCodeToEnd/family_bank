import 'package:flutter/material.dart';
import '../../services/onboarding/onboarding_service.dart';
import '../home/home_page.dart';
import 'steps/welcome_step.dart';
import 'steps/family_group_step.dart';
import 'steps/family_member_step.dart';
import 'steps/account_step.dart';
import 'steps/ai_config_step.dart';
import 'steps/completion_step.dart';

/// 首次启动引导页面
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();

  int _currentPage = 0;
  final int _totalPages = 6;

  // 存储引导过程中创建的数据
  int? _createdGroupId;
  int? _createdMemberId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 前往下一页
  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 前往上一页
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 跳过引导
  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过引导'),
        content: const Text('跳过引导后，你需要手动完成初始设置。确定要跳过吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _onboardingService.markOnboardingCompleted();
              if (!mounted) return;
              navigator.pop(); // 关闭对话框
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
            child: const Text('确定跳过'),
          ),
        ],
      ),
    );
  }

  /// 完成引导
  Future<void> _completeOnboarding() async {
    await _onboardingService.markOnboardingCompleted();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部进度条和跳过按钮
            _buildTopBar(),

            // 页面内容
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 禁止手势滑动
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // 1. 欢迎页
                  WelcomeStep(
                    onNext: _nextPage,
                  ),

                  // 2. 创建家庭组
                  FamilyGroupStep(
                    onNext: (groupId) {
                      setState(() {
                        _createdGroupId = groupId;
                      });
                      _nextPage();
                    },
                    onBack: _previousPage,
                  ),

                  // 3. 添加家庭成员
                  FamilyMemberStep(
                    familyGroupId: _createdGroupId,
                    onNext: (memberId) {
                      setState(() {
                        _createdMemberId = memberId;
                      });
                      _nextPage();
                    },
                    onBack: _previousPage,
                  ),

                  // 4. 创建账户
                  AccountStep(
                    familyMemberId: _createdMemberId,
                    onNext: (_) => _nextPage(),
                    onBack: _previousPage,
                  ),

                  // 5. AI 配置（可选）
                  AIConfigStep(
                    onNext: _nextPage,
                    onSkip: _nextPage,
                    onBack: _previousPage,
                  ),

                  // 6. 完成页
                  CompletionStep(
                    onComplete: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部栏（进度条和跳过按钮）
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 进度条
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 跳过按钮（最后一页不显示）
          if (_currentPage < _totalPages - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: const Text('跳过'),
            ),
        ],
      ),
    );
  }
}
