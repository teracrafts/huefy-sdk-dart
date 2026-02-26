import 'error_code.dart';
import 'error_sanitizer.dart';

/// The primary error type for the Huefy Dart SDK.
///
/// All public methods throw [HuefyError] on failure. Use [errorCode]
/// to programmatically determine the error category and [isRecoverable] to
/// decide whether a retry is appropriate.
class HuefyError implements Exception {
  /// A human-readable error message.
  final String message;

  /// The categorized error code.
  final ErrorCode errorCode;

  /// The HTTP status code, if applicable.
  final int? statusCode;

  /// The field that caused a validation error, if applicable.
  final String? field;

  /// Seconds to wait before retrying (from Retry-After header).
  final int? retryAfter;

  /// The server-assigned request ID, if available.
  final String? requestId;

  /// The underlying cause, if any.
  final Object? cause;

  HuefyError._({
    required this.message,
    required this.errorCode,
    this.statusCode,
    this.field,
    this.retryAfter,
    this.requestId,
    this.cause,
  });

  // -- Factory constructors --

  /// Creates a network error.
  factory HuefyError.network({
    required String message,
    Object? cause,
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.network,
      cause: cause,
    );
  }

  /// Creates an authentication error.
  factory HuefyError.auth({
    String message = 'Invalid or expired API key',
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.authentication,
      statusCode: 401,
    );
  }

  /// Creates a timeout error.
  factory HuefyError.timeout({
    String message = 'Request timed out',
    Object? cause,
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.timeout,
      cause: cause,
    );
  }

  /// Creates a validation error.
  factory HuefyError.validation({
    required String message,
    String? field,
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.validation,
      field: field,
    );
  }

  /// Creates a rate-limited error.
  factory HuefyError.rateLimited({
    String message = 'Rate limit exceeded',
    int? retryAfter,
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.rateLimited,
      statusCode: 429,
      retryAfter: retryAfter,
    );
  }

  /// Creates a server error.
  factory HuefyError.server({
    required String message,
    required int statusCode,
  }) {
    return HuefyError._(
      message: message,
      errorCode: statusCode == 503
          ? ErrorCode.serviceUnavailable
          : ErrorCode.serverError,
      statusCode: statusCode,
    );
  }

  /// Creates a circuit breaker open error.
  factory HuefyError.circuitBreakerOpen({
    String message =
        'Circuit breaker is open -- requests are temporarily blocked',
  }) {
    return HuefyError._(
      message: message,
      errorCode: ErrorCode.circuitBreakerOpen,
    );
  }

  /// Creates an error from an HTTP status code and response body.
  factory HuefyError.fromStatus(int statusCode, String body, {String? requestId}) {
    switch (statusCode) {
      case 401:
        return HuefyError._(
          message: 'Invalid or expired API key',
          errorCode: ErrorCode.authentication,
          statusCode: 401,
          requestId: requestId,
        );
      case 408:
        return HuefyError._(
          message: 'Request timeout: $body',
          errorCode: ErrorCode.timeout,
          statusCode: 408,
          requestId: requestId,
        );
      case 403:
        return HuefyError._(
          message: 'Insufficient permissions',
          errorCode: ErrorCode.authorization,
          statusCode: 403,
          requestId: requestId,
        );
      case 404:
        return HuefyError._(
          message: 'Resource not found',
          errorCode: ErrorCode.notFound,
          statusCode: 404,
          requestId: requestId,
        );
      case 422:
        return HuefyError._(
          message: 'Validation failed: $body',
          errorCode: ErrorCode.validation,
          requestId: requestId,
        );
      case 429:
        return HuefyError._(
          message: 'Rate limit exceeded',
          errorCode: ErrorCode.rateLimited,
          statusCode: 429,
          requestId: requestId,
        );
      default:
        if (statusCode >= 500) {
          return HuefyError._(
            message: 'Server error: $body',
            errorCode: statusCode == 503
                ? ErrorCode.serviceUnavailable
                : ErrorCode.serverError,
            statusCode: statusCode,
            requestId: requestId,
          );
        }
        return HuefyError._(
          message: 'Unexpected status $statusCode: $body',
          errorCode: ErrorCode.unknown,
          statusCode: statusCode,
          requestId: requestId,
        );
    }
  }

  /// Whether this error is potentially recoverable via retry.
  bool get isRecoverable => errorCode.isRecoverable;

  /// Returns the error message with sensitive data redacted.
  String get sanitizedMessage => sanitizeErrorMessage(message);

  @override
  String toString() {
    final prefix = requestId != null ? '[${errorCode.label}] [req:$requestId]' : '[${errorCode.label}]';
    return '$prefix $message';
  }
}
