/// Huefy - Official Dart SDK.
///
/// Provides a type-safe client for interacting with the Huefy API.
///
/// ```dart
/// import 'package:huefy/huefy.dart';
///
/// final client = HuefyClient(
///   HuefyConfig(apiKey: 'your-api-key'),
/// );
///
/// final health = await client.healthCheck();
/// print(health.data.status);
/// ```
library huefy;

export 'src/client.dart';
export 'src/config.dart';
export 'src/errors/error_code.dart';
export 'src/errors/huefy_error.dart';
export 'src/errors/error_sanitizer.dart';
export 'src/http/http_client.dart';
export 'src/http/circuit_breaker.dart';
export 'src/http/retry_handler.dart';
export 'src/models/email_provider.dart';
export 'src/models/email_models.dart';
export 'src/validators/email_validators.dart';
export 'src/huefy_email_client.dart';
export 'src/security/security.dart';
export 'src/utils/version.dart';
export 'src/utils/logger.dart';
