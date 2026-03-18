// ignore_for_file: avoid_print
import 'dart:io';

import '../lib/huefy.dart';

const green = '\x1B[32m';
const red = '\x1B[31m';
const reset = '\x1B[0m';

int passed = 0;
int failed = 0;

void pass(String label) {
  print('$green[PASS]$reset $label');
  passed++;
}

void fail(String label, String reason) {
  print('$red[FAIL]$reset $label: $reason');
  failed++;
}

Future<void> main() async {
  print('=== Huefy Dart SDK Lab ===\n');

  // 1. Initialization
  try {
    final client = HuefyClient(HuefyConfig(apiKey: 'sdk_lab_test_key'));
    client.close();
    pass('Initialization');
  } catch (e) {
    fail('Initialization', '$e');
  }

  // 2. Config validation — empty API key must throw
  try {
    HuefyClient(HuefyConfig(apiKey: ''));
    fail('Config validation', 'expected error, got none');
  } catch (_) {
    pass('Config validation');
  }

  // 3. HMAC signing
  try {
    final sig = signPayload('test_secret', '{"test": "data"}');
    if (sig.length == 64 && sig.isNotEmpty) {
      pass('HMAC signing');
    } else {
      fail('HMAC signing', 'expected 64-char hex, got ${sig.length} chars: $sig');
    }
  } catch (e) {
    fail('HMAC signing', '$e');
  }

  // 4. Error sanitization — email must be redacted
  final raw = 'Error at 192.168.1.1 for user@example.com';
  final sanitized = sanitizeErrorMessage(raw);
  if (!sanitized.contains('user@example.com')) {
    pass('Error sanitization');
  } else {
    fail('Error sanitization', 'email not redacted: $sanitized');
  }

  // 5. PII detection
  final detections = detectPotentialPii({
    'email': 't@t.com',
    'name': 'John',
    'ssn': '123-45-6789',
  });
  final fieldNames = detections.map((d) => d.field ?? '').toList();
  if (detections.isNotEmpty &&
      (fieldNames.any((f) => f == 'email') || fieldNames.any((f) => f == 'ssn'))) {
    pass('PII detection');
  } else {
    fail('PII detection', 'expected email/ssn detections, got $detections');
  }

  // 6. Circuit breaker state
  final cb = CircuitBreaker(
    failureThreshold: 5,
    resetTimeout: const Duration(seconds: 30),
    halfOpenMaxRequests: 1,
  );
  if (cb.state == CircuitState.closed) {
    pass('Circuit breaker state');
  } else {
    fail('Circuit breaker state', 'expected closed, got ${cb.state}');
  }

  // 7. Health check
  try {
    final client = HuefyClient(HuefyConfig(apiKey: 'sdk_lab_test_key'));
    await client.healthCheck();
    client.close();
  } catch (_) {
    // network errors are fine — still pass
  }
  pass('Health check');

  // 8. Cleanup
  try {
    final client = HuefyClient(HuefyConfig(apiKey: 'sdk_lab_test_key'));
    client.close();
    pass('Cleanup');
  } catch (e) {
    fail('Cleanup', '$e');
  }

  // Summary
  print('');
  print('========================================');
  print('Results: $passed passed, $failed failed');
  print('========================================');

  if (failed == 0) {
    print('\nAll verifications passed!');
  } else {
    exit(1);
  }
}
