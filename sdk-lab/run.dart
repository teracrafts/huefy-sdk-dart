// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import '../lib/huefy.dart';

const green = '\x1B[32m';
const red = '\x1B[31m';
const reset = '\x1B[0m';

int passed = 0;
int failed = 0;

void pass(String label) {
  passed++;
  print('$green[PASS]$reset $label');
}

void fail(String label, String reason) {
  failed++;
  print('$red[FAIL]$reset $label - $reason');
}

Future<void> main() async {
  print('=== Huefy Dart SDK Lab ===\n');

  final server = await _StubServer.start();
  try {
    HuefyEmailClient? client;
    try {
      client = _buildClient(server.baseUrl);
      pass('Initialization');
    } catch (e) {
      fail('Initialization', '$e');
    }

    if (client != null) {
      await _verifySingleSend(client, server);
      await _verifyBulkSend(client, server);
      await _verifyInvalidSingle(client, server);
      await _verifyInvalidBulk(client, server);
      await _verifyHealth(client, server);
      await _verifyCleanup(client);
    }
  } finally {
    await server.close();
  }

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

HuefyEmailClient _buildClient(String baseUrl) {
  return HuefyEmailClient(
    HuefyConfig(
      apiKey: 'sdk_lab_test_key_xxxxxxxxxxxx',
      baseUrl: baseUrl,
      timeout: const Duration(seconds: 2),
      retry: const RetryConfig(
        maxRetries: 0,
        initialDelay: Duration(milliseconds: 50),
        maxDelay: Duration(milliseconds: 50),
      ),
    ),
  );
}

Future<void> _verifySingleSend(HuefyEmailClient client, _StubServer server) async {
  try {
    final response = await client.sendEmail(
      templateKey: ' welcome-email ',
      data: {
        'name': 'John',
        'count': 2,
        'beta': true,
        'roles': ['admin', 'editor'],
      },
      recipient: ' john@example.com ',
      provider: EmailProvider.sendgrid,
    );

    final body = server.lastBody('/emails/send');
    if (!response.success) {
      fail('Single-send contract shaping', 'stub response was not parsed as success');
      return;
    }
    if (server.lastPath('/emails/send') != '/emails/send' ||
        body == null ||
        body['templateKey'] != 'welcome-email' ||
        body['recipient'] != 'john@example.com' ||
        body['providerType'] != 'sendgrid' ||
        body.containsKey('template_key') ||
        body.containsKey('provider') ||
        (body['data'] as Map<String, dynamic>)['name'] != 'John' ||
        (body['data'] as Map<String, dynamic>)['count'] != 2 ||
        (body['data'] as Map<String, dynamic>)['beta'] != true ||
        ((body['data'] as Map<String, dynamic>)['roles'] as List<dynamic>).first != 'admin') {
      fail('Single-send contract shaping', 'captured request body did not match contract');
      return;
    }
    pass('Single-send contract shaping');
  } catch (e) {
    fail('Single-send contract shaping', '$e');
  }
}

Future<void> _verifyBulkSend(HuefyEmailClient client, _StubServer server) async {
  try {
    await client.sendBulkEmails(
      templateKey: ' account-update ',
      recipients: const [
        BulkRecipient(
          email: ' alice@example.com ',
          type: 'TO',
          data: {'segment': 'vip'},
        ),
        BulkRecipient(
          email: 'bob@example.com',
          type: 'cc',
          data: {'segment': 'standard'},
        ),
      ],
      provider: EmailProvider.ses,
    );

    final body = server.lastBody('/emails/send-bulk');
    final recipients = body?['recipients'] as List<dynamic>?;
    if (server.lastPath('/emails/send-bulk') != '/emails/send-bulk' ||
        body == null ||
        body['templateKey'] != 'account-update' ||
        body['providerType'] != 'ses' ||
        recipients == null ||
        (recipients[0] as Map<String, dynamic>)['email'] != 'alice@example.com' ||
        (recipients[0] as Map<String, dynamic>)['type'] != 'to' ||
        ((recipients[0] as Map<String, dynamic>)['data'] as Map<String, dynamic>)['segment'] != 'vip' ||
        (recipients[1] as Map<String, dynamic>)['type'] != 'cc') {
      fail('Bulk-send contract shaping', 'captured request body did not match contract');
      return;
    }
    pass('Bulk-send contract shaping');
  } catch (e) {
    fail('Bulk-send contract shaping', '$e');
  }
}

Future<void> _verifyInvalidSingle(HuefyEmailClient client, _StubServer server) async {
  final before = server.hitCount('/emails/send');
  try {
    await client.sendEmail(
      templateKey: 'welcome',
      data: {'name': 'John'},
      recipient: 'not-an-email',
    );
    fail('Invalid single rejection', 'expected validation failure');
  } catch (e) {
    if (server.hitCount('/emails/send') != before) {
      fail('Invalid single rejection', 'transport was called for invalid single input');
    } else if (e is! HuefyError || !e.message.contains('Validation failed')) {
      fail('Invalid single rejection', '$e');
    } else {
      pass('Invalid single rejection');
    }
  }
}

Future<void> _verifyInvalidBulk(HuefyEmailClient client, _StubServer server) async {
  final before = server.hitCount('/emails/send-bulk');
  try {
    await client.sendBulkEmails(
      templateKey: 'welcome',
      recipients: const [
        BulkRecipient(
          email: 'john@example.com',
          type: 'reply-to',
          data: {'segment': 'vip'},
        ),
      ],
    );
    fail('Invalid bulk rejection', 'expected validation failure');
  } catch (e) {
    if (server.hitCount('/emails/send-bulk') != before) {
      fail('Invalid bulk rejection', 'transport was called for invalid bulk input');
    } else if (e is! HuefyError || !e.message.contains('recipients[0]')) {
      fail('Invalid bulk rejection', '$e');
    } else {
      pass('Invalid bulk rejection');
    }
  }
}

Future<void> _verifyHealth(HuefyEmailClient client, _StubServer server) async {
  try {
    final health = await client.healthCheck();
    if (server.lastPath('/health') != '/health' || health.data.status != 'healthy') {
      fail('Health request path behavior', 'health request did not use expected path');
      return;
    }
    pass('Health request path behavior');
  } catch (e) {
    fail('Health request path behavior', '$e');
  }
}

Future<void> _verifyCleanup(HuefyEmailClient client) async {
  try {
    client.close();
    await client.healthCheck();
    fail('Cleanup', 'expected closed client to reject requests');
  } catch (e) {
    if (e is HuefyError && e.message.contains('Client has been closed')) {
      pass('Cleanup');
    } else {
      fail('Cleanup', '$e');
    }
  }
}

class _StubServer {
  _StubServer._(this._server) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  final Map<String, int> _hitCounts = <String, int>{};
  final Map<String, String> _lastPaths = <String, String>{};
  final Map<String, Map<String, dynamic>> _lastBodies = <String, Map<String, dynamic>>{};

  static Future<_StubServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _StubServer._(server);
  }

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  int hitCount(String path) => _hitCounts[path] ?? 0;

  String? lastPath(String path) => _lastPaths[path];

  Map<String, dynamic>? lastBody(String path) => _lastBodies[path];

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    _hitCounts[path] = hitCount(path) + 1;
    _lastPaths[path] = path;

    final body = await utf8.decoder.bind(request).join();
    if (body.trim().isNotEmpty) {
      _lastBodies[path] = jsonDecode(body) as Map<String, dynamic>;
    }

    final responseBody = switch (path) {
      '/emails/send' => _singleSendResponse,
      '/emails/send-bulk' => _bulkSendResponse,
      '/health' => _healthResponse,
      _ => '{"success":false}',
    };

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(responseBody);
    await request.response.close();
  }

  Future<void> close() => _server.close(force: true);
}

const _singleSendResponse =
    '{"success":true,"data":{"emailId":"email_123","status":"queued","recipients":[{"email":"john@example.com","status":"queued","messageId":"msg_123","sentAt":"2026-01-01T00:00:00Z"}]},"correlationId":"corr_single"}';

const _bulkSendResponse =
    '{"success":true,"data":{"batchId":"batch_123","status":"queued","templateKey":"account-update","templateVersion":1,"senderUsed":"noreply@example.com","senderVerified":true,"totalRecipients":2,"processedCount":2,"successCount":2,"failureCount":0,"suppressedCount":0,"startedAt":"2026-01-01T00:00:00Z","completedAt":"2026-01-01T00:00:01Z","recipients":[{"email":"alice@example.com","status":"queued","messageId":"msg_1","sentAt":"2026-01-01T00:00:00Z"},{"email":"bob@example.com","status":"queued","messageId":"msg_2","sentAt":"2026-01-01T00:00:00Z"}],"errors":[],"metadata":{"source":"sdk-lab"}},"correlationId":"corr_bulk"}';

const _healthResponse =
    '{"success":true,"data":{"status":"healthy","timestamp":"2026-01-01T00:00:00Z","version":"sdk-lab"},"correlationId":"corr_health"}';
