import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_provider.dart';

/// 首次使用引导页面
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _memberNameController = TextEditingController();
  final _memberRoleController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberNameController.dispose();
    _memberRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('欢迎使用账清'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // 欢迎图标
            const Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // 欢迎文字
            Text(
              '开始使用',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '首先，让我们创建一个家庭组和第一个成员',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 家庭组信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.home, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '家庭组信息',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: '家庭组名称',
                        hintText: '例如：我的家庭',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.family_restroom),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入家庭组名称';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 成员信息卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '第一个成员',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _memberNameController,
                      decoration: const InputDecoration(
                        labelText: '成员姓名',
                        hintText: '例如：爸爸',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入成员姓名';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _memberRoleController,
                      decoration: const InputDecoration(
                        labelText: '角色（可选）',
                        hintText: '例如：父亲',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('开始使用'),
              ),
            ),
            const SizedBox(height: 16),

            // 提示文字
            Text(
              '提示：之后可以在设置中添加更多成员和账户',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final familyProvider = context.read<FamilyProvider>();

    try {
      // 创建家庭组
      final groupSuccess = await familyProvider.createFamilyGroup(
        _groupNameController.text.trim(),
      );

      if (!groupSuccess) {
        throw Exception('创建家庭组失败');
      }

      // 创建成员
      final currentGroup = familyProvider.currentFamilyGroup;
      if (currentGroup == null) {
        throw Exception('家庭组创建失败');
      }

      final memberSuccess = await familyProvider.createFamilyMember(
        familyGroupId: currentGroup.id!,
        name: _memberNameController.text.trim(),
        role: _memberRoleController.text.trim().isEmpty
            ? null
            : _memberRoleController.text.trim(),
      );

      if (!memberSuccess) {
        throw Exception('创建成员失败');
      }

      if (!mounted) return;

      // 成功，返回上一页
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建成功！')),
      );
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
