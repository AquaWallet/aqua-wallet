import 'dart:async';

import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockFiatRatesNotifier
    extends AsyncNotifier<List<BitcoinFiatRatesResponse>>
    with Mock
    implements FiatRatesNotifier {
  MockFiatRatesNotifier({required this.rates});

  final List<BitcoinFiatRatesResponse> rates;

  @override
  FutureOr<List<BitcoinFiatRatesResponse>> build() => rates;
}
