import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';
import 'api_logger.dart';

typedef TokenProvider = Future<String?> Function();
typedef DeviceIdProvider = Future<String?> Function();
typedef SessionTypeProvider = Future<String?> Function();

class ApiClient {
  final Dio _dio;
  final TokenProvider? _tokenProvider;
  final DeviceIdProvider? _deviceIdProvider;
  final SessionTypeProvider? _sessionTypeProvider;

  ApiClient({
    String baseUrl = ApiConstants.defaultBaseUrl,
    this._tokenProvider,
    this._deviceIdProvider,
    this._sessionTypeProvider,
    Dio? customDio,
  })  : _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Normalize path: if options.path starts with '/', remove it so Dio
          // resolves against baseUrl subpath (e.g. /api/) rather than domain root
          if (options.path.startsWith('/') && !options.path.startsWith('//')) {
            options.path = options.path.substring(1);
          }
          if (_tokenProvider != null) {
            final token = await _tokenProvider();
            if (token != null && token.isNotEmpty) {
              options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
            }
          }

          final sessionType = _sessionTypeProvider != null ? await _sessionTypeProvider() : null;
          final isDesktop = sessionType == 'desktop';
          final isAdmin = sessionType == 'admin';

          if (!isDesktop && !isAdmin && _deviceIdProvider != null) {
            final devId = await _deviceIdProvider();
            if (devId != null && devId.isNotEmpty) {
              options.headers[ApiConstants.headerDeviceId] = devId;
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          final mappedException = _mapDioError(error);
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mappedException,
              message: mappedException.message,
            ),
          );
        },
      ),
    );
    _dio.interceptors.add(ApiLoggerInterceptor(appName: 'MANARA_APP'));
  }

  Dio get dio => _dio;

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl.endsWith('/') ? newBaseUrl : '$newBaseUrl/';
  }

  ApiException _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }

    final response = error.response;
    if (response == null) {
      return ApiException(message: error.message ?? 'Unknown network failure');
    }

    final data = response.data;
    String? code;
    String message = 'An error occurred';
    Map<String, dynamic>? details;
    Map<String, List<String>>? extractedFieldErrors;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
        final errObj = data['error'] as Map<String, dynamic>;
        code = errObj['code']?.toString();
        message = errObj['message']?.toString() ?? message;
        if (errObj['details'] is Map<String, dynamic>) {
          details = errObj['details'] as Map<String, dynamic>;
          if (details.containsKey('fieldErrors') && details['fieldErrors'] is Map) {
            final fieldErrors = details['fieldErrors'] as Map;
            extractedFieldErrors = {};
            final errorLines = <String>[];
            fieldErrors.forEach((k, v) {
              if (v is List) {
                final listStr = v.map((e) => e.toString()).toList();
                extractedFieldErrors![k.toString()] = listStr;
                errorLines.add('$k: ${listStr.join(", ")}');
              } else if (v != null) {
                extractedFieldErrors![k.toString()] = [v.toString()];
                errorLines.add('$k: $v');
              }
            });
            if (errorLines.isNotEmpty) {
              message = '$message (${errorLines.join("; ")})';
            }
          }
        }
      } else if (data.containsKey('message')) {
        message = data['message'].toString();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    switch (response.statusCode) {
      case 401:
        return UnauthorizedException(message: message);
      case 403:
        return ForbiddenException(message: message, code: code, details: details);
      case 404:
        return NotFoundException(message: message);
      case 409:
        return ConflictException(message: message, code: code);
      case 422:
        return ValidationException(
          message: message,
          details: details,
          fieldErrors: extractedFieldErrors,
        );
      case 429:
        final retryAfter = response.headers.value('retry-after');
        return RateLimitException(
          message: data is String && data.isNotEmpty && !data.contains('<!DOCTYPE html>')
              ? data
              : 'Too many requests. Please slow down and try again later.',
          retryAfter: retryAfter,
        );
      case 503:
        return ServiceUnavailableException(
          message: message.isNotEmpty && message != 'An error occurred'
              ? message
              : 'Service temporarily unavailable. Please retry the identical request.',
          code: code ?? 'REGISTRATION_RETRY_REQUIRED',
        );
      default:
        return ApiException(
          message: message,
          code: code,
          statusCode: response.statusCode,
          details: details,
        );
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Error');
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Error');
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Error');
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Error');
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(message: e.message ?? 'Error');
    }
  }
}
