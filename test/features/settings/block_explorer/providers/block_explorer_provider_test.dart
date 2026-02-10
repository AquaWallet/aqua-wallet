import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../mocks/mocks.dart';

void main() {
  late ProviderContainer container;
  late MockUserPreferencesNotifier mockPrefs;
  const kExtExplorers = BlockExplorer.availableBlockExplorers;
  final kExpBlockstream = kExtExplorers.first;
  final kExpMempool = kExtExplorers.last;

  setUp(() {
    mockPrefs = MockUserPreferencesNotifier();
    container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWith((ref) => mockPrefs),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BlockExplorerProvider', () {
    test('should return the first explorer when no explorer is set', () async {
      when(() => mockPrefs.blockExplorer).thenReturn(null);

      final provider = container.read(blockExplorerProvider);
      final result = provider.currentBlockExplorer;

      expect(
        result,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpBlockstream.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpBlockstream.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpBlockstream.liquidUrl),
      );
    });

    test('should return saved block explorer when one is set', () async {
      when(() => mockPrefs.blockExplorer).thenReturn(kExpBlockstream.name);

      final provider = container.read(blockExplorerProvider);
      final result = provider.currentBlockExplorer;

      expect(
        result,
        isA<BlockExplorer>()
            .having((e) => e.name, 'name', kExpBlockstream.name)
            .having((e) => e.btcUrl, 'btcUrl', kExpBlockstream.btcUrl)
            .having((e) => e.liquidUrl, 'liquidUrl', kExpBlockstream.liquidUrl),
      );
    });

    test('should update block explorer when changed', () async {
      when(() => mockPrefs.blockExplorer).thenReturn(kExpBlockstream.name);
      when(() => mockPrefs.setBlockExplorer(any())).thenAnswer((_) async {});

      final provider = container.read(blockExplorerProvider);
      final initialExplorer = provider.currentBlockExplorer;

      await provider.setBlockExplorer(kExpMempool);

      // Update the mock to return the new value after setBlockExplorer
      when(() => mockPrefs.blockExplorer).thenReturn(kExpMempool.name);

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
