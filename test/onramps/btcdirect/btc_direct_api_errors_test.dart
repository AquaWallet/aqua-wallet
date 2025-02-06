import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BTCDirectException', () {
    test('fromResponse handles empty/null errors', () {
      final emptyResponse = {'errors': <String, dynamic>{}};
      final nullResponse = <String, dynamic>{};

      expect(
        BTCDirectException.fromResponse(emptyResponse).code,
        equals(BTCDirectErrorCode.unknown),
      );
      expect(
        BTCDirectException.fromResponse(nullResponse).code,
        equals(BTCDirectErrorCode.unknown),
      );
    });

    test('fromResponse correctly parses error code and message', () {
      final response = {
        'errors': {
          'error1': {
            'code': 'ER900',
            'message': 'Custom network error message',
          }
        }
      };
      final exception = BTCDirectException.fromResponse(response);

      expect(exception.code, equals(BTCDirectErrorCode.networkError));
      expect(exception.customMessage, equals('Custom network error message'));
    });
  });

  group('BTCDirectErrorCode', () {
    test('fromCode handles valid and invalid codes', () {
      expect(
        BTCDirectErrorCode.fromCode('ER900'),
        equals(BTCDirectErrorCode.networkError),
      );
      expect(
        BTCDirectErrorCode.fromCode('INVALID_CODE'),
        equals(BTCDirectErrorCode.unknown),
      );
    });

    test('all error codes have unique string codes', () {
      final codes = BTCDirectErrorCode.values.map((e) => e.code).toList();
      final uniqueCodes = codes.toSet();
      expect(codes.length, equals(uniqueCodes.length));
    });
  });
}
