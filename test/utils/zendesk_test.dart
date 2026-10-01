import 'package:aqua/config/constants/constants.dart';
import 'package:aqua/utils/zendesk.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Uri buildUri({
    String subject = 'Lightning Swap Support',
    String swapId = 'swap-1',
    String aquaVersion = '1.2.3',
    String providerUrl = 'https://api.example.com/v2',
  }) =>
      Uri.parse(
          getAquaBoltzZendeskUrl(subject, swapId, aquaVersion, providerUrl));

  group('getAquaBoltzZendeskUrl', () {
    test('round-trips the localized ticket subject', () async {
      final loc = await AppLocalizations.delegate.load(const Locale('en'));
      final subject = loc.boltzSwapSupportZendeskSubjectCriticalDoNotChange;

      // Sourcing the subject from the arb is what makes this a guard on the
      // ticket subject itself; hardcoding it would only test Uri encoding.
      expect(subject, 'Lightning Swap Support');
      // Zendesk decodes the parameter, so assert on the decoded value rather
      // than on whether Dart emitted '+' or '%20' for the spaces.
      expect(buildUri(subject: subject).queryParameters['tf_subject'], subject);
    });

    test('carries the swap id, provider url and app version as form fields',
        () {
      final uri = buildUri();

      expect(uri.queryParameters['tf_$zendeskFormFieldBoltzSwapId'], 'swap-1');
      expect(
        uri.queryParameters['tf_$zendeskFormFieldBoltzUrl'],
        'https://api.example.com/v2',
      );
      expect(uri.queryParameters['tf_$zendeskFormFieldAquaVersion'], '1.2.3');
    });

    test('omits empty fields rather than sending blank ones', () {
      final uri = buildUri(swapId: '', providerUrl: '');

      expect(uri.queryParameters.containsKey('tf_$zendeskFormFieldBoltzSwapId'),
          isFalse);
      expect(uri.queryParameters.containsKey('tf_$zendeskFormFieldBoltzUrl'),
          isFalse);
      expect(uri.queryParameters['tf_subject'], 'Lightning Swap Support');
    });
  });
}
