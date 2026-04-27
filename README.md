# huefy

Official Dart SDK for [Huefy](https://huefy.dev) — transactional email delivery made simple.

Works in both server-side Dart and Flutter.

## Installation

```bash
dart pub add huefy
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  huefy: ^1.0.0
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
import 'package:huefy/huefy.dart';

void main() async {
  final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_your_api_key'));

  final response = await client.sendEmail(
    templateKey: 'welcome-email',
    data: const {'firstName': 'Alice', 'trialDays': 14},
    recipient: 'alice@example.com',
  );

  print('Email ID: ${response.data.emailId}');
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
  templateKey: 'promo',
  recipients: const [
    BulkRecipient(email: 'bob@example.com'),
    BulkRecipient(email: 'carol@example.com'),
  ],
);

print('Sent: ${bulk.data.successCount}, Failed: ${bulk.data.failureCount}');
```

## Error Handling

```dart
import 'package:huefy/huefy.dart';

try {
  final response = await client.sendEmail(request);
  print('Delivered: ${response.data.emailId}');
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
if (health.data.status != 'healthy') {
  debugPrint('Huefy degraded: ${health.data.status}');
}
```

## Local Development

`HUEFY_MODE=local` resolves to `https://api.huefy.on/api/v1/sdk`. To bypass Caddy and hit the raw app port directly, override `baseUrl` to `http://localhost:8080/api/v1/sdk`:

```dart
final client = HuefyEmailClient(
  config: HuefyConfig(
    apiKey: 'sdk_local_key',
    baseUrl: 'https://api.huefy.on/api/v1/sdk',
  ),
);
```

## Developer Guide

Full documentation, advanced patterns, and provider configuration are in the [Dart Developer Guide](../../docs/spec/guides/dart.guide.md).

## License

MIT
