import 'dart:convert';

import 'config.dart';
import 'errors/huefy_error.dart';
import 'http/http_client.dart';
import 'models/email_models.dart';
import 'models/email_provider.dart';
import 'security/security.dart' as security;
import 'utils/logger.dart';
import 'validators/email_validators.dart';

/// Email-focused client for the Huefy Dart SDK.
///
/// Extends the base HTTP capabilities with email-specific operations
/// including single and bulk email sending with input validation.
///
/// ```dart
/// final client = HuefyEmailClient(
///   HuefyConfig(apiKey: 'your-api-key'),
/// );
///
/// final response = await client.sendEmail(
///   templateKey: 'welcome',
///   data: {'name': 'John'},
///   recipient: 'john@example.com',
/// );
/// ```
class HuefyEmailClient {
  static const String _emailsSendPath = '/emails/send';
  static const String _emailsBulkPath = '/emails/send-bulk';

  final HuefyConfig _config;
  late final SdkHttpClient _http;
  late final Logger _logger;
  bool _closed = false;

  /// Creates a new [HuefyEmailClient] with the given configuration.
  ///
  /// Throws [HuefyError] if the configuration is invalid.
  HuefyEmailClient(this._config) {
    if (_config.apiKey.isEmpty) {
      throw HuefyError.validation(
        message: 'API key is required',
        field: 'apiKey',
      );
    }
    _http = SdkHttpClient(config: _config);
    _logger = _config.debug ? ConsoleLogger() : NoopLogger();
  }

  /// Sends a single email using the default provider (SES).
  ///
  /// Throws [HuefyError] on validation or network failures.
  Future<SendEmailResponse> sendEmail({
    required String templateKey,
    required Map<String, String> data,
    required String recipient,
    EmailProvider? provider,
  }) async {
    _ensureNotClosed();

    final errors = validateSendEmailInput(templateKey, data, recipient);
    if (errors.isNotEmpty) {
      throw HuefyError.validation(
        message: 'Validation failed: ${errors.join("; ")}',
      );
    }

    // Warn if potential PII fields are detected in template data.
    final piiDetections = security.detectPotentialPii(data);
    if (piiDetections.isNotEmpty) {
      final fields = piiDetections.map((d) => d.toString()).join('; ');
      _logger.warn(
        'Potential PII detected in template data: [$fields]. '
        'Consider removing or encrypting these fields.',
      );
    }

    final request = SendEmailRequest(
      templateKey: templateKey.trim(),
      recipient: recipient.trim(),
      data: data,
      providerType: provider,
    );

    final responseBody = await _http.request(
      'POST',
      _emailsSendPath,
      body: request.toJson(),
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return SendEmailResponse.fromJson(json);
  }

  /// Sends multiple emails in bulk using a shared template.
  ///
  /// Throws [HuefyError] if validation fails.
  Future<SendBulkEmailsResponse> sendBulkEmails(
    String templateKey,
    List<BulkRecipient> recipients, {
    String? fromEmail,
    String? fromName,
    String? providerType,
    int? batchSize,
    String? correlationId,
  }) async {
    _ensureNotClosed();

    final countErr = validateBulkCount(recipients.length);
    if (countErr != null) {
      throw HuefyError.validation(message: countErr);
    }

    final templateErr = validateTemplateKey(templateKey);
    if (templateErr != null) {
      throw HuefyError.validation(message: templateErr);
    }

    final body = <String, dynamic>{
      'templateKey': templateKey.trim(),
      'recipients': recipients.map((r) => r.toJson()).toList(),
      if (fromEmail != null) 'fromEmail': fromEmail,
      if (fromName != null) 'fromName': fromName,
      if (providerType != null) 'providerType': providerType,
      if (batchSize != null) 'batchSize': batchSize,
      if (correlationId != null) 'correlationId': correlationId,
    };

    final responseBody = await _http.request(
      'POST',
      _emailsBulkPath,
      body: body,
    );

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return SendBulkEmailsResponse.fromJson(json);
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
