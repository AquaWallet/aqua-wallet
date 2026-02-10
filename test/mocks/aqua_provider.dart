import 'package:aqua/data/data.dart';
import 'package:mocktail/mocktail.dart';

class MockAquaProvider extends Mock implements AquaProvider {}

extension MockAquaProviderX on MockAquaProvider {
  void mockClearSecureStorageOnReinstall() {
    when(() => clearSecureStorageOnReinstall())
        .thenAnswer((_) => Future.value());
  }
}
