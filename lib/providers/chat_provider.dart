import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai/agent/ai_agent_service.dart';
import '../utils/app_logger.dart';

/// 聊天状态管理
class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  AIAgentService? _agent;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// 初始化 Agent
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _agent = await AIAgentFactory.create();
      _isInitialized = true;
      _errorMessage = null;
    } catch (e) {
      AppLogger.e('ChatProvider initialize failed', error: e);
      _errorMessage = '初始化失败: $e';
    }
    notifyListeners();
  }

  /// 重新初始化（配置变更后调用）
  Future<void> reinitialize() async {
    _isInitialized = false;
    _agent = null;
    await initialize();
  }

  /// 发送消息
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    if (_agent == null) {
      _errorMessage = '未配置 AI 模型';
      notifyListeners();
      return;
    }

    // 添加用户消息
    _messages.add(ChatMessage(role: ChatRole.user, content: text));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 添加加载占位
      final loadingMsg = ChatMessage(
        role: ChatRole.assistant,
        content: '',
        isLoading: true,
      );
      _messages.add(loadingMsg);
      notifyListeners();

      await _agent!.chat(
        history: _messages.where((m) =>
          m.role == ChatRole.user || m.role == ChatRole.assistant
        ).toList(),
        userMessage: text,
        onMessage: (msg) {
          // 移除加载占位（如果还在）
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(msg);
          notifyListeners();
        },
      );

      // 确保移除加载占位
      _messages.removeWhere((m) => m.isLoading);
    } catch (e) {
      AppLogger.e('sendMessage failed', error: e);
      _messages.removeWhere((m) => m.isLoading);
      _errorMessage = '发送失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 清空会话
  void clearChat() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
