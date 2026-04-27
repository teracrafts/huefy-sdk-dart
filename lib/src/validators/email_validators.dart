/// Validation utilities for email-related inputs.

import '../models/email_models.dart';

/// Maximum allowed email address length.
const int maxEmailLength = 254;

/// Maximum allowed template key length.
const int maxTemplateKeyLength = 100;

/// Maximum number of emails in a single bulk request.
const int maxBulkEmails = 1000;

/// Regex pattern for basic email validation.
final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
const Set<String> _validRecipientTypes = {'to', 'cc', 'bcc'};

/// Validates a recipient email address.
///
/// Returns `null` if valid, or an error message string if invalid.
String? validateEmail(String email) {
  if (email.isEmpty) {
    return 'recipient email is required';
  }

  final trimmed = email.trim();

  if (trimmed.length > maxEmailLength) {
    return 'email exceeds maximum length of $maxEmailLength characters';
  }

  if (!_emailRegex.hasMatch(trimmed)) {
    return 'invalid email address: $trimmed';
  }

  return null;
}

/// Validates a template key.
///
/// Returns `null` if valid, or an error message string if invalid.
String? validateTemplateKey(String key) {
  if (key.isEmpty) {
    return 'template key is required';
  }

  final trimmed = key.trim();

  if (trimmed.isEmpty) {
    return 'template key cannot be empty';
  }

  if (trimmed.length > maxTemplateKeyLength) {
    return 'template key exceeds maximum length of $maxTemplateKeyLength characters';
  }

  return null;
}

/// Validates template data.
///
/// Returns `null` if valid, or an error message string if invalid.
String? validateEmailData(Map<String, dynamic>? data) {
  if (data == null) {
    return 'template data is required';
  }
  return null;
}

/// Validates the count of emails in a bulk request.
///
/// Returns `null` if valid, or an error message string if invalid.
String? validateBulkCount(int count) {
  if (count <= 0) {
    return 'at least one email is required';
  }
  if (count > maxBulkEmails) {
    return 'maximum of $maxBulkEmails emails per bulk request';
  }
  return null;
}

/// Validates all inputs for sending a single email.
///
/// Returns a list of error message strings. Empty if all inputs are valid.
String? validateRecipientObject(SendEmailRecipient? recipient) {
  if (recipient == null) {
    return 'recipient email is required';
  }
  final emailErr = validateEmail(recipient.email);
  if (emailErr != null) return emailErr;
  final recipientType = recipient.type?.trim().toLowerCase();
  if (recipientType != null &&
      recipientType.isNotEmpty &&
      !_validRecipientTypes.contains(recipientType)) {
    return 'recipient type must be one of: to, cc, bcc';
  }
  return null;
}

String? validateBulkRecipient(BulkRecipient? recipient) {
  if (recipient == null) {
    return 'recipient email is required';
  }

  final emailErr = validateEmail(recipient.email);
  if (emailErr != null) return emailErr;

  final recipientType = recipient.type.trim().toLowerCase();
  if (recipientType.isNotEmpty && !_validRecipientTypes.contains(recipientType)) {
    return 'recipient type must be one of: to, cc, bcc';
  }

  if (recipient.data != null && recipient.data is! Map<String, dynamic>) {
    return 'recipient data must be an object';
  }

  return null;
}

List<String> validateSendEmailInput(
  String templateKey,
  Map<String, dynamic>? data,
  Object? recipient,
) {
  final errors = <String>[];

  final templateErr = validateTemplateKey(templateKey);
  if (templateErr != null) errors.add(templateErr);

  final dataErr = validateEmailData(data);
  if (dataErr != null) errors.add(dataErr);

  final emailErr = switch (recipient) {
    String value => validateEmail(value),
    SendEmailRecipient value => validateRecipientObject(value),
    null => 'recipient email is required',
    _ => 'recipient must be a string or recipient object',
  };
  if (emailErr != null) errors.add(emailErr);

  return errors;
}
