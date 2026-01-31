import 'package:flutter/material.dart';

/// 欢迎页 - 引导第一步
class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({
    super.key,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 应用图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 32),

          // 应用名称
          Text(
            '欢迎使用账清',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // 应用介绍
          Text(
            '家庭财务管理助手',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 48),

          // 功能介绍
          _buildFeatureItem(
            context,
            icon: Icons.people,
            title: '多账户管理',
            description: '支持支付宝、微信、银行卡等多种账户',
          ),

          const SizedBox(height: 16),

          _buildFeatureItem(
            context,
            icon: Icons.category,
            title: '智能分类',
            description: 'AI 自动分类，支持自定义规则学习',
          ),

          const SizedBox(height: 16),

          _buildFeatureItem(
            context,
            icon: Icons.file_upload,
            title: '账单导入',
            description: '一键导入支付宝、微信账单',
          ),

          const SizedBox(height: 16),

          _buildFeatureItem(
            context,
            icon: Icons.analytics,
            title: '数据分析',
            description: '可视化图表，洞察消费习惯',
          ),

          const SizedBox(height: 48),

          // 开始按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onNext,
              child: const Text('开始使用'),
            ),
          ),

          const SizedBox(height: 16),

          // 提示文字
          Text(
            '只需 3 分钟完成初始设置',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// 构建功能介绍项
  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
