import 'package:flutter/foundation.dart';
import '../models/agent_memory.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/ai/agent/ai_agent_service.dart';
import '../services/database/agent_memory_db_service.dart';
import '../services/database/chat_session_db_service.dart';
import '../utils/app_logger.dart';

/// 聊天状态管理
class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  final Map<String, String> _feedbackTypes = {};
  final AgentMemoryDbService _memoryDbService = AgentMemoryDbService();
  final ChatSessionDbService _sessionDbService = ChatSessionDbService();
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  AIAgentService? _agent;

  List<ChatSession> _sessions = [];
  String? _currentSessionId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get currentSessionId => _currentSessionId;
  ChatSession? get currentSession =>
      _currentSessionId == null
          ? null
          : _sessions.cast<ChatSession?>().firstWhere(
                (s) => s?.id == _currentSessionId,
                orElse: () => null,
              );

  String? getFeedbackType(String messageId) => _feedbackTypes[messageId];

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _agent = await AIAgentFactory.create();
      _isInitialized = true;
      _errorMessage = null;
      await loadSessions();
    } catch (e) {
      AppLogger.e('ChatProvider initialize failed', error: e);
      _errorMessage = '初始化失败: $e';
    }
    notifyListeners();
  }

  Future<void> reinitialize() async {
    _isInitialized = false;
    _agent = null;
    await initialize();
  }

  /// 加载会话列表
  Future<void> loadSessions() async {
    try {
      _sessions = await _sessionDbService.getAll();
    } catch (e) {
      AppLogger.e('loadSessions failed', error: e);
    }
  }

  /// 创建新会话
  Future<void> createNewSession() async {
    // 先保存当前会话
    await _saveCurrentSession();
    _currentSessionId = null;
    _messages.clear();
    _feedbackTypes.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// 切换会话
  Future<void> switchSession(String sessionId) async {
    if (sessionId == _currentSessionId) return;
    // 保存当前会话
    await _saveCurrentSession();

    // 加载目标会话
    final session = await _sessionDbService.getById(sessionId);
    if (session != null) {
      _currentSessionId = session.id;
      _messages.clear();
      _messages.addAll(session.messages);
      _feedbackTypes.clear();
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// 删除会话
  Future<void> deleteSession(String sessionId) async {
    await _sessionDbService.delete(sessionId);
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
      _messages.clear();
      _feedbackTypes.clear();
    }
    notifyListeners();
  }

  /// 切换置顶
  Future<void> togglePinSession(String sessionId) async {
    await _sessionDbService.togglePin(sessionId);
    await loadSessions();
    notifyListeners();
  }

  /// 保存当前会话到数据库
  Future<void> _saveCurrentSession() async {
    if (_currentSessionId == null || _messages.isEmpty) return;
    final existing = currentSession;
    if (existing == null) return;

    final updated = existing.copyWith(
      messages: List<ChatMessage>.from(_messages),
      updatedAt: DateTime.now(),
    );
    await _sessionDbService.save(updated);
    await loadSessions();
  }

  /// 首次对话后生成标题
  Future<void> _generateSessionTitle() async {
    if (_currentSessionId == null || _agent == null) return;

    final userMessages =
        _messages.where((m) => m.role == ChatRole.user).toList();
    final assistantMessages =
        _messages.where((m) => m.role == ChatRole.assistant && m.content.isNotEmpty).toList();

    if (userMessages.isEmpty || assistantMessages.isEmpty) return;

    final title = await _agent!.generateTitle(
      firstUserMessage: userMessages.first.content,
      firstAssistantReply: assistantMessages.first.content,
    );

    if (title != null && _currentSessionId != null) {
      final idx = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (idx >= 0) {
        final updated = _sessions[idx].copyWith(
          title: title,
          messages: List<ChatMessage>.from(_messages),
          updatedAt: DateTime.now(),
        );
        await _sessionDbService.save(updated);
        await loadSessions();
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    if (_agent == null) {
      _errorMessage = '未配置 AI 模型';
      notifyListeners();
      return;
    }

    // 如果没有当前会话，自动创建
    if (_currentSessionId == null) {
      final session = ChatSession(title: '新对话');
      _currentSessionId = session.id;
      await _sessionDbService.save(session);
      await loadSessions();
    }

    final isFirstRound = _messages.where((m) => m.role == ChatRole.user).isEmpty;

    _messages.add(ChatMessage(role: ChatRole.user, content: text));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadingMsg = ChatMessage(
        role: ChatRole.assistant,
        content: '',
        isLoading: true,
      );
      _messages.add(loadingMsg);
      notifyListeners();

      await _agent!.chat(
        history: _messages
            .where(
                (m) => m.role == ChatRole.user || m.role == ChatRole.assistant)
            .toList(),
        userMessage: text,
        onMessage: (msg) {
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(msg);
          notifyListeners();
        },
      );

      _messages.removeWhere((m) => m.isLoading);

      // 保存会话
      await _saveCurrentSession();

      // 首次对话完成后异步生成标题
      if (isFirstRound) {
        _generateSessionTitle();
      }
    } catch (e) {
      AppLogger.e('sendMessage failed', error: e);
      _messages.removeWhere((m) => m.isLoading);
      _errorMessage = '发送失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> likeMessage(String messageId) async {
    if (_feedbackTypes.containsKey(messageId)) return;
    _feedbackTypes[messageId] = 'like';
    notifyListeners();

    try {
      final context = _buildReasoningContext(messageId);

      final summary = await _agent?.summarizeFeedback(
        feedbackType: 'like',
        context: context,
      );

      await _memoryDbService.save(AgentMemory(
        type: 'like',
        content: summary?.content ?? '用户认可了这个回答',
        relatedQuery: summary?.relatedQuery,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      AppLogger.e('likeMessage failed', error: e);
    }
  }

  Future<void> dislikeMessage(String messageId, String reason) async {
    if (_feedbackTypes.containsKey(messageId)) return;
    _feedbackTypes[messageId] = 'dislike';
    notifyListeners();

    try {
      final context = _buildReasoningContext(messageId);
      final contextWithReason = '$context\n\n用户反馈原因：$reason';

      final summary = await _agent?.summarizeFeedback(
        feedbackType: 'dislike',
        context: contextWithReason,
      );

      await _memoryDbService.save(AgentMemory(
        type: 'dislike',
        content: summary?.content ?? reason,
        relatedQuery: summary?.relatedQuery,
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      AppLogger.e('dislikeMessage failed', error: e);
    }
  }

  String _buildReasoningContext(String assistantMessageId) {
    final idx = _messages.indexWhere((m) => m.id == assistantMessageId);
    if (idx < 0) return '';

    int startIdx = idx;
    for (var i = idx - 1; i >= 0; i--) {
      if (_messages[i].role == ChatRole.user) {
        startIdx = i;
        break;
      }
    }

    final buf = StringBuffer();
    for (var i = startIdx; i <= idx; i++) {
      final msg = _messages[i];
      switch (msg.role) {
        case ChatRole.user:
          buf.writeln('【用户提问】${msg.content}');
        case ChatRole.toolCall:
          if (msg.toolCalls != null) {
            for (final tc in msg.toolCalls!) {
              buf.writeln('【工具调用】${tc.name}(${tc.arguments})');
              if (tc.result != null) {
                final result = tc.result!.length > 200
                    ? '${tc.result!.substring(0, 200)}...'
                    : tc.result!;
                buf.writeln('【工具结果】$result');
              }
            }
          }
        case ChatRole.assistant:
          buf.writeln('【最终回答】${msg.content}');
        default:
          break;
      }
    }
    return buf.toString();
  }

  /// 清空当前会话（创建新会话）
  void clearChat() {
    createNewSession();
  }
}
