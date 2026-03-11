import 'package:aqua/data/data.dart';
import 'package:aqua/data/services/mempool_api_service.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../mocks/bitcoin_provider_mocks.dart';
import '../../../mocks/liquid_provider_mocks.dart';
import '../../../mocks/mempool_api_service_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ConnectionStatusNotifier.checkConnectionStatus', () {
    late ProviderContainer container;
    late MockMempoolApiService mockMempoolBitcoinService;
    late MockBitcoinProvider mockBitcoinProvider;
    late MockLiquidProvider mockLiquidProvider;
    late MockMempoolApiService mockMempoolLiquidService;
    late BehaviorSubject<int> btcSubject;
    late BehaviorSubject<int> lqdSubject;
    const liquidNetworkBlockHeight = 3;

    setUp(() {
      mockMempoolBitcoinService = MockMempoolApiService();
      mockMempoolLiquidService = MockMempoolApiService();
      mockBitcoinProvider = MockBitcoinProvider();
      mockLiquidProvider = MockLiquidProvider();

      btcSubject = BehaviorSubject<int>();
      lqdSubject = BehaviorSubject<int>();
      when(() => mockBitcoinProvider.blockHeightEventSubject)
          .thenAnswer((_) => btcSubject);
      when(() => mockLiquidProvider.blockHeightEventSubject)
          .thenAnswer((_) => lqdSubject);

      container = ProviderContainer(
        overrides: [
          mempoolBitcoinApiServiceProvider
              .overrideWith((_) => mockMempoolBitcoinService),
          bitcoinProvider.overrideWithValue(mockBitcoinProvider),
          liquidProvider.overrideWithValue(mockLiquidProvider),
          mempoolLiquidApiServiceProvider
              .overrideWith((_) => mockMempoolLiquidService),
        ],
      );
    });

    tearDown(() {
      btcSubject.close();
      lqdSubject.close();
      container.dispose();
    });

    group('checkConnectionStatus function tests', () {
      test('sets connected to true when GDK height >= Mempool height',
          () async {
        const mempoolHeight = 800000;
        mockMempoolBitcoinService
            .mockGetLatestBlockHeightSuccess(mempoolHeight);
        mockMempoolLiquidService
            .mockGetLatestBlockHeightSuccess(liquidNetworkBlockHeight);

        // Act - Use the provider but override the state after it's built
        final notifier = container.read(syncStatusProvider.notifier);

        await container.read(syncStatusProvider.future);

        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: false,
            lastBitcoinBlock: mempoolHeight,
            lastLiquidBlock: liquidNetworkBlockHeight,
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert
        expect(notifier.state.value?.isDeviceConnected, isTrue);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verify(() => mockMempoolLiquidService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
      });

      test('sets connected to false when GDK height < Mempool height',
          () async {
        // Arrange
        const gdkHeight = 799999;
        const mempoolHeight = 800000;
        mockMempoolBitcoinService
            .mockGetLatestBlockHeightSuccess(mempoolHeight);
        mockMempoolLiquidService
            .mockGetLatestBlockHeightSuccess(liquidNetworkBlockHeight);

        // Act
        final notifier = container.read(syncStatusProvider.notifier);

        // Wait for initial build to complete
        await container.read(syncStatusProvider.future);

        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: true,
            lastBitcoinBlock: gdkHeight,
            lastLiquidBlock:
                liquidNetworkBlockHeight, // Match the mocked blockstream height
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert
        expect(notifier.state.value?.isDeviceConnected, isFalse);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verify(() => mockMempoolLiquidService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
      });

      test('skips comparison when Mempool API fails', () async {
        // Arrange
        const gdkHeight = 800000;
        mockMempoolBitcoinService.mockGetLatestBlockHeightFailure();
        mockMempoolLiquidService.mockGetLatestBlockHeightFailure();

        // Act
        final notifier = container.read(syncStatusProvider.notifier);

        // Wait for initial build to complete
        await container.read(syncStatusProvider.future);

        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: true,
            lastBitcoinBlock: gdkHeight,
            lastLiquidBlock:
                liquidNetworkBlockHeight, // Match the mocked blockstream height
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert - should remain unchanged
        expect(notifier.state.value?.isDeviceConnected, isTrue);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verify(() => mockMempoolLiquidService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
      });

      test('sets connected to false when GDK height is null', () async {
        // Arrange
        const mempoolHeight = 800000;
        mockMempoolBitcoinService
            .mockGetLatestBlockHeightSuccess(mempoolHeight);
        mockMempoolLiquidService
            .mockGetLatestBlockHeightSuccess(liquidNetworkBlockHeight);

        // Act
        final notifier = container.read(syncStatusProvider.notifier);

        // Wait for initial build to complete
        await container.read(syncStatusProvider.future);

        // Set state without GDK height
        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: true,
            lastBitcoinBlock: null,
            lastLiquidBlock: null,
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert - should be set to false when GDK height is null
        expect(notifier.state.value?.isDeviceConnected, isFalse);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verify(() => mockMempoolLiquidService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
      });

      test('handles exception gracefully', () async {
        // Arrange
        const gdkHeight = 800000;
        mockMempoolBitcoinService.mockGetLatestBlockHeightException();

        // Act
        final notifier = container.read(syncStatusProvider.notifier);

        // Wait for initial build to complete
        await container.read(syncStatusProvider.future);

        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: true,
            lastBitcoinBlock: gdkHeight,
            lastLiquidBlock:
                liquidNetworkBlockHeight, // Match the mocked blockstream height
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert - should remain unchanged
        expect(notifier.state.value?.isDeviceConnected, isFalse);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verifyNever(() => mockMempoolLiquidService.getLatestBlockHeight());
      });

      test('sets connected to false when liquid height is wrong', () async {
        // Arrange
        const gdkHeight = 800000;
        const mempoolHeight = 800000;
        mockMempoolBitcoinService
            .mockGetLatestBlockHeightSuccess(mempoolHeight);
        mockMempoolLiquidService
            .mockGetLatestBlockHeightSuccess(liquidNetworkBlockHeight);

        // Act
        final notifier = container.read(syncStatusProvider.notifier);

        // Wait for initial build to complete
        await container.read(syncStatusProvider.future);

        notifier.state = const AsyncValue.data(
          SyncStatus(
            isDeviceConnected: true,
            lastBitcoinBlock: gdkHeight,
            lastLiquidBlock: liquidNetworkBlockHeight -
                1, // Lower than the mocked blockstream height
            initialized: true,
          ),
        );

        await notifier.checkSync();

        // Assert - should be set to false when liquid height comparison fails
        expect(notifier.state.value?.isDeviceConnected, isFalse);
        verify(() => mockMempoolBitcoinService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
        verify(() => mockMempoolLiquidService.getLatestBlockHeight())
            .called(2); // 1 for initial, 1 for manual checkSync
      });
    });
  });
}
