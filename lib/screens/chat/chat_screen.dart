import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../settings/ai_settings_screen.dart';
import 'chat_session_list_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, provider, _) {
            final title = provider.currentSession?.title;
            return Text(title ?? '智能问答');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '会话历史',
            onPressed: () async {
              final chatProvider = context.read<ChatProvider>();
              final sessionId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                    builder: (_) => const ChatSessionListScreen()),
              );
              if (sessionId != null && mounted) {
                chatProvider.switchSession(sessionId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: '新建对话',
            onPressed: () => context.read<ChatProvider>().createNewSession(),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          // 未配置 AI 模型
          if (provider.errorMessage == '未配置 AI 模型' ||
              (!provider.isLoading && provider.messages.isEmpty && provider.errorMessage != null)) {
            return _buildNoConfigHint(context);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;
              return _buildChatBody(context, provider, isDesktop);
            },
          );
        },
      ),
    );
  }

  Widget _buildNoConfigHint(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('尚未配置 AI 模型',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('请先在设置中配置并激活一个 AI 模型',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final chatProvider = context.read<ChatProvider>();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AISettingsScreen()),
                );
                if (!mounted) return;
                chatProvider.reinitialize();
              },
              icon: const Icon(Icons.settings),
              label: const Text('前往设置'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody(
      BuildContext context, ChatProvider provider, bool isDesktop) {
    final maxContentWidth = isDesktop ? 800.0 : double.infinity;
    final fontSize = isDesktop ? 15.0 : 14.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: Column(
          children: [
            Expanded(
              child: provider.messages.isEmpty
                  ? _buildEmptyHint(context)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 24 : 12,
                        vertical: 16,
                      ),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final msg = provider.messages[index];
                        return _buildMessageItem(
                            context, msg, isDesktop, fontSize);
                      },
                    ),
            ),
            _buildInputBar(context, provider, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(BuildContext context) {
    final provider = context.read<ChatProvider>();
    final questions = provider.quickQuestions;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('试试问我关于收支的问题',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    )),
            const SizedBox(height: 8),
            Text('"这个月花了多少钱？"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    )),
            if (questions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: questions.map((q) {
                    return ActionChip(
                      label: Text(q),
                      onPressed: () {
                        _controller.text = q;
                        _sendMessage();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
      BuildContext context, ChatMessage msg, bool isDesktop, double fontSize) {
    if (msg.isLoading) {
      return _buildTypingIndicator(context);
    }

    switch (msg.role) {
      case ChatRole.user:
        return _buildUserBubble(context, msg, isDesktop, fontSize);
      case ChatRole.assistant:
        return _buildAssistantBubble(context, msg, isDesktop, fontSize);
      case ChatRole.toolCall:
        return _buildToolCallCard(context, msg, isDesktop);
      case ChatRole.toolResult:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserBubble(
      BuildContext context, ChatMessage msg, bool isDesktop, double fontSize) {
    final maxWidth = isDesktop ? 0.6 : 0.85;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * maxWidth,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          msg.content,
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(
      BuildContext context, ChatMessage msg, bool isDesktop, double fontSize) {
    final maxWidth = isDesktop ? 0.6 : 0.85;
    final colorScheme = Theme.of(context).colorScheme;
    final provider = context.read<ChatProvider>();
    final feedbackType = provider.getFeedbackType(msg.id);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * maxWidth,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: msg.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(fontSize: fontSize),
                code: TextStyle(
                  fontSize: fontSize - 1,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                ),
                codeblockDecoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.thumb_up_outlined,
                      color: feedbackType == 'like'
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
                    onPressed: feedbackType != null
                        ? null
                        : () => provider.likeMessage(msg.id),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    icon: Icon(
                      Icons.thumb_down_outlined,
                      color: feedbackType == 'dislike'
                          ? colorScheme.error
                          : colorScheme.outline,
                    ),
                    onPressed: feedbackType != null
                        ? null
                        : () => _showDislikeDialog(context, msg.id),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDislikeDialog(BuildContext context, String messageId) {
    final controller = TextEditingController(text: '回答不满意');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('反馈原因'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入原因',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ChatProvider>()
                  .dislikeMessage(messageId, controller.text);
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallCard(
      BuildContext context, ChatMessage msg, bool isDesktop) {
    if (msg.toolCalls == null || msg.toolCalls!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: msg.toolCalls!.map((tc) {
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            child: ExpansionTile(
              leading: Icon(Icons.build_circle_outlined,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              title: Text(
                _toolDisplayName(tc.name),
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tc.arguments.isNotEmpty &&
                          tc.arguments != '{}') ...[
                        Text('参数:',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline)),
                        const SizedBox(height: 4),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            _formatJson(tc.arguments),
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                      if (tc.result != null) ...[
                        const SizedBox(height: 8),
                        Text('结果:',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.outline)),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _formatToolResult(tc.result!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 40,
          height: 20,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(
      BuildContext context, ChatProvider provider, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 16 : 8,
        8,
        isDesktop ? 16 : 8,
        8 + (bottomPadding > 0 ? 0 : MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: isDesktop
                  ? (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        _sendMessage();
                      }
                    }
                  : null,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: isDesktop ? 3 : 1,
                minLines: 1,
                textInputAction:
                    isDesktop ? TextInputAction.newline : TextInputAction.send,
                onSubmitted: isDesktop ? null : (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: '输入你的问题...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(isDesktop ? 16 : 24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: provider.isLoading ? null : _sendMessage,
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _toolDisplayName(String name) {
    switch (name) {
      case 'get_current_time':
        return '获取当前时间';
      case 'get_tables':
        return '查询数据库表';
      case 'get_table_schema':
        return '查询表结构';
      case 'execute_sql':
        return '执行SQL查询';
      case 'save_memory':
        return '保存记忆';
      default:
        return name;
    }
  }

  String _formatJson(String jsonStr) {
    try {
      final obj = const JsonDecoder().convert(jsonStr);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return jsonStr;
    }
  }

  String _formatToolResult(String result) {
    // 尝试格式化 JSON 结果
    try {
      final obj = const JsonDecoder().convert(result);
      return const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {
      return result;
    }
  }
}