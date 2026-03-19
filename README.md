# huefy_dart

Official Dart SDK for [Huefy](https://huefy.dev) — transactional email delivery made simple.

Works in both server-side Dart and Flutter.

## Installation

```bash
dart pub add huefy_dart
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  huefy_dart: ^1.0.0
```

Then:

```bash
dart pub get
```

## Requirements

- Dart 3.0+
- Flutter 3.10+ (if used with Flutter)

## Quick Start

```dart
import 'package:huefy_dart/huefy_dart.dart';

void main() async {
  final client = HuefyEmailClient(
    config: HuefyConfig(apiKey: 'sdk_your_api_key'),
  );

  final response = await client.sendEmail(
    SendEmailRequest(
      templateKey: 'welcome-email',
      recipient: const Recipient(email: 'alice@example.com', name: 'Alice'),
      variables: const {'firstName': 'Alice', 'trialDays': 14},
    ),
  );

  print('Message ID: ${response.messageId}');
  client.close();
}
```

## Key Features

- **`async`/`await` throughout** — built on Dart's `http` package, works in isolates
- **Named parameters** — all constructors use named parameters for clarity
- **Sealed error classes** (Dart 3) — exhaustive `switch` on `HuefyError` subtypes
- **Immutable value types** — `const` constructors for request/response objects
- **Flutter-friendly** — no platform channels required; works on all Flutter targets
- **Retry with exponential backoff** — configurable attempts, base delay, ceiling, and jitter
- **Circuit breaker** — opens after 5 consecutive failures, probes after 30 s
- **HMAC-SHA256 signing** — optional request signing for additional integrity verification
- **Key rotation** — primary + secondary API key with seamless failover
- **Rate limit callbacks** — `onRateLimitUpdate` fires whenever rate-limit headers change
- **PII detection** — warns when template variables contain sensitive field patterns

## Configuration Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `apiKey` | — | **Required.** Must have prefix `sdk_`, `srv_`, or `cli_` |
| `baseUrl` | `https://api.huefy.dev/api/v1/sdk` | Override the API base URL |
| `timeout` | `Duration(seconds: 30)` | Request timeout |
| `retryConfig.maxAttempts` | `3` | Total attempts including the first |
| `retryConfig.baseDelay` | `Duration(milliseconds: 500)` | Exponential backoff base delay |
| `retryConfig.maxDelay` | `Duration(seconds: 10)` | Maximum backoff delay |
| `retryConfig.jitter` | `0.2` | Random jitter factor (0–1) |
| `circuitBreakerConfig.failureThreshold` | `5` | Consecutive failures before circuit opens |
| `circuitBreakerConfig.resetTimeout` | `Duration(seconds: 30)` | Duration before half-open probe |
| `secondaryApiKey` | `null` | Backup key used during key rotation |
| `enableRequestSigning` | `false` | Enable HMAC-SHA256 request signing |
| `onRateLimitUpdate` | `null` | Callback fired on rate-limit header changes |

## Bulk Email

```dart
final bulk = await client.sendBulkEmails(
  BulkEmailRequest(
    emails: [
      SendEmailRequest(
        templateKey: 'promo',
        recipient: const Recipient(email: 'bob@example.com'),
      ),
      SendEmailRequest(
        templateKey: 'promo',
        recipient: const Recipient(email: 'carol@example.com'),
      ),
    ],
  ),
);

print('Sent: ${bulk.totalSent}, Failed: ${bulk.totalFailed}');
```

## Error Handling

```dart
import 'package:huefy_dart/huefy_dart.dart';

try {
  final response = await client.sendEmail(request);
  print('Delivered: ${response.messageId}');
} on HuefyAuthError {
  print('Invalid API key');
} on HuefyRateLimitError catch (e) {
  print('Rate limited. Retry after ${e.retryAfter}s');
} on HuefyCircuitOpenError {
  print('Circuit open — service unavailable, backing off');
} on HuefyNetworkError catch (e) {
  print('Network error: $e');
} on HuefyError catch (e) {
  print('Huefy error [${e.code}]: $e');
}
```

### Error Code Reference

| Class | Code | Meaning |
|-------|------|---------|
| `HuefyInitError` | 1001 | Client failed to initialise |
| `HuefyAuthError` | 1102 | API key rejected |
| `HuefyNetworkError` | 1201 | Upstream request failed |
| `HuefyCircuitOpenError` | 1301 | Circuit breaker tripped |
| `HuefyRateLimitError` | 2003 | Rate limit exceeded |
| `HuefyTemplateMissingError` | 2005 | Template key not found |

## Health Check

```dart
final health = await client.healthCheck();
if (health.status != 'healthy') {
  debugPrint('Huefy degraded: ${health.status}');
}
```

## Local Development

Set `HUEFY_MODE=local` to point the SDK at a local Huefy server, or override `baseUrl` in config:

```dart
final client = HuefyEmailClient(
  config: HuefyConfig(
    apiKey: 'sdk_local_key',
    baseUrl: 'http://localhost:3000/api/v1/sdk',
  ),
);
```

## Developer Guide

Full documentation, advanced patterns, and provider configuration are in the [Dart Developer Guide](../../docs/spec/guides/dart.guide.md).

## License

MIT
