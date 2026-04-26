import 'package:test/test.dart';
import 'package:huefy/huefy.dart';

void main() {
  // ---------------------------------------------------------------------------
  // validateEmail
  // ---------------------------------------------------------------------------
  group('validateEmail', () {
    test('returns null for valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(validateEmail('user@mail.example.com'), isNull);
    });

    test('returns error for empty email', () {
      final result = validateEmail('');
      expect(result, isNotNull);
      expect(result, contains('required'));
    });

    test('returns error for email without @ sign', () {
      expect(validateEmail('userexample.com'), isNotNull);
    });

    test('returns error for email without domain', () {
      expect(validateEmail('user@'), isNotNull);
    });

    test('returns error for email exceeding max length', () {
      final longEmail = '${"a" * 250}@b.co';
      final result = validateEmail(longEmail);
      expect(result, isNotNull);
      expect(result, contains('maximum length'));
    });

    test('returns error for email with spaces', () {
      expect(validateEmail('user @example.com'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateTemplateKey
  // ---------------------------------------------------------------------------
  group('validateTemplateKey', () {
    test('returns null for valid template key', () {
      expect(validateTemplateKey('welcome-email'), isNull);
    });

    test('returns error for empty template key', () {
      final result = validateTemplateKey('');
      expect(result, isNotNull);
      expect(result, contains('required'));
    });

    test('returns error for whitespace-only template key', () {
      expect(validateTemplateKey('   '), isNotNull);
    });

    test('returns error for template key exceeding max length', () {
      final longKey = 'a' * 101;
      final result = validateTemplateKey(longKey);
      expect(result, isNotNull);
      expect(result, contains('maximum length'));
    });

    test('returns null for template key at max length', () {
      final key = 'a' * 100;
      expect(validateTemplateKey(key), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateEmailData
  // ---------------------------------------------------------------------------
  group('validateEmailData', () {
    test('returns null for valid data', () {
      expect(validateEmailData({'name': 'John'}), isNull);
    });

    test('returns null for structured data', () {
      expect(
        validateEmailData({
          'count': 2,
          'beta': true,
          'profile': {'plan': 'pro'},
        }),
        isNull,
      );
    });

    test('returns error for null data', () {
      expect(validateEmailData(null), isNotNull);
    });

    test('returns null for empty data map', () {
      expect(validateEmailData({}), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validateBulkCount
  // ---------------------------------------------------------------------------
  group('validateBulkCount', () {
    test('returns null for valid count', () {
      expect(validateBulkCount(10), isNull);
    });

    test('returns null for count at limit', () {
      expect(validateBulkCount(100), isNull);
    });

    test('returns error for zero count', () {
      expect(validateBulkCount(0), isNotNull);
    });

    test('returns error for negative count', () {
      expect(validateBulkCount(-1), isNotNull);
    });

    test('returns error for count over limit', () {
      final result = validateBulkCount(1001);
      expect(result, isNotNull);
      expect(result, contains('maximum'));
    });
  });

  // ---------------------------------------------------------------------------
  // validateSendEmailInput
  // ---------------------------------------------------------------------------
  group('validateSendEmailInput', () {
    test('returns empty list for valid input', () {
      final errors = validateSendEmailInput(
        'welcome',
        {'name': 'John', 'count': 2},
        'user@example.com',
      );
      expect(errors, isEmpty);
    });

    test('returns multiple errors for all invalid input', () {
      final errors = validateSendEmailInput('', null, 'bad');
      expect(errors.length, greaterThanOrEqualTo(3));
    });

    test('returns single error for partially invalid input', () {
      final errors = validateSendEmailInput(
        'welcome',
        {'name': 'John'},
        'bad',
      );
      expect(errors.length, equals(1));
    });
  });
}
