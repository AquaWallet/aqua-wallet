import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockStorageNotifier = MockSwapOrderStorageNotifier();

  final container = ProviderContainer(
    overrides: [
      swapStorageProvider.overrideWith(() => mockStorageNotifier),
    ],
  );

  group('SwapOrderStorageNotifier', () {
    test('builds empty list by default', () async {
      final orders = await container.read(swapStorageProvider.future);
      expect(orders, isEmpty);
    });

    test('saves new order', () async {
      final order = createMockSwapOrderDbModel();

      when(() => mockStorageNotifier.save(order))
          .thenAnswer((_) async => Future.value());

      await container.read(swapStorageProvider.notifier).save(order);

      verify(() => mockStorageNotifier.save(order)).called(1);
    });

    test('getAllPendingSettlementSwaps returns filtered list', () async {
      final pendingOrder = createMockSwapOrderDbModel(
        status: SwapOrderStatus.waiting,
      );

      when(() => mockStorageNotifier.getAllPendingSettlementSwaps())
          .thenAnswer((_) async => [pendingOrder]);

      final result = await container
          .read(swapStorageProvider.notifier)
          .getAllPendingSettlementSwaps();

      expect(result.length, 1);
      expect(result.first.status, SwapOrderStatus.waiting);
    });

    test('getPendingSettlementSwapsForService filters by service', () async {
      final sideshiftOrder = createMockSwapOrderDbModel(
        serviceType: SwapServiceSource.sideshift,
        status: SwapOrderStatus.waiting,
      );

      when(() => mockStorageNotifier.getPendingSettlementSwapsForService(
            SwapServiceSource.sideshift,
          )).thenAnswer((_) async => [sideshiftOrder]);

      final result = await container
          .read(swapStorageProvider.notifier)
          .getPendingSettlementSwapsForService(SwapServiceSource.sideshift);

      expect(result.length, 1);
      expect(result.first.serviceType, SwapServiceSource.sideshift);
    });

    test('getPendingSettlementSwapsForAssets filters by assets', () async {
      final btcOrder = createMockSwapOrderDbModel(
        fromAsset: 'BTC',
        toAsset: 'L-BTC',
        status: SwapOrderStatus.waiting,
      );

      when(() => mockStorageNotifier.getPendingSettlementSwapsForAssets(
            depositAsset: any(named: 'depositAsset'),
            settleAsset: any(named: 'settleAsset'),
          )).thenAnswer((_) async => [btcOrder]);

      final result = await container
          .read(swapStorageProvider.notifier)
          .getPendingSettlementSwapsForAssets(
            depositAsset: Asset.btc(),
          );

      expect(result.length, 1);
      expect(result.first.fromAsset, 'BTC');
    });

    test('updateOrder updates existing order', () async {
      final order = createMockSwapOrderDbModel();

      when(() => mockStorageNotifier.updateOrder(
            orderId: order.orderId,
            status: SwapOrderStatus.completed,
          )).thenAnswer((_) async => {});

      await container.read(swapStorageProvider.notifier).updateOrder(
            orderId: order.orderId,
            status: SwapOrderStatus.completed,
          );

      verify(() => mockStorageNotifier.updateOrder(
            orderId: order.orderId,
            status: SwapOrderStatus.completed,
          )).called(1);
    });
  });
}
