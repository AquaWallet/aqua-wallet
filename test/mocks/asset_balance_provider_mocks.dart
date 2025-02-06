import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockBalanceProvider extends Mock implements BalanceService {}

extension MockBalanceProviderX on MockBalanceProvider {
  void mockGetBalanceCall({
    required int value,
    Asset? asset,
  }) {
    when(() => getBalance(asset ?? any()))
        .thenAnswer((_) => Future.value(value));
  }
}
