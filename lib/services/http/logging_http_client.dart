import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../../models/http_log.dart';
import '../database/http_log_db_service.dart';

/// HTTP 拦截器，自动记录所有请求和响应
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;
  final HttpLogDbService _logService;
  final String? serviceName;
  final String? apiProvider;
  final bool enabled;

  static const _uuid = Uuid();
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  LoggingHttpClient(
    this._inner, {
    HttpLogDbService? logService,
    this.serviceName,
    this.apiProvider,
    this.enabled = true,
  }) : _logService = logService ?? HttpLogDbService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!enabled) {
      return _inner.send(request);
    }

    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    // 1. 记录请求开始（异步，不阻塞）
    _createRequestLogAsync(requestId, request, startTime);

    try {
      // 2. 发送请求
      final streamedResponse = await _inner.send(request);

      // 3. 转换为 Response 以便读取内容
      final response = await http.Response.fromStream(streamedResponse);

      // 4. 异步记录响应（不阻塞）
      _logResponseAsync(requestId, response, startTime);

      // 5. 返回新的 StreamedResponse（因为原始的已经被消费）
      return http.StreamedResponse(
        http.ByteStream.fromBytes(response.bodyBytes),
        response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, stackTrace) {
      // 4. 异步记录错误（不阻塞）
      _logErrorAsync(requestId, e, stackTrace, startTime);
      rethrow;
    }
  }

  /// 异步创建请求日志（不阻塞主流程）
  Future<void> _createRequestLogAsync(
    String requestId,
    http.BaseRequest request,
    DateTime startTime,
  ) async {
    try {
      final requestHeaders = _headersToJson(request.headers);
      String? requestBody;
      int? requestSize;

      // 尝试读取请求体
      if (request is http.Request) {
        requestBody = request.body;
        requestSize = utf8.encode(requestBody).length;
      }

      final log = HttpLog(
        requestId: requestId,
        method: request.method,
        url: request.url.toString(),
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        requestSize: requestSize,
        startTime: startTime,
        serviceName: serviceName,
        apiProvider: apiProvider,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _logService.createLog(log);
    } catch (e) {
      // 日志记录失败不影响请求
      _logger.w('Failed to create HTTP log', error: e);
    }
  }

  /// 异步记录响应（不阻塞主流程）
  Future<void> _logResponseAsync(
    String requestId,
    http.Response response,
    DateTime startTime,
  ) async {
    try {
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;

      final existingLog = await _logService.getLogByRequestId(requestId);
      if (existingLog == null) {
        _logger.w('Cannot find log with requestId: $requestId');
        return;
      }

      final responseHeaders = _headersToJson(response.headers);
      final responseBody = response.body;
      final responseSize = response.bodyBytes.length;

      final updatedLog = existingLog.copyWith(
        statusCode: response.statusCode,
        statusMessage: response.reasonPhrase,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        responseSize: responseSize,
        endTime: endTime,
        durationMs: durationMs,
        updatedAt: DateTime.now(),
      );

      await _logService.updateLog(updatedLog);
    } catch (e) {
      // 日志记录失败不影响响应
      _logger.w('Failed to log HTTP response', error: e);
    }
  }

  /// 异步记录错误（不阻塞主流程）
  Future<void> _logErrorAsync(
    String requestId,
    dynamic error,
    StackTrace stackTrace,
    DateTime startTime,
  ) async {
    try {
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;

      final existingLog = await _logService.getLogByRequestId(requestId);
      if (existingLog == null) {
        _logger.w('Cannot find log with requestId: $requestId');
        return;
      }

      final errorType = _getErrorType(error);
      final errorMessage = error.toString();

      final updatedLog = existingLog.copyWith(
        endTime: endTime,
        durationMs: durationMs,
        errorType: errorType,
        errorMessage: errorMessage,
        stackTrace: stackTrace.toString(),
        updatedAt: DateTime.now(),
      );

      await _logService.updateLog(updatedLog);
    } catch (e) {
      // 日志记录失败不影响错误传播
      _logger.w('Failed to log HTTP error', error: e);
    }
  }

  /// 将 headers 转换为 JSON 字符串
  String _headersToJson(Map<String, String> headers) {
    try {
      return jsonEncode(headers);
    } catch (e) {
      return '{}';
    }
  }

  /// 判断错误类型
  String _getErrorType(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout')) {
      return 'timeout';
    } else if (errorStr.contains('socket') || errorStr.contains('network')) {
      return 'network';
    } else if (errorStr.contains('format') || errorStr.contains('parse')) {
      return 'parse';
    } else if (errorStr.contains('401') ||
        errorStr.contains('403') ||
        errorStr.contains('429')) {
      return 'api';
    } else {
      return 'unknown';
    }
  }

  @override
  void close() {
    _inner.close();
  }
}
