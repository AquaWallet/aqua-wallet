import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../mocks/mocks.dart';

void main() async {
  SharedPreferences.setMockInitialValues({
    PrefKeys.customElectrumServerBtcUrl: '',
    PrefKeys.customElectrumServerLiquidUrl: '',
  });
  final sp = await SharedPreferences.getInstance();
  final mockAquaConnectionProvider = MockAquaConnectionProvider();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
    ],
  );

  group('Electrum Server', () {
    const kCustomBtcUrl = 'https://custom-btc.com';
    const kCustomLiquidUrl = 'https://custom-liquid.com';
    const kCustomBtcUrl2 = 'https://custom-btc-2.com';
    const kCustomLiquidUrl2 = 'https://custom-liquid-2.com';

    test('should return the empty URLs when no server is set', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.customElectrumServerBtcUrl: '',
        PrefKeys.customElectrumServerLiquidUrl: '',
      });
      final sp = await SharedPreferences.getInstance();
      final mockAquaConnectionProvider = MockAquaConnectionProvider();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
        ],
      );
      final provider = container.read(electrumServerProvider);

      expect(provider.prefs.customElectrumServerBtcUrl, '');
      expect(provider.prefs.customElectrumServerLiquidUrl, '');
    });
    test('should have blockstream as default', () {
      final provider = container.read(electrumServerProvider);

      expect(provider.prefs.customElectrumServerBtcUrl, '');
      expect(provider.prefs.customElectrumServerLiquidUrl, '');
    });
    test('should have correct value on server change', () async {
      final provider = container.read(electrumServerProvider);

      final initialBtcUrl = provider.customElectrumServerBtcUrl;
      final initialLiquidUrl = provider.customElectrumServerLiquidUrl;

      await provider.setElectrumServer(const ElectrumConfig(
        btcUrl: kCustomBtcUrl,
        liquidUrl: kCustomLiquidUrl,
      ));

      expect(initialBtcUrl, '');
      expect(initialLiquidUrl, '');
      expect(provider.customElectrumServerBtcUrl, kCustomBtcUrl);
      expect(provider.customElectrumServerLiquidUrl, kCustomLiquidUrl);
    });
    test('should preserve custom url on value changes change', () async {
      final provider = container.read(electrumServerProvider);
      final initialBtcUrl = provider.customElectrumServerBtcUrl;
      final initialLiquidUrl = provider.customElectrumServerLiquidUrl;

      await provider.setElectrumServer(const ElectrumConfig(
        btcUrl: kCustomBtcUrl2,
        liquidUrl: kCustomLiquidUrl2,
      ));

      expect(initialBtcUrl, kCustomBtcUrl);
      expect(initialLiquidUrl, kCustomLiquidUrl);
      expect(provider.customElectrumServerBtcUrl, kCustomBtcUrl2);
      expect(provider.customElectrumServerLiquidUrl, kCustomLiquidUrl2);
    });
    test('should remove custom urls on switching to defualt server', () async {
      final provider = container.read(electrumServerProvider);
      final initialBtcUrl = provider.customElectrumServerBtcUrl;
      final initialLiquidUrl = provider.customElectrumServerLiquidUrl;

      await provider.setDefaultElectrumServerUrls();

      expect(initialBtcUrl, kCustomBtcUrl2);
      expect(initialLiquidUrl, kCustomLiquidUrl2);
      expect(provider.customElectrumServerBtcUrl, '');
      expect(provider.customElectrumServerLiquidUrl, '');
    });
  });
}
