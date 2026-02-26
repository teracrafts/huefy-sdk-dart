import 'email_provider.dart';

/// Request to send a single email via the Huefy API.
class SendEmailRequest {
  /// The template key identifying the email template (1-100 characters).
  final String templateKey;

  /// The recipient email address.
  final String recipient;

  /// Template data variables to merge into the email.
  final Map<String, String> data;

  /// The email provider to use. Defaults to SES if not specified.
  final EmailProvider? providerType;

  SendEmailRequest({
    required this.templateKey,
    required this.recipient,
    required this.data,
    this.providerType,
  });

  /// Converts this request to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'template_key': templateKey,
      'recipient': recipient,
      'data': data,
    };
    if (providerType != null) {
      json['provider_type'] = providerType!.value;
    }
    return json;
  }
}

/// Response from the send email endpoint.
class SendEmailResponse {
  /// Whether the email was sent successfully.
  final bool success;

  /// A human-readable message from the server.
  final String? message;

  /// The unique identifier for the sent message.
  final String? messageId;

  /// The provider that was used to deliver the email.
  final String? provider;

  SendEmailResponse({
    required this.success,
    this.message,
    this.messageId,
    this.provider,
  });

  factory SendEmailResponse.fromJson(Map<String, dynamic> json) {
    return SendEmailResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      messageId: json['message_id'] as String?,
      provider: json['provider'] as String?,
    );
  }
}

/// Error details for a single email in a bulk operation.
class BulkEmailError {
  /// Error message describing what went wrong.
  final String message;

  /// Error code string.
  final String code;

  BulkEmailError({
    required this.message,
    required this.code,
  });

  factory BulkEmailError.fromJson(Map<String, dynamic> json) {
    return BulkEmailError(
      message: json['message'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code,
      };
}

/// Result of sending a single email in a bulk operation.
class BulkEmailResult {
  /// The recipient email address.
  final String email;

  /// Whether this individual email was sent successfully.
  final bool success;

  /// The response if the email was sent successfully.
  final SendEmailResponse? result;

  /// The error if the email failed to send.
  final BulkEmailError? error;

  BulkEmailResult({
    required this.email,
    required this.success,
    this.result,
    this.error,
  });

  factory BulkEmailResult.fromJson(Map<String, dynamic> json) {
    return BulkEmailResult(
      email: json['email'] as String,
      success: json['success'] as bool,
      result: json['result'] != null
          ? SendEmailResponse.fromJson(json['result'] as Map<String, dynamic>)
          : null,
      error: json['error'] != null
          ? BulkEmailError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response from the health check endpoint.
class EmailHealthResponse {
  /// The status of the API (e.g., "ok").
  final String status;

  /// Server timestamp.
  final String timestamp;

  /// The API version string.
  final String? version;

  EmailHealthResponse({
    required this.status,
    required this.timestamp,
    this.version,
  });

  factory EmailHealthResponse.fromJson(Map<String, dynamic> json) {
    return EmailHealthResponse(
      status: json['status'] as String,
      timestamp: json['timestamp'].toString(),
      version: json['version'] as String?,
    );
  }
}
