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
    required this.data,
    required this.recipient,
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

/// Status of a single recipient in an email send or bulk send operation.
class RecipientStatus {
  final String email;
  final String status;
  final String? messageId;
  final String? error;
  final String? sentAt;

  const RecipientStatus({
    required this.email,
    required this.status,
    this.messageId,
    this.error,
    this.sentAt,
  });

  factory RecipientStatus.fromJson(Map<String, dynamic> json) => RecipientStatus(
        email: json['email'] as String,
        status: json['status'] as String,
        messageId: json['messageId'] as String?,
        error: json['error'] as String?,
        sentAt: json['sentAt'] as String?,
      );
}

/// Data payload from the send email response.
class SendEmailResponseData {
  final String emailId;
  final String status;
  final List<RecipientStatus> recipients;

  const SendEmailResponseData({
    required this.emailId,
    required this.status,
    required this.recipients,
  });

  factory SendEmailResponseData.fromJson(Map<String, dynamic> json) =>
      SendEmailResponseData(
        emailId: json['emailId'] as String,
        status: json['status'] as String,
        recipients: (json['recipients'] as List)
            .map((r) => RecipientStatus.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

/// Response from the send email endpoint.
class SendEmailResponse {
  final bool success;
  final SendEmailResponseData data;
  final String correlationId;

  const SendEmailResponse({
    required this.success,
    required this.data,
    required this.correlationId,
  });

  factory SendEmailResponse.fromJson(Map<String, dynamic> json) => SendEmailResponse(
        success: json['success'] as bool,
        data: SendEmailResponseData.fromJson(json['data'] as Map<String, dynamic>),
        correlationId: json['correlationId'] as String,
      );
}

/// A recipient entry for bulk email sending.
class BulkRecipient {
  final String email;
  final String type;
  final Map<String, dynamic>? data;

  const BulkRecipient({
    required this.email,
    this.type = 'to',
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'type': type,
        if (data != null) 'data': data,
      };
}

/// Data payload from the send-bulk response.
class SendBulkEmailsResponseData {
  final String batchId;
  final String status;
  final String templateKey;
  final int totalRecipients;
  final int successCount;
  final int failureCount;
  final int suppressedCount;
  final String startedAt;
  final String? completedAt;
  final List<RecipientStatus> recipients;

  const SendBulkEmailsResponseData({
    required this.batchId,
    required this.status,
    required this.templateKey,
    required this.totalRecipients,
    required this.successCount,
    required this.failureCount,
    required this.suppressedCount,
    required this.startedAt,
    this.completedAt,
    required this.recipients,
  });

  factory SendBulkEmailsResponseData.fromJson(Map<String, dynamic> json) =>
      SendBulkEmailsResponseData(
        batchId: json['batchId'] as String,
        status: json['status'] as String,
        templateKey: json['templateKey'] as String,
        totalRecipients: json['totalRecipients'] as int,
        successCount: json['successCount'] as int,
        failureCount: json['failureCount'] as int,
        suppressedCount: json['suppressedCount'] as int,
        startedAt: json['startedAt'] as String,
        completedAt: json['completedAt'] as String?,
        recipients: (json['recipients'] as List)
            .map((r) => RecipientStatus.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

/// Response from the send-bulk endpoint.
class SendBulkEmailsResponse {
  final bool success;
  final SendBulkEmailsResponseData data;
  final String correlationId;

  const SendBulkEmailsResponse({
    required this.success,
    required this.data,
    required this.correlationId,
  });

  factory SendBulkEmailsResponse.fromJson(Map<String, dynamic> json) =>
      SendBulkEmailsResponse(
        success: json['success'] as bool,
        data: SendBulkEmailsResponseData.fromJson(
            json['data'] as Map<String, dynamic>),
        correlationId: json['correlationId'] as String,
      );
}

/// Data payload from the health check response.
class HealthResponseData {
  final String status;
  final String timestamp;
  final String version;

  const HealthResponseData({
    required this.status,
    required this.timestamp,
    required this.version,
  });

  factory HealthResponseData.fromJson(Map<String, dynamic> json) =>
      HealthResponseData(
        status: json['status'] as String,
        timestamp: json['timestamp'] as String,
        version: json['version'] as String,
      );
}

/// Response from the health check endpoint.
class HealthResponse {
  final bool success;
  final HealthResponseData data;
  final String correlationId;

  const HealthResponse({
    required this.success,
    required this.data,
    required this.correlationId,
  });

  factory HealthResponse.fromJson(Map<String, dynamic> json) => HealthResponse(
        success: json['success'] as bool,
        data: HealthResponseData.fromJson(json['data'] as Map<String, dynamic>),
        correlationId: json['correlationId'] as String,
      );
}
