import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../mocks/mocks.dart';

void main() async {
  SharedPreferences.setMockInitialValues({
    PrefKeys.blockExplorer: 'blockstream.info',
  });
  final sp = await SharedPreferences.getInstance();
  const kExtExplorers = BlockExplorer.availableBlockExplorers;
  final kExpBlockstream = kExtExplorers.first;
  final kExpMempool = kExtExplorers.last;
  final mockAquaConnectionProvider = MockAquaConnectionProvider();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
    ],
  );

  group('External Block Explorers', () {
    test('should return the first explorer when no explorer is set', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.blockExplorer: '',
      });
      final sp = await SharedPreferences.getInstance();
      final mockAquaConnectionProvider = MockAquaConnectionProvider();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          aquaConnectionProvider.overrideWith(() => mockAquaConnectionProvider),
        ],
      );
      final provider = container.read(blockExplorerProvider);

      expect(provider.prefs.blockExplorer, '');
      expect(
        provider.currentBlockExplorer,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpBlockstream.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpBlockstream.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpBlockstream.liquidUrl),
      );
    });
    test('should have blockstream as default', () {
      final provider = container.read(blockExplorerProvider);

      expect(provider.prefs.blockExplorer, kExpBlockstream.name);
      expect(
        provider.currentBlockExplorer,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpBlockstream.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpBlockstream.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpBlockstream.liquidUrl),
      );
    });
    test('should have correct value on explorer change', () async {
      final provider = container.read(blockExplorerProvider);
      final initialExplorer = provider.currentBlockExplorer;

      await provider.setBlockExplorer(kExpMempool);

      expect(
        initialExplorer,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpBlockstream.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpBlockstream.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpBlockstream.liquidUrl),
      );
      expect(
        provider.currentBlockExplorer,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpMempool.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpMempool.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpMempool.liquidUrl),
      );
    });
  });
}
