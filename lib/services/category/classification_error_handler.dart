import '../../utils/app_logger.dart';

/// 分类错误类型
enum ClassificationErrorType {
  networkError, // 网络错误
  apiError, // API错误
  configError, // 配置错误
  dataError, // 数据错误
  unknown, // 未知错误
}

/// 分类异常
class ClassificationException implements Exception {
  final String message;
  final ClassificationErrorType type;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ClassificationException({
    required this.message,
    required this.type,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'ClassificationException($type): $message';
  }

  /// 获取用户友好的错误信息
  String getUserMessage() {
    switch (type) {
      case ClassificationErrorType.networkError:
        return '网络连接失败，请检查网络设置';
      case ClassificationErrorType.apiError:
        return 'AI服务调用失败，请检查API配置';
      case ClassificationErrorType.configError:
        return '配置错误，请检查AI设置';
      case ClassificationErrorType.dataError:
        return '数据处理错误：$message';
      case ClassificationErrorType.unknown:
        return '发生未知错误：$message';
    }
  }
}

/// 错误处理结果
class ErrorHandlingResult<T> {
  final T? data;
  final ClassificationException? error;

  ErrorHandlingResult.success(this.data) : error = null;
  ErrorHandlingResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// 错误处理工具类
class ClassificationErrorHandler {
  /// 包装可能抛出异常的操作
  static Future<ErrorHandlingResult<T>> handle<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return ErrorHandlingResult.success(result);
    } catch (e, stackTrace) {
      final exception = _convertToClassificationException(e, stackTrace, context);
      return ErrorHandlingResult.failure(exception);
    }
  }

  /// 包装同步操作
  static ErrorHandlingResult<T> handleSync<T>(
    T Function() operation, {
    String? context,
  }) {
    try {
      final result = operation();
      return ErrorHandlingResult.success(result);
    } catch (e, stackTrace) {
      final exception = _convertToClassificationException(e, stackTrace, context);
      return ErrorHandlingResult.failure(exception);
    }
  }

  /// 将异常转换为分类异常
  static ClassificationException _convertToClassificationException(
    dynamic error,
    StackTrace stackTrace,
    String? context,
  ) {
    if (error is ClassificationException) {
      return error;
    }

    // 判断错误类型
    ClassificationErrorType type = ClassificationErrorType.unknown;
    String message = error.toString();

    // 网络错误
    if (error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('Connection') ||
        error.toString().contains('timeout')) {
      type = ClassificationErrorType.networkError;
      message = '网络连接失败';
    }
    // API错误
    else if (error.toString().contains('API') ||
        error.toString().contains('401') ||
        error.toString().contains('403') ||
        error.toString().contains('429')) {
      type = ClassificationErrorType.apiError;
      message = 'API调用失败';
    }
    // 配置错误
    else if (error.toString().contains('config') ||
        error.toString().contains('setting')) {
      type = ClassificationErrorType.configError;
      message = '配置错误';
    }
    // 数据错误
    else if (error.toString().contains('FormatException') ||
        error.toString().contains('JSON') ||
        error.toString().contains('parse')) {
      type = ClassificationErrorType.dataError;
      message = '数据格式错误';
    }

    if (context != null) {
      message = '$context: $message';
    }

    return ClassificationException(
      message: message,
      type: type,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录错误日志
  static void logError(ClassificationException exception) {
    AppLogger.w('=== Classification Error ===');
    AppLogger.w('Type: ${exception.type}');
    AppLogger.w('Message: ${exception.message}');
    if (exception.originalError != null) {
      AppLogger.w('Original Error: ${exception.originalError}');
    }
    if (exception.stackTrace != null) {
      AppLogger.w('Stack Trace:', stackTrace: exception.stackTrace);
    }
    AppLogger.w('===========================');
  }
}

/// 可重试的操作包装器
class RetryableOperation<T> {
  final Future<T> Function() operation;
  final int maxRetries;
  final Duration retryDelay;
  final bool Function(dynamic error)? shouldRetry;

  RetryableOperation({
    required this.operation,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.shouldRetry,
  });

  Future<ErrorHandlingResult<T>> execute() async {
    int attempts = 0;
    dynamic lastError;
    StackTrace? lastStackTrace;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        return ErrorHandlingResult.success(result);
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;
        attempts++;

        // 检查是否应该重试
        if (shouldRetry != null && !shouldRetry!(e)) {
          break;
        }

        // 如果还有重试次数，等待后重试
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay * attempts); // 指数退避
        }
      }
    }

    // 所有重试都失败
    final exception = ClassificationErrorHandler._convertToClassificationException(
      lastError,
      lastStackTrace ?? StackTrace.current,
      '操作失败（已重试 $attempts 次）',
    );

    return ErrorHandlingResult.failure(exception);
  }
}
