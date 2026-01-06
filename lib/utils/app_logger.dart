import 'package:logger/logger.dart';

/// 全局日志工具类
/// 提供统一的日志接口，避免在每个类中重复创建 Logger
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // 不显示方法调用栈
      errorMethodCount: 5, // 错误时显示5层调用栈
      lineLength: 80, // 行宽限制
      colors: true, // 启用彩色输出
      printEmojis: true, // 显示表情符号
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 显示时间戳
    ),
  );

  /// Debug 级别日志
  static void d(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info 级别日志
  static void i(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning 级别日志
  static void w(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error 级别日志
  static void e(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Verbose 级别日志（详细信息）
  static void v(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}
