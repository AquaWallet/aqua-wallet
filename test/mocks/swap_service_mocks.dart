import 'dart:async';

import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockSwapServicesRegistry
    extends Notifier<Map<SwapServiceSource, SwapService>>
    with Mock
    implements SwapServicesRegistryNotifier {
  final SwapService mockService;

  MockSwapServicesRegistry({required this.mockService});

  @override
  Map<SwapServiceSource, SwapService> build() => {
        SwapServiceSource.sideshift: mockService,
        SwapServiceSource.changelly: mockService,
      };
}

class MockSwapOrderCreationNotifier
    extends AutoDisposeFamilyAsyncNotifier<SwapOrderCreationState, SwapArgs>
    with Mock
    implements SwapOrderNotifier {
  final _state = const SwapOrderCreationState();
  late final SwapPair _pair;

  @override
  Future<SwapOrderCreationState> build(SwapArgs arg) async {
    _pair = arg.pair;
    return _state;
  }

  void mockGetRate(SwapRate rate) {
    when(() => getRate(
          amount: any(named: 'amount'),
          type: any(named: 'type'),
        )).thenAnswer((_) async {
      state = AsyncData(_state.copyWith(
        selectedPair: _pair,
        rate: rate,
      ));
    });
  }

  void mockCreateOrder(SwapOrder order) {
    when(() => createReceiveOrder(any())).thenAnswer((_) async {
      state = AsyncData(_state.copyWith(order: order));
    });
    when(() => createSendOrder(any())).thenAnswer((_) async {
      state = AsyncData(_state.copyWith(order: order));
    });
  }
}

// Mock factory methods
SwapQuote createMockSwapQuote({
  required String sentAmount,
  required String receivedAmount,
  required String feeRate,
  required Asset deliverAsset,
}) {
  return SwapQuote(
    id: 'mock_id',
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    depositCoin: deliverAsset.id,
    settleCoin: Asset.liquidTest().id,
    depositNetwork: 'ETH',
    settleNetwork: 'Liquid',
    depositAmount: Decimal.parse(sentAmount),
    settleAmount: Decimal.parse(receivedAmount),
    rate: Decimal.parse(feeRate),
  );
}

SwapOrder createMockSwapOrder({
  required String sentAmount,
  required String receivedAmount,
  required Asset deliverAsset,
}) {
  return SwapOrder(
    createdAt: DateTime.now(),
    id: 'mock_order_id',
    from: SwapAsset.fromAsset(deliverAsset),
    to: SwapAsset.fromAsset(Asset.liquidTest()),
    depositAddress: 'mock_deposit_address',
    settleAddress: 'mock_settle_address',
    depositAmount: Decimal.parse(sentAmount),
    settleAmount: Decimal.parse(receivedAmount),
    serviceFee: SwapFee(
      type: SwapFeeType.percentageFee,
      value: Decimal.parse('0.1'),
      currency: SwapFeeCurrency.usd,
    ),
    status: SwapOrderStatus.waiting,
    serviceType: SwapServiceSource.changelly,
  );
}

SwapOrderCreationState createMockSwapOrderCreationState({
  required String sentAmount,
  required String receivedAmount,
  required String feeRate,
  required Asset deliverAsset,
}) {
  return SwapOrderCreationState(
    quote: createMockSwapQuote(
      sentAmount: sentAmount,
      receivedAmount: receivedAmount,
      feeRate: feeRate,
      deliverAsset: deliverAsset,
    ),
    order: createMockSwapOrder(
      sentAmount: sentAmount,
      receivedAmount: receivedAmount,
      deliverAsset: deliverAsset,
    ),
    rate: SwapRate(
      rate: Decimal.parse(feeRate),
      min: Decimal.parse('0.1'),
      max: Decimal.parse('1000'),
    ),
  );
}

class MockSwapOrderStorageNotifier extends AsyncNotifier<List<SwapOrderDbModel>>
    with Mock
    implements SwapOrderStorageNotifier {
  @override
  FutureOr<List<SwapOrderDbModel>> build() async => [];
}

// Helper to create a mock SwapOrderDbModel
SwapOrderDbModel createMockSwapOrderDbModel({
  String orderId = 'mock_order_id',
  SwapOrderStatus status = SwapOrderStatus.waiting,
  SwapServiceSource serviceType = SwapServiceSource.sideshift,
  String fromAsset = 'BTC',
  String toAsset = 'L-BTC',
}) {
  return SwapOrderDbModel(
      orderId: orderId,
      createdAt: DateTime.now(),
      status: status,
      serviceType: serviceType,
      fromAsset: fromAsset,
      toAsset: toAsset,
      depositAmount: '1.0',
      settleAmount: '0.99',
      depositAddress: 'mock_deposit_address',
      settleAddress: 'mock_settle_address',
      serviceFeeType: SwapFeeType.percentageFee,
      serviceFeeValue: '0.1',
      serviceFeeCurrency: SwapFeeCurrency.usd,
      type: SwapOrderType.fixed);
}
