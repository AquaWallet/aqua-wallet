import 'package:aqua/data/provider/lwk_provider.dart';

class MockLwkNetworkFrontend extends LwkNetworkFrontend {
  MockLwkNetworkFrontend({required super.ref});

  @override
  Future<bool> verifyInitialized() async => true;
}
