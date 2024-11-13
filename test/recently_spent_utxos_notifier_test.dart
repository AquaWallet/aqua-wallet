import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/send/providers/send_asset_used_utxo_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRef extends Mock implements Ref {}

void main() {
  late RecentlySpentUtxosNotifier notifier;
  // ignore: unused_local_variable
  late MockRef mockRef;

  setUp(() {
    mockRef = MockRef();
    notifier = RecentlySpentUtxosNotifier();
  });

  group('RecentlySpentUtxosNotifier', () {
    test('initial state is null', () {
      expect(notifier.state, isNull);
    });

    test('updateRecentlySpentUtxos updates state correctly', () {
      final utxos = {
        'asset1': [const GdkUnspentOutputs()],
        'asset2': [const GdkUnspentOutputs(), const GdkUnspentOutputs()],
      };
      notifier.updateRecentlySpentUtxos(utxos);
      expect(notifier.state, equals(utxos));
    });

    test('clearRecentlySpentUtxos sets state to null', () {
      notifier.updateRecentlySpentUtxos({
        'asset1': [const GdkUnspentOutputs()]
      });
      notifier.clearRecentlySpentUtxos();
      expect(notifier.state, isNull);
    });

    test('addUtxos adds new UTXOs to empty state', () {
      final utxos = {
        'asset1': [const GdkUnspentOutputs()],
      };
      notifier.addUtxos(utxos);
      expect(notifier.state, equals(utxos));
    });

    test('addUtxos merges new UTXOs with existing state', () {
      final initialUtxos = {
        'asset1': [const GdkUnspentOutputs()],
      };
      final newUtxos = {
        'asset1': [const GdkUnspentOutputs()],
        'asset2': [const GdkUnspentOutputs()],
      };
      notifier.updateRecentlySpentUtxos(initialUtxos);
      notifier.addUtxos(newUtxos);

      final expectedUtxos = {
        'asset1': [const GdkUnspentOutputs(), const GdkUnspentOutputs()],
        'asset2': [const GdkUnspentOutputs()],
      };
      expect(notifier.state, equals(expectedUtxos));
    });

    test('getRecentlySpentUtxosForAsset returns correct UTXOs', () {
      final utxos = {
        'asset1': [const GdkUnspentOutputs()],
        'asset2': [const GdkUnspentOutputs(), const GdkUnspentOutputs()],
      };
      notifier.updateRecentlySpentUtxos(utxos);

      expect(notifier.getRecentlySpentUtxosForAsset('asset1'),
          equals([const GdkUnspentOutputs()]));
      expect(notifier.getRecentlySpentUtxosForAsset('asset2'),
          equals([const GdkUnspentOutputs(), const GdkUnspentOutputs()]));
      expect(notifier.getRecentlySpentUtxosForAsset('asset3'), isNull);
    });
  });

  group('recentlySpentUtxosProvider', () {
    test('returns RecentlySpentUtxosNotifier', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(recentlySpentUtxosProvider.notifier),
          isA<RecentlySpentUtxosNotifier>());
    });
  });

  group('recentlySpentUtxosForAssetProvider', () {
    test('returns correct UTXOs for given asset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(recentlySpentUtxosProvider.notifier);
      final utxos = {
        'asset1': [const GdkUnspentOutputs()],
        'asset2': [const GdkUnspentOutputs(), const GdkUnspentOutputs()],
      };
      notifier.updateRecentlySpentUtxos(utxos);

      expect(container.read(recentlySpentUtxosForAssetProvider('asset1')),
          equals([const GdkUnspentOutputs()]));
      expect(container.read(recentlySpentUtxosForAssetProvider('asset2')),
          equals([const GdkUnspentOutputs(), const GdkUnspentOutputs()]));
      expect(
          container.read(recentlySpentUtxosForAssetProvider('asset3')), isNull);
    });
  });
}
