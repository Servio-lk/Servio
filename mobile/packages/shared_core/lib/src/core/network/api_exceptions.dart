class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? error;
  final String? path;
  final String? traceId;

  const ApiException(
    this.message, {
    this.statusCode,
    this.data,
    this.error,
    this.path,
    this.traceId,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [$statusCode]: $message';
    }
    return 'ApiException: $message';
  }
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    String message = 'Unauthorized. Please sign in again.',
    int statusCode = 401,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    String message = 'Access forbidden.',
    int statusCode = 403,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class ResourceNotFoundException extends ApiException {
  const ResourceNotFoundException([
    String message = 'Requested resource not found.',
    int statusCode = 404,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class ConflictException extends ApiException {
  const ConflictException([
    String message = 'Conflict. The requested resource or slot is already in use.',
    int statusCode = 409,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? validationErrors;

  const ValidationException(
    String message, {
    int statusCode = 400,
    this.validationErrors,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  }) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class RateLimitExceededException extends ApiException {
  final int? retryAfterSeconds;

  const RateLimitExceededException([
    String message = 'Too many requests. Please try again later.',
    int statusCode = 429,
    this.retryAfterSeconds,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class ServerException extends ApiException {
  const ServerException([
    String message = 'Internal server error occurred.',
    int statusCode = 500,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}

class NetworkException extends ApiException {
  const NetworkException([
    String message = 'Network connection failure. Please check your internet connection.',
    int? statusCode,
    dynamic data,
    String? error,
    String? path,
    String? traceId,
  ]) : super(
          message,
          statusCode: statusCode,
          data: data,
          error: error,
          path: path,
          traceId: traceId,
        );
}
