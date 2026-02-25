import 'dart:math';

import '../errors/huefy_error.dart';

/// Handles retry logic with exponential backoff and jitter.
class RetryHandler {
  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay before the first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Multiplier applied to the delay after each retry.
  final double backoffMultiplier;

  final Random _random = Random();

  /// Creates a new [RetryHandler].
  RetryHandler({
    required this.maxRetries,
    required this.initialDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
  });

  /// Executes [operation] with retry logic.
  ///
  /// Only recoverable errors trigger a retry. Non-recoverable errors are
  /// rethrown immediately.
  Future<T> execute<T>(Future<T> Function() operation) async {
    HuefyError? lastError;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } on HuefyError catch (e) {
        lastError = e;

        if (!e.isRecoverable || attempt == maxRetries) {
          rethrow;
        }

        final delay = calculateDelay(attempt);
        await Future<void>.delayed(delay);
      }
    }

    // Should be unreachable, but satisfies the type checker.
    throw lastError ??
        HuefyError.network(message: 'Retry loop exited without result');
  }

  /// Calculates the retry delay for the given [attempt] number.
  ///
  /// Uses exponential backoff with random jitter of up to 20% of the base
  /// delay, capped at [maxDelay].
  Duration calculateDelay(int attempt) {
    final baseMs = initialDelay.inMilliseconds *
        pow(backoffMultiplier, attempt).toInt();
    final cappedMs = min(baseMs, maxDelay.inMilliseconds);

    // Add up to 20% jitter.
    final jitter = (_random.nextDouble() * 0.2 * cappedMs).toInt();

    return Duration(milliseconds: cappedMs + jitter);
  }

  /// Parses a `Retry-After` header value into a [Duration].
  ///
  /// Supports delta-seconds format only (e.g., `"120"`). Returns `null` for
  /// unparseable values.
  static Duration? parseRetryAfter(String value) {
    final seconds = int.tryParse(value.trim());
    if (seconds == null) return null;
    return Duration(seconds: seconds);
  }
}
