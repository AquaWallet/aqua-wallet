import 'dart:math';

import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/address_list/address_list_provider.dart';
import 'package:aqua/features/address_list/address_lists.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/wallet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLiquidProvider extends Mock implements LiquidProvider {
  @override
  WalletService get session => MockLiquidWalletService();
}

class MockLiquidWalletService extends Mock implements WalletService {
  @override
  int getSubAccount() => 0;
}

class MockBitcoinProvider extends Mock implements BitcoinProvider {
  @override
  WalletService get session => MockBitcoinWalletService();
}

class MockBitcoinWalletService extends Mock implements WalletService {
  @override
  int getSubAccount() => 0;
}

List<GdkPreviousAddress> generateMixedAddresses(String prefix, int count) {
  final random = Random(42);
  return List.generate(count, (i) {
    final txCount = random.nextInt(10);
    return GdkPreviousAddress(
      address: '$prefix${i + 1}',
      txCount: txCount,
      isInternal: random.nextBool(),
      pointer: i,
      addressType: 'p2wpkh',
    );
  });
}

void main() {
  setUpAll(() {
    registerFallbackValue(const GdkPreviousAddressesDetails());
  });

  late MockLiquidProvider mockLiquidProvider;
  late MockBitcoinProvider mockBitcoinProvider;

  setUp(() {
    mockLiquidProvider = MockLiquidProvider();
    mockBitcoinProvider = MockBitcoinProvider();

    when(() => mockLiquidProvider.getPreviousAddresses(
            details: any(named: 'details')))
        .thenAnswer((_) async => (generateMixedAddresses('liquid', 10), 1));

    when(() => mockBitcoinProvider.getPreviousAddresses(
            details: any(named: 'details')))
        .thenAnswer((_) async => (generateMixedAddresses('bitcoin', 10), 1));
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        liquidProvider.overrideWithValue(mockLiquidProvider),
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
      ],
    );
  }

  group('AddressListNotifier', () {
    // test(
    //     'build returns AddressLists with minimum 10 used addresses for Bitcoin network',
    //     () async {
    //   final container = createContainer();
    //   final addressLists =
    //       await container.read(addressListProvider(NetworkType.bitcoin).future);

    //   expect(addressLists, isA<AddressLists>());
    //   expect(addressLists.usedAddresses.length, greaterThanOrEqualTo(10));
    //   expect(
    //       addressLists.usedAddresses.every((addr) => addr.txCount! > 0), true);
    //   expect(addressLists.unusedAddresses.every((addr) => addr.txCount == 0),
    //       true);
    //   expect(addressLists.usedAddresses.first.address, startsWith('bitcoin'));
    //   expect(addressLists.unusedAddresses.first.address, startsWith('bitcoin'));
    // });

    test(
        'build returns AddressLists with minimum 10 used addresses for Liquid network',
        () async {
      final container = createContainer();
      final addressLists =
          await container.read(addressListProvider(NetworkType.liquid).future);

      expect(addressLists, isA<AddressLists>());
      expect(addressLists.usedAddresses.length, greaterThanOrEqualTo(10));
      expect(
          addressLists.usedAddresses.every((addr) => addr.txCount! > 0), true);
      expect(addressLists.unusedAddresses.every((addr) => addr.txCount == 0),
          true);
      expect(addressLists.usedAddresses.first.address, startsWith('liquid'));
      expect(addressLists.unusedAddresses.first.address, startsWith('liquid'));
    });

    test('refreshAddresses updates state', () async {
      final container = createContainer();
      await container.read(addressListProvider(NetworkType.bitcoin).future);

      when(() => mockBitcoinProvider.getPreviousAddresses(
              details: any(named: 'details')))
          .thenAnswer(
              (_) async => (generateMixedAddresses('bitcoin_new', 20), 2));

      await container
          .read(addressListProvider(NetworkType.bitcoin).notifier)
          .refreshAddresses();

      final result =
          container.read(addressListProvider(NetworkType.bitcoin)).value;
      expect(result?.usedAddresses.length, greaterThanOrEqualTo(10));
      expect(
          result?.usedAddresses
              .every((addr) => addr.address!.startsWith('bitcoin_new')),
          true);
      expect(
          result?.unusedAddresses
              .every((addr) => addr.address!.startsWith('bitcoin_new')),
          true);
    });

    test('loadMoreAddresses appends new addresses', () async {
      final container = createContainer();
      await container.read(addressListProvider(NetworkType.bitcoin).future);

      final initialState =
          container.read(addressListProvider(NetworkType.bitcoin)).value;
      final initialUsedCount = initialState!.usedAddresses.length;
      final initialUnusedCount = initialState.unusedAddresses.length;

      when(() => mockBitcoinProvider.getPreviousAddresses(
              details: any(named: 'details')))
          .thenAnswer(
              (_) async => (generateMixedAddresses('bitcoin_more', 10), 2));

      await container
          .read(addressListProvider(NetworkType.bitcoin).notifier)
          .loadMoreAddresses();

      final result =
          container.read(addressListProvider(NetworkType.bitcoin)).value;
      expect(result?.usedAddresses.length, greaterThan(initialUsedCount));
      expect(result?.unusedAddresses.length, greaterThan(initialUnusedCount));
      expect(result?.usedAddresses.last.address, startsWith('bitcoin_more'));
      expect(result?.unusedAddresses.last.address, startsWith('bitcoin_more'));
    });

    test('search filters addresses correctly', () async {
      final container = createContainer();
      when(() => mockBitcoinProvider
              .getPreviousAddresses(details: any(named: 'details')))
          .thenAnswer((_) async => (
                [
                  const GdkPreviousAddress(address: 'bitcoin1', txCount: 1),
                  const GdkPreviousAddress(address: 'bitcoin2', txCount: 0),
                  const GdkPreviousAddress(address: 'other1', txCount: 1),
                  const GdkPreviousAddress(address: 'other2', txCount: 0),
                ],
                null
              ));

      await container.read(addressListProvider(NetworkType.bitcoin).future);

      final notifier =
          container.read(addressListProvider(NetworkType.bitcoin).notifier);
      notifier.search('bitcoin');

      final usedResult = notifier.getFilteredAddresses(true);
      final unusedResult = notifier.getFilteredAddresses(false);

      expect(usedResult.length, 1);
      expect(usedResult.first.address, 'bitcoin1');
      expect(unusedResult.length, 1);
      expect(unusedResult.first.address, 'bitcoin2');
    });
  });
}
