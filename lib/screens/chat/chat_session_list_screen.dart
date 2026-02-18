import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_session.dart';

class ChatSessionListScreen extends StatelessWidget {
  const ChatSessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会话历史')),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          final sessions = provider.sessions;
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  Text('暂无会话历史',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          )),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _SessionTile(
                session: session,
                isActive: session.id == provider.currentSessionId,
                onTap: () => Navigator.pop(context, session.id),
                onLongPress: () =>
                    _showSessionMenu(context, provider, session),
              );
            },
          );
        },
      ),
    );
  }

  void _showSessionMenu(
      BuildContext context, ChatProvider provider, ChatSession session) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(session.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(session.isPinned ? '取消置顶' : '置顶'),
              onTap: () {
                Navigator.pop(ctx);
                provider.togglePinSession(session.id);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('删除',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, provider, session);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ChatProvider provider, ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除会话'),
        content: Text('确定删除「${session.title}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteSession(session.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      selected: isActive,
      leading: session.isPinned
          ? Icon(Icons.push_pin, size: 18, color: colorScheme.primary)
          : null,
      title: Text(
        session.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        _formatTime(session.updatedAt),
        style: TextStyle(fontSize: 12, color: colorScheme.outline),
      ),
      trailing: Text(
        '${session.messageCount} 条',
        style: TextStyle(fontSize: 12, color: colorScheme.outline),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}
