import 'package:flutter/material.dart';

/// 完成页 - 引导最后一步
class CompletionStep extends StatelessWidget {
  final VoidCallback onComplete;

  const CompletionStep({
    super.key,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 成功图标
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green[700],
            ),
          ),

          const SizedBox(height: 32),

          // 标题
          Text(
            '设置完成！',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // 描述
          Text(
            '你已经完成了所有初始设置\n现在可以开始使用账清了',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 48),

          // 快速开始指南
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '快速开始',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildQuickStartItem(
                  context,
                  icon: Icons.add_circle_outline,
                  title: '记录第一笔交易',
                  description: '点击首页的 + 按钮开始记账',
                ),
                const SizedBox(height: 16),
                _buildQuickStartItem(
                  context,
                  icon: Icons.file_upload,
                  title: '导入账单',
                  description: '从支付宝、微信导入历史账单',
                ),
                const SizedBox(height: 16),
                _buildQuickStartItem(
                  context,
                  icon: Icons.analytics,
                  title: '查看分析',
                  description: '了解你的消费习惯和趋势',
                ),
              ],
            ),
          ),

          const Spacer(),

          // 开始使用按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onComplete,
              child: const Text('开始使用账清'),
            ),
          ),

          const SizedBox(height: 16),

          // 提示文字
          Text(
            '你可以随时在设置中查看使用帮助',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// 构建快速开始项
  Widget _buildQuickStartItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
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
