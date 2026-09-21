import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';
import 'api_logger.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  final Dio _dio;
  final TokenProvider? _tokenProvider;

  ApiClient({
    String baseUrl = ApiConstants.defaultBaseUrl,
    this._tokenProvider,
    Dio? customDio,
  }) : _dio = customDio ??
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
          // Normalize leading slash to prevent Dio from stripping baseUrl subpath (/api/)
          if (options.path.startsWith('/') && !options.path.startsWith('//')) {
            options.path = options.path.substring(1);
          }

          if (_tokenProvider != null) {
            final token = await _tokenProvider();
            if (token != null && token.isNotEmpty) {
              options.headers[ApiConstants.headerAuthorization] = 'Bearer $token';
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
    _dio.interceptors.add(ApiLoggerInterceptor(appName: 'MANARA_ADMIN'));
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
      return ApiException(message: error.message ?? 'Network error');
    }

    final data = response.data;
    String? code;
    String message = 'An error occurred';
    Map<String, dynamic>? details;

    if (data is Map<String, dynamic>) {
      if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
        final errObj = data['error'] as Map<String, dynamic>;
        code = errObj['code']?.toString();
        message = errObj['message']?.toString() ?? message;
        if (errObj['details'] is Map<String, dynamic>) {
          details = errObj['details'] as Map<String, dynamic>;
          if (details.containsKey('fieldErrors') && details['fieldErrors'] is Map) {
            final fieldErrors = details['fieldErrors'] as Map;
            final errorLines = <String>[];
            fieldErrors.forEach((k, v) {
              if (v is List) {
                errorLines.add('$k: ${v.join(", ")}');
              } else {
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
      if (!data.trim().startsWith('<')) {
        message = data;
      } else {
        message = response.statusMessage ?? 'Server Error (${response.statusCode})';
      }
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
        return ValidationException(message: message, details: details);
      case 429:
        final retryAfter = response.headers.value('retry-after');
        return RateLimitException(
          message: message.isNotEmpty && message != 'An error occurred'
              ? message
              : 'Too many requests. Please slow down and try again.',
          retryAfter: retryAfter,
        );
      case 503:
        return ServiceUnavailableException(
          message: message.isNotEmpty && message != 'An error occurred'
              ? message
              : 'Service temporarily unavailable. Please retry the identical request.',
          code: code ?? 'SERVICE_UNAVAILABLE',
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
