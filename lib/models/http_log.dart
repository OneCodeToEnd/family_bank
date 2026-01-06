/// HTTP 日志模型
class HttpLog {
  final int? id;
  final String requestId;
  final String method;
  final String url;
  final String? requestHeaders;
  final String? requestBody;
  final int? requestSize;
  final int? statusCode;
  final String? statusMessage;
  final String? responseHeaders;
  final String? responseBody;
  final int? responseSize;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMs;
  final String? errorType;
  final String? errorMessage;
  final String? stackTrace;
  final String? serviceName;
  final String? apiProvider;
  final DateTime createdAt;
  final DateTime updatedAt;

  HttpLog({
    this.id,
    required this.requestId,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.requestSize,
    this.statusCode,
    this.statusMessage,
    this.responseHeaders,
    this.responseBody,
    this.responseSize,
    required this.startTime,
    this.endTime,
    this.durationMs,
    this.errorType,
    this.errorMessage,
    this.stackTrace,
    this.serviceName,
    this.apiProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HttpLog.fromMap(Map<String, dynamic> map) {
    return HttpLog(
      id: map['id'] as int?,
      requestId: map['request_id'] as String,
      method: map['method'] as String,
      url: map['url'] as String,
      requestHeaders: map['request_headers'] as String?,
      requestBody: map['request_body'] as String?,
      requestSize: map['request_size'] as int?,
      statusCode: map['status_code'] as int?,
      statusMessage: map['status_message'] as String?,
      responseHeaders: map['response_headers'] as String?,
      responseBody: map['response_body'] as String?,
      responseSize: map['response_size'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: map['end_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int)
          : null,
      durationMs: map['duration_ms'] as int?,
      errorType: map['error_type'] as String?,
      errorMessage: map['error_message'] as String?,
      stackTrace: map['stack_trace'] as String?,
      serviceName: map['service_name'] as String?,
      apiProvider: map['api_provider'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'request_id': requestId,
      'method': method,
      'url': url,
      'request_headers': requestHeaders,
      'request_body': requestBody,
      'request_size': requestSize,
      'status_code': statusCode,
      'status_message': statusMessage,
      'response_headers': responseHeaders,
      'response_body': responseBody,
      'response_size': responseSize,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime?.millisecondsSinceEpoch,
      'duration_ms': durationMs,
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'service_name': serviceName,
      'api_provider': apiProvider,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  HttpLog copyWith({
    int? id,
    String? requestId,
    String? method,
    String? url,
    String? requestHeaders,
    String? requestBody,
    int? requestSize,
    int? statusCode,
    String? statusMessage,
    String? responseHeaders,
    String? responseBody,
    int? responseSize,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMs,
    String? errorType,
    String? errorMessage,
    String? stackTrace,
    String? serviceName,
    String? apiProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HttpLog(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      method: method ?? this.method,
      url: url ?? this.url,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      requestBody: requestBody ?? this.requestBody,
      requestSize: requestSize ?? this.requestSize,
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      responseBody: responseBody ?? this.responseBody,
      responseSize: responseSize ?? this.responseSize,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMs: durationMs ?? this.durationMs,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      serviceName: serviceName ?? this.serviceName,
      apiProvider: apiProvider ?? this.apiProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'HttpLog(id: $id, method: $method, url: $url, statusCode: $statusCode, durationMs: $durationMs)';
  }
}
