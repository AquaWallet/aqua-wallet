import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:mocktail/mocktail.dart';

class MockSideswapTaxiProvider extends AutoDisposeAsyncNotifier<TaxiState>
    with Mock
    implements TaxiNotifier {
  MockSideswapTaxiProvider({this.throwError = false});

  final bool throwError;

  @override
  FutureOr<TaxiState> build() =>
      throwError ? throw Exception('Taxi error') : const TaxiState.empty();
}

extension MockSideswapTaxiProviderX on MockSideswapTaxiProvider {
  void mockEstimatedTaxiFeeUsdt(int fee) {
    when(() => estimatedTaxiFeeUsdt(any(), any())).thenAnswer(
      (_) => Future.value(fee),
    );
  }
}
