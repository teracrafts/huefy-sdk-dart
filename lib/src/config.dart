import 'dart:io' show Platform;

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
    this.initialDelay = const Duration(milliseconds: 1000),
    this.maxDelay = const Duration(seconds: 30),
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
  }) : baseUrl = baseUrl ?? _defaultBaseUrl() {
    assert(timeout.inMilliseconds > 0, 'timeout must be > 0');
    assert(
      retry.initialDelay.inMilliseconds > 0,
      'retry.initialDelay must be > 0',
    );
    assert(
      circuitBreaker.resetTimeout.inMilliseconds > 0,
      'circuitBreaker.resetTimeout must be > 0',
    );
  }

  static String _defaultBaseUrl() {
    final envMode = Platform.environment['HUEFY_MODE'] ?? '';
    if (envMode.toLowerCase() == 'development') {
      return 'https://api.huefy.on/api/v1/sdk';
    }
    return 'https://api.huefy.dev/api/v1/sdk';
  }
}
