import 'package:flutter/material.dart';
import '../../../providers/family_provider.dart';

/// 欢迎卡片组件
class WelcomeCard extends StatelessWidget {
  final FamilyProvider familyProvider;
  final VoidCallback onCreateFamily;

  const WelcomeCard({
    super.key,
    required this.familyProvider,
    required this.onCreateFamily,
  });

  @override
  Widget build(BuildContext context) {
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
                onPressed: onCreateFamily,
                icon: const Icon(Icons.add),
                label: const Text('立即创建'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
