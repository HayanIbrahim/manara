import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLogEntry {
  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final String path;
  final Map<String, dynamic> requestHeaders;
  final dynamic requestBody;
  int? statusCode;
  int? durationMs;
  dynamic responseBody;
  String? errorMessage;
  bool isError;

  ApiLogEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.path,
    required this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.durationMs,
    this.responseBody,
    this.errorMessage,
    this.isError = false,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class ApiLogStore extends ChangeNotifier {
  static final ApiLogStore instance = ApiLogStore._();
  ApiLogStore._();

  final List<ApiLogEntry> _logs = [];
  static const int maxLogs = 100;

  List<ApiLogEntry> get logs => List.unmodifiable(_logs);

  int get errorCount => _logs.where((l) => l.isError).length;

  void addLog(ApiLogEntry entry) {
    if (_logs.length >= maxLogs) {
      _logs.removeLast();
    }
    _logs.insert(0, entry);
    notifyListeners();
  }

  void updateLog({
    required String id,
    int? statusCode,
    int? durationMs,
    dynamic responseBody,
    String? errorMessage,
    bool isError = false,
  }) {
    final index = _logs.indexWhere((l) => l.id == id);
    if (index != -1) {
      final item = _logs[index];
      item.statusCode = statusCode ?? item.statusCode;
      item.durationMs = durationMs ?? item.durationMs;
      item.responseBody = responseBody ?? item.responseBody;
      item.errorMessage = errorMessage ?? item.errorMessage;
      item.isError = isError;
      notifyListeners();
    }
  }

  void clear() {
    _logs.clear();
    notifyListeners();
  }

  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== MANARA ADMIN API LOGS EXPORT (${DateTime.now()}) ===\n');
    for (final log in _logs) {
      buffer.writeln('----------------------------------------------------');
      buffer.writeln('[${log.formattedTime}] ${log.method} ${log.url}');
      final statusStr = log.statusCode != null
          ? '${log.statusCode}'
          : (log.isError ? 'FAILED (Network/Host error)' : 'PENDING (Awaiting response)');
      final durationStr = log.durationMs != null
          ? '${log.durationMs}ms'
          : '${DateTime.now().difference(log.timestamp).inMilliseconds}ms elapsed';
      buffer.writeln('Status: $statusStr ($durationStr)');
      if (log.isError) {
        buffer.writeln('ERROR: ${log.errorMessage}');
      }
      if (log.requestBody != null) {
        buffer.writeln('Request Body: ${log.requestBody}');
      }
      if (log.responseBody != null) {
        buffer.writeln('Response Body: ${log.responseBody}');
      }
      buffer.writeln('----------------------------------------------------\n');
    }
    return buffer.toString();
  }
}

class ApiLoggerInterceptor extends Interceptor {
  final String appName;

  ApiLoggerInterceptor({this.appName = 'API'});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final reqId = '${DateTime.now().microsecondsSinceEpoch}_${options.path.hashCode}';
    final startTime = DateTime.now().millisecondsSinceEpoch;
    options.extra['log_id'] = reqId;
    options.extra['start_time'] = startTime;

    final method = options.method.toUpperCase();
    final uri = options.uri.toString();

    final entry = ApiLogEntry(
      id: reqId,
      timestamp: DateTime.now(),
      method: method,
      url: uri,
      path: options.path,
      requestHeaders: Map<String, dynamic>.from(options.headers),
      requestBody: _sanitizeData(options.data),
    );

    ApiLogStore.instance.addLog(entry);

    debugPrint('\n==================== 🌐 [$appName REQUEST] ====================');
    debugPrint('➡️  $method $uri');
    if (options.headers.isNotEmpty) {
      debugPrint('📋 Headers: ${_sanitizeHeaders(options.headers)}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('🔍 Query Parameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('📦 Body: ${_formatPayload(options.data)}');
    }
    debugPrint('=================================================================\n');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final reqId = response.requestOptions.extra['log_id']?.toString() ?? '';
    final startTime = response.requestOptions.extra['start_time'] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;

    final method = response.requestOptions.method.toUpperCase();
    final uri = response.requestOptions.uri.toString();
    final statusCode = response.statusCode ?? 200;

    ApiLogStore.instance.updateLog(
      id: reqId,
      statusCode: statusCode,
      durationMs: duration,
      responseBody: response.data,
      isError: statusCode >= 400,
    );

    debugPrint('\n==================== ✅ [$appName RESPONSE: $statusCode] (${duration ?? 0}ms) ====================');
    debugPrint('⬅️  $method $uri');
    debugPrint('📦 Payload: ${_formatPayload(response.data)}');
    debugPrint('====================================================================================\n');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final req = err.requestOptions;
    final reqId = req.extra['log_id']?.toString() ?? '';
    final startTime = req.extra['start_time'] as int?;
    final duration = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;

    final method = req.method.toUpperCase();
    final uri = req.uri.toString();
    final statusCode = err.response?.statusCode;
    final statusText = statusCode != null ? '$statusCode' : 'NO_STATUS';

    String errorMessage = err.message ?? err.toString();
    if (err.response?.data is Map) {
      final data = err.response!.data as Map;
      if (data['error'] is Map && (data['error'] as Map)['message'] != null) {
        errorMessage = (data['error'] as Map)['message'].toString();
      } else if (data['message'] != null) {
        errorMessage = data['message'].toString();
      }
    }

    ApiLogStore.instance.updateLog(
      id: reqId,
      statusCode: statusCode,
      durationMs: duration,
      responseBody: err.response?.data,
      errorMessage: errorMessage,
      isError: true,
    );

    debugPrint('\n🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 [$appName API ERROR: $statusText] (${duration ?? 0}ms) 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
    debugPrint('❌ FAILED: $method $uri');
    debugPrint('⚠️ Error Type: ${err.type}');
    debugPrint('⚠️ Error Summary: $errorMessage');
    if (req.data != null) {
      debugPrint('📦 Sent Request Payload: ${_formatPayload(req.data)}');
    }
    if (err.response != null) {
      debugPrint('💥 Server Raw Response: ${_formatPayload(err.response?.data)}');
    } else {
      debugPrint('💥 No response received from server (Network timeout / Host unreachable)');
    }
    debugPrint('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\n');

    handler.next(err);
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization'].toString();
      if (auth.length > 25) {
        sanitized['Authorization'] = '${auth.substring(0, 16)}... (len: ${auth.length})';
      }
    }
    return sanitized;
  }

  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('password') ||
            lowerKey == 'secret' ||
            lowerKey == 'token' ||
            lowerKey == 'accesstoken' ||
            lowerKey == 'refreshtoken') {
          sanitized[key] = '********';
        } else if (entry.value is Map || entry.value is List) {
          sanitized[key] = _sanitizeData(entry.value);
        } else {
          sanitized[key] = entry.value;
        }
      }
      return sanitized;
    } else if (data is List) {
      return data.map(_sanitizeData).toList();
    }
    return data;
  }

  String _formatPayload(dynamic data) {
    if (data == null) return 'null';
    try {
      final sanitized = _sanitizeData(data);
      if (sanitized is Map || sanitized is List) {
        return const JsonEncoder.withIndent('  ').convert(sanitized);
      }
      return sanitized.toString();
    } catch (_) {
      return data.toString();
    }
  }
}
