import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../errors/huefy_error.dart';
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
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'X-API-Key': _config.apiKey,
          'User-Agent': 'huefy-dart/$sdkVersion',
        };

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
                  .post(url, headers: headers, body: jsonEncode(body))
                  .timeout(_config.timeout);
              break;
            case 'PUT':
              response = await _inner
                  .put(url, headers: headers, body: jsonEncode(body))
                  .timeout(_config.timeout);
              break;
            case 'DELETE':
              response = await _inner
                  .delete(url, headers: headers)
                  .timeout(_config.timeout);
              break;
            case 'PATCH':
              response = await _inner
                  .patch(url, headers: headers, body: jsonEncode(body))
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
            message: 'HTTP request failed: ${e.message}',
            cause: e,
          );
        } catch (e) {
          if (e is HuefyError) rethrow;
          throw HuefyError.network(
            message: 'Unexpected error: $e',
            cause: e,
          );
        }

        if (response.statusCode >= 400) {
          throw HuefyError.fromStatus(
            response.statusCode,
            response.body,
          );
        }

        return response.body;
      });
    });
  }

  /// Closes the underlying HTTP client.
  void close() {
    _inner.close();
  }
}
