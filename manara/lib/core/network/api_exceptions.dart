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

  bool get isDeviceMismatch =>
      code == 'DEVICE_MISMATCH' ||
      code == 'DEVICE_BOUND_MISMATCH' ||
      message.toLowerCase().contains('device mismatch');

  @override
  String toString() => 'ApiException(code: $code, message: $message, statusCode: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Network connection failure. Please check your internet.'});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expired or unauthorized.'})
      : super(statusCode: 401, code: 'UNAUTHORIZED');
}

class ForbiddenException extends ApiException {
  const ForbiddenException({required super.message, super.code, super.details})
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Resource not found.'})
      : super(statusCode: 404, code: 'NOT_FOUND');
}

class ConflictException extends ApiException {
  const ConflictException({required super.message, super.code})
      : super(statusCode: 409);
}

class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.details,
    this.fieldErrors,
  }) : super(statusCode: 422, code: 'VALIDATION_ERROR');
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
    super.code = 'REGISTRATION_RETRY_REQUIRED',
  }) : super(statusCode: 503);
}
