import 'package:huefy/src/errors/error_code.dart';
import 'package:huefy/src/errors/huefy_error.dart';
import 'package:test/test.dart';

void main() {
  group('HuefyError', () {
    test('maps 402 quota exhaustion to insufficient quota', () {
      final error = HuefyError.fromStatus(
        402,
        '{"error":"Quota exceeded","code":"INSUFFICIENT_QUOTA"}',
        requestId: 'req_123',
      );

      expect(error.errorCode, ErrorCode.insufficientQuota);
      expect(error.errorCode.code, 3003);
      expect(error.errorCode.label, 'INSUFFICIENT_QUOTA');
      expect(error.statusCode, 402);
      expect(error.requestId, 'req_123');
      expect(error.isRecoverable, isFalse);
      expect(error.message, contains('Quota exceeded'));
    });
  });
}
