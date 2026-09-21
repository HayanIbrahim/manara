class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() => 'ApiException: $message (code: $code, status: $statusCode)';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Unauthorized admin session'})
      : super(statusCode: 401, code: 'UNAUTHORIZED');
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Access forbidden. Administrator privileges required',
    super.code,
    super.details,
  }) : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Resource not found'})
      : super(statusCode: 404, code: 'NOT_FOUND');
}

class ConflictException extends ApiException {
  const ConflictException({super.message = 'Resource conflict', super.code})
      : super(statusCode: 409);
}

class ValidationException extends ApiException {
  const ValidationException({super.message = 'Validation failure', super.details})
      : super(statusCode: 422, code: 'VALIDATION_ERROR');
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network connection failure. Verify your host connection.'})
      : super(statusCode: null, code: 'NETWORK_ERROR');
}

class RateLimitException extends ApiException {
  final String? retryAfter;

  const RateLimitException({
    super.message = 'Too many requests. Please slow down and try again later.',
    this.retryAfter,
  }) : super(statusCode: 429, code: 'RATE_LIMITED');
}

class ServiceUnavailableException extends ApiException {
  const ServiceUnavailableException({
    super.message = 'Service temporarily unavailable. Please retry the identical request.',
    super.code = 'SERVICE_UNAVAILABLE',
  }) : super(statusCode: 503);
}

