import 'package:aqua/features/lightning/lnurl_parser/dart_lnurl_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Valid bech32 LNURL from the LUD-01 spec example
// Decodes to: https://service.com/api?q=3fc3645b439ce8e7f2553a69e5267081d96dcd340693afabe04be7b0ccd178df
const _validLnurl =
    'lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekvcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxfq5fns';

void main() {
  group('decodeLnurlUri', () {
    group('LUD-01 fallback scheme (lightning= query parameter)', () {
      test('extracts LNURL from https URL with lightning= param', () {
        const input =
            'https://service.com/giftcard/redeem?id=123&lightning=$_validLnurl';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
        expect(result.path, equals('/api'));
      });

      test('extracts LNURL from https URL with only lightning= param', () {
        const input = 'https://app.example.com/pay?lightning=$_validLnurl';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });

      test('ignores empty lightning= param and falls through', () {
        const input = 'https://service.com/page?lightning=';
        expect(
          () => decodeLnurlUri(input),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('non-http scheme still decodes via bech32 regex fallback', () {
        const input = 'ftp://service.com/page?lightning=$_validLnurl';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });
    });

    group('bech32 LNURL decoding', () {
      test('decodes valid bech32 LNURL to https URL', () {
        final result = decodeLnurlUri(_validLnurl);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });

      test('decodes uppercase bech32 LNURL', () {
        final result = decodeLnurlUri(_validLnurl.toUpperCase());
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });

      test('extracts lnurl from lightning: prefix', () {
        const input = 'lightning:$_validLnurl';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });

      test('rejects malformed bech32 (missing separator digit)', () {
        const input = 'lnurldp68gurn8ghj7cm0wfjjucn5vdkkzupwd';
        expect(
          () => decodeLnurlUri(input),
          throwsA(anything),
        );
      });
    });

    group('LUD-17 protocol schemes', () {
      test('decodes lnurlp:// to https', () {
        const input = 'lnurlp://service.com/pay';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
        expect(result.path, equals('/pay'));
      });

      test('decodes lnurlw:// to https', () {
        const input = 'lnurlw://service.com/withdraw';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('https'));
        expect(result.host, equals('service.com'));
      });

      test('decodes lnurlp:// onion to http', () {
        const input = 'lnurlp://examplennnnnnnn.onion/pay';
        final result = decodeLnurlUri(input);
        expect(result.scheme, equals('http'));
        expect(result.host, equals('examplennnnnnnn.onion'));
      });
    });
  });
}
