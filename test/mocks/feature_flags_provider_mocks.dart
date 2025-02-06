import 'package:aqua/features/settings/settings.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureFlagsProvider extends Mock implements FeatureFlagsNotifier {}

extension MockFeatureFlagsProviderX on MockFeatureFlagsProvider {
  void mockFakeBroadcastsEnabled(bool value) {
    when(() => fakeBroadcastsEnabled).thenReturn(value);
  }
}
