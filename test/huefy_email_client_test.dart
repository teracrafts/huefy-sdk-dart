import 'package:huefy/huefy.dart';
import 'package:test/test.dart';

void main() {
  group('HuefyEmailClient', () {
    // --- sendEmail validation ---

    group('sendEmail', () {
      test('throws on empty templateKey', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        expect(
          () => client.sendEmail(
            templateKey: '',
            data: {'name': 'John'},
            recipient: 'john@example.com',
          ),
          throwsA(isA<HuefyError>()),
        );
      });

      test('throws on invalid recipient', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        expect(
          () => client.sendEmail(
            templateKey: 'welcome',
            data: {'name': 'John'},
            recipient: 'not-an-email',
          ),
          throwsA(isA<HuefyError>()),
        );
      });

      test('throws when client is closed', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        client.close();
        expect(
          () => client.sendEmail(
            templateKey: 'welcome',
            data: {'name': 'John'},
            recipient: 'john@example.com',
          ),
          throwsA(isA<HuefyError>()),
        );
      });
    });

    // --- sendBulkEmails validation ---

    group('sendBulkEmails', () {
      test('throws on empty recipients', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        expect(
          () => client.sendBulkEmails(
            templateKey: 'welcome',
            recipients: [],
          ),
          throwsA(isA<HuefyError>()),
        );
      });

      test('throws on invalid recipient email', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        expect(
          () => client.sendBulkEmails(
            templateKey: 'welcome',
            recipients: [BulkRecipient(email: 'not-an-email')],
          ),
          throwsA(
            predicate(
              (e) => e is HuefyError && e.message.contains('recipients[0]'),
            ),
          ),
        );
      });

      test('throws when client is closed', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        client.close();
        expect(
          () => client.sendBulkEmails(
            templateKey: 'welcome',
            recipients: [BulkRecipient(email: 'john@example.com')],
          ),
          throwsA(isA<HuefyError>()),
        );
      });
    });

    // --- model construction ---

    group('SendEmailRequest', () {
      test('initializes with named params in correct order', () {
        final request = SendEmailRequest(
          templateKey: 'welcome',
          data: {'name': 'John'},
          recipient: 'john@example.com',
        );
        expect(request.templateKey, equals('welcome'));
        expect(request.data, equals({'name': 'John'}));
        expect(request.recipient, equals('john@example.com'));
        expect(request.providerType, isNull);
      });
    });
  });
}
