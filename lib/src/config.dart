import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

/// Parsed rate-limit header values from an API response.
class RateLimitInfo {
  /// The request limit as reported by the server.
  final int limit;

  /// The number of remaining requests in the current window.
  final int remaining;

  /// The time at which the current rate-limit window resets.
  final DateTime resetAt;

  const RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  });
}

/// Configuration for retry behavior on failed requests.
class RetryConfig {
  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier applied to the delay after each retry.
  final double backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 2.0,
  });
}

/// Configuration for the circuit breaker protecting outbound requests.
class CircuitBreakerConfig {
  /// Number of consecutive failures before the circuit opens.
  final int failureThreshold;

  /// Duration the circuit stays open before transitioning to half-open.
  final Duration resetTimeout;

  /// Number of successful probes required to close the circuit again.
  final int halfOpenMaxRequests;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.halfOpenMaxRequests = 1,
  });
}

/// Primary configuration for the Huefy Dart SDK client.
///
/// ```dart
/// final config = HuefyConfig(
///   apiKey: 'your-api-key',
///   baseUrl: 'https://custom.api.com', // optional
/// );
/// ```
class HuefyConfig {
  /// API key used for authentication.
  final String apiKey;

  /// Base URL of the API.
  final String baseUrl;

  /// Request timeout.
  final Duration timeout;

  /// Retry configuration.
  final RetryConfig retry;

  /// Circuit breaker configuration.
  final CircuitBreakerConfig circuitBreaker;

  /// Enable debug logging.
  final bool debug;

  /// Enable HMAC-SHA256 request signing.
  final bool enableRequestSigning;

  /// Enable sanitization of sensitive data in error messages.
  final bool enableErrorSanitization;

  /// Optional callback invoked with rate-limit info after every successful response.
  final void Function(RateLimitInfo)? onRateLimitUpdate;

  /// Optional callback invoked when remaining requests drop below 20% of the limit.
  final void Function(RateLimitInfo)? onRateLimitWarning;

  /// Creates a new [HuefyConfig].
  ///
  /// The [apiKey] parameter is required. All other parameters have sensible
  /// defaults.
  HuefyConfig({
    required this.apiKey,
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.retry = const RetryConfig(),
    this.circuitBreaker = const CircuitBreakerConfig(),
    this.debug = false,
    this.enableRequestSigning = false,
    this.enableErrorSanitization = true,
    this.onRateLimitUpdate,
    this.onRateLimitWarning,
  }) : baseUrl = baseUrl ?? _defaultBaseUrl() {
    if (timeout.inMilliseconds <= 0) {
      throw ArgumentError.value(timeout, 'timeout', 'must be > 0');
    }
    if (retry.initialDelay.inMilliseconds <= 0) {
      throw ArgumentError.value(
        retry.initialDelay,
        'retry.initialDelay',
        'must be > 0',
      );
    }
    if (circuitBreaker.resetTimeout.inMilliseconds <= 0) {
      throw ArgumentError.value(
        circuitBreaker.resetTimeout,
        'circuitBreaker.resetTimeout',
        'must be > 0',
      );
    }
  }

  static String _defaultBaseUrl() {
    final envMode = getEnvironmentVariable('HUEFY_MODE') ?? '';
    if (envMode.toLowerCase() == 'local') {
      return 'https://api.huefy.on/api/v1/sdk';
    }
    return 'https://api.huefy.dev/api/v1/sdk';
  }
}
