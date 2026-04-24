import 'dart:convert';

import 'config.dart';
import 'errors/huefy_error.dart';
import 'http/http_client.dart';
import 'models/email_models.dart';

/// The main SDK client for interacting with the Huefy API.
///
/// Create an instance with a [HuefyConfig] and use it to make
/// authenticated requests.
///
/// ```dart
/// final client = HuefyClient(
///   HuefyConfig(apiKey: 'your-api-key'),
/// );
/// ```
class HuefyClient {
  final HuefyConfig _config;
  late final SdkHttpClient _http;
  bool _closed = false;

  /// Creates a new [HuefyClient] with the given configuration.
  ///
  /// Throws [HuefyError] if the configuration is invalid.
  HuefyClient(this._config) {
    if (_config.apiKey.isEmpty) {
      throw HuefyError.validation(
        message: 'API key is required',
        field: 'apiKey',
      );
    }
    _http = SdkHttpClient(config: _config);
  }

  /// Performs a health check against the API.
  ///
  /// Returns a [HealthResponse] if the API is reachable and healthy.
  ///
  /// Throws [HuefyError] on failure.
  Future<HealthResponse> healthCheck() async {
    _ensureNotClosed();
    final response = await _http.request('GET', '/health');
    final json = jsonDecode(response) as Map<String, dynamic>;
    return HealthResponse.fromJson(json);
  }

  /// Closes the client and releases resources.
  ///
  /// After calling [close], no further requests should be made.
  void close() {
    _closed = true;
    _http.close();
  }

  void _ensureNotClosed() {
    if (_closed) {
      throw HuefyError.validation(
        message: 'Client has been closed',
        field: null,
      );
    }
  }
}
