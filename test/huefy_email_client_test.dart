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

      test('throws on invalid recipient type', () {
        final client = HuefyEmailClient(HuefyConfig(apiKey: 'sdk_test_key'));
        expect(
          () => client.sendBulkEmails(
            templateKey: 'welcome',
            recipients: [BulkRecipient(email: 'john@example.com', type: 'reply-to')],
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
        expect(request.recipientObject, isNull);
        expect(request.providerType, isNull);
      });

      test('serializes single-send requests with camelCase keys', () {
        final request = SendEmailRequest(
          templateKey: 'welcome',
          data: {
            'name': 'John',
            'count': 2,
            'beta': true,
          },
          recipient: 'john@example.com',
          providerType: EmailProvider.sendgrid,
        );

        final json = request.toJson();
        expect(json['templateKey'], equals('welcome'));
        expect(json['providerType'], equals('sendgrid'));
        expect(json.containsKey('template_key'), isFalse);
        expect(json.containsKey('provider_type'), isFalse);

        final data = json['data'] as Map<String, dynamic>;
        expect(data['name'], equals('John'));
        expect(data['count'], equals(2));
        expect(data['beta'], isTrue);
      });

      test('serializes recipient objects when provided', () {
        final request = SendEmailRequest.withRecipientObject(
          templateKey: 'welcome',
          data: {'name': 'John'},
          recipient: const SendEmailRecipient(
            email: 'john@example.com',
            type: 'cc',
            data: {'segment': 'vip'},
          ),
          providerType: EmailProvider.ses,
        );

        final json = request.toJson();
        final recipient = json['recipient'] as Map<String, dynamic>;
        expect(recipient['email'], equals('john@example.com'));
        expect(recipient['type'], equals('cc'));
        expect((recipient['data'] as Map<String, dynamic>)['segment'], equals('vip'));
      });
    });
  });
}
