import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../errors/error_sanitizer.dart';
import '../errors/huefy_error.dart';
import '../security/security.dart' as security;
import '../utils/version.dart';
import 'circuit_breaker.dart';
import 'retry_handler.dart';

/// HTTP client that wraps the `http` package with retry logic, circuit
/// breaking, and automatic header injection.
class SdkHttpClient {
  final HuefyConfig _config;
  final http.Client _inner;
  final CircuitBreaker _circuitBreaker;
  final RetryHandler _retryHandler;

  /// Creates a new [SdkHttpClient] from the given SDK configuration.
  SdkHttpClient({required HuefyConfig config})
      : _config = config,
        _inner = http.Client(),
        _circuitBreaker = CircuitBreaker(
          failureThreshold: config.circuitBreaker.failureThreshold,
          resetTimeout: config.circuitBreaker.resetTimeout,
          halfOpenMaxRequests: config.circuitBreaker.halfOpenMaxRequests,
        ),
        _retryHandler = RetryHandler(
          maxRetries: config.retry.maxRetries,
          initialDelay: config.retry.initialDelay,
          maxDelay: config.retry.maxDelay,
          backoffMultiplier: config.retry.backoffMultiplier,
        );

  /// Sends an HTTP request with retry and circuit breaker protection.
  ///
  /// Returns the response body as a [String].
  ///
  /// Throws [HuefyError] on failure.
  Future<String> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final url = Uri.parse('${_config.baseUrl.replaceAll(RegExp(r'/$'), '')}$path');

    return _retryHandler.execute(() async {
      return _circuitBreaker.execute(() async {
        final bodyString = body != null ? jsonEncode(body) : '';

        final headers = <String, String>{
          'Content-Type': 'application/json',
          'X-API-Key': _config.apiKey,
          'User-Agent': 'huefy-dart/$sdkVersion',
        };

        if (_config.enableRequestSigning) {
          final timestamp =
              DateTime.now().millisecondsSinceEpoch.toString();
          final message = '$timestamp.$bodyString';
          final signature =
              security.signPayload(_config.apiKey, message);

          headers['X-Timestamp'] = timestamp;
          headers['X-Signature'] = signature;
          headers['X-Key-Id'] = _config.apiKey.length >= 8
              ? _config.apiKey.substring(0, 8)
              : _config.apiKey;
        }

        http.Response response;
        try {
          switch (method.toUpperCase()) {
            case 'GET':
              response = await _inner
                  .get(url, headers: headers)
                  .timeout(_config.timeout);
              break;
            case 'POST':
              response = await _inner
                  .post(url, headers: headers, body: bodyString.isNotEmpty ? bodyString : null)
                  .timeout(_config.timeout);
              break;
            case 'PUT':
              response = await _inner
                  .put(url, headers: headers, body: bodyString.isNotEmpty ? bodyString : null)
                  .timeout(_config.timeout);
              break;
            case 'DELETE':
              response = await _inner
                  .delete(url, headers: headers)
                  .timeout(_config.timeout);
              break;
            case 'PATCH':
              response = await _inner
                  .patch(url, headers: headers, body: bodyString.isNotEmpty ? bodyString : null)
                  .timeout(_config.timeout);
              break;
            default:
              throw HuefyError.validation(
                message: 'Unsupported HTTP method: $method',
                field: 'method',
              );
          }
        } on TimeoutException catch (e) {
          throw HuefyError.timeout(cause: e);
        } on http.ClientException catch (e) {
          throw HuefyError.network(
            message: _maybeSanitize('HTTP request failed: ${e.message}'),
            cause: e,
          );
        } catch (e) {
          if (e is HuefyError) rethrow;
          throw HuefyError.network(
            message: _maybeSanitize('Unexpected error: $e'),
            cause: e,
          );
        }

        if (response.statusCode >= 400) {
          final requestId = response.headers['x-request-id'];
          throw HuefyError.fromStatus(
            response.statusCode,
            _maybeSanitize(response.body),
            requestId: requestId,
          );
        }

        _parseRateLimitHeaders(response);

        return response.body;
      });
    });
  }

  void _parseRateLimitHeaders(http.Response response) {
    final limitStr     = response.headers['x-ratelimit-limit'];
    final remainingStr = response.headers['x-ratelimit-remaining'];
    final resetStr     = response.headers['x-ratelimit-reset'];

    if (limitStr == null || remainingStr == null || resetStr == null) return;

    final limit     = int.tryParse(limitStr);
    final remaining = int.tryParse(remainingStr);
    final resetSecs = int.tryParse(resetStr);

    if (limit == null || remaining == null || resetSecs == null) return;

    final info = RateLimitInfo(
      limit: limit,
      remaining: remaining,
      resetAt: DateTime.fromMillisecondsSinceEpoch(resetSecs * 1000, isUtc: true),
    );

    _config.onRateLimitUpdate?.call(info);

    if (limit > 0 && remaining < (limit * 0.2).floor()) {
      _config.onRateLimitWarning?.call(info);
    }
  }

  /// Sanitizes [input] if error sanitization is enabled; otherwise returns
  /// [input] unchanged.
  String _maybeSanitize(String input) =>
      _config.enableErrorSanitization ? sanitizeErrorMessage(input) : input;

  /// Closes the underlying HTTP client.
  void close() {
    _inner.close();
  }
}
