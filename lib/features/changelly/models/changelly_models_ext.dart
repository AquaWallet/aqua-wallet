import 'package:aqua/features/swaps/swaps.dart';
import 'package:decimal/decimal.dart';

import 'changelly_models.dart';

extension ChangellyPairExt on ChangellyPair {
  SwapPair toSwapPair() {
    return SwapPair(
      from: SwapAsset(
        id: from,
        name: from,
        ticker: from,
      ),
      to: SwapAsset(
        id: to,
        name: to,
        ticker: to,
      ),
    );
  }
}

extension ChangellyQuoteResponseExt on ChangellyQuoteResponse {
  SwapRate toSwapRate() {
    return SwapRate(
      rate: Decimal.parse(rate),
      min: Decimal.parse(min),
      max: Decimal.parse(max),
    );
  }
}

SwapOrderStatus changellyToSwapOrderStatus(ChangellyOrderStatus status) =>
    switch (status) {
      ChangellyOrderStatus.unknown => SwapOrderStatus.unknown,
      ChangellyOrderStatus.new_ => SwapOrderStatus.waiting,
      ChangellyOrderStatus.waiting => SwapOrderStatus.waiting,
      ChangellyOrderStatus.confirming => SwapOrderStatus.processing,
      ChangellyOrderStatus.exchanging => SwapOrderStatus.processing,
      ChangellyOrderStatus.sending => SwapOrderStatus.sending,
      ChangellyOrderStatus.finished => SwapOrderStatus.completed,
      ChangellyOrderStatus.failed => SwapOrderStatus.failed,
      ChangellyOrderStatus.refunded => SwapOrderStatus.refunded,
      ChangellyOrderStatus.hold => SwapOrderStatus.processing,
      ChangellyOrderStatus.overdue => SwapOrderStatus.processing,
      ChangellyOrderStatus.expired => SwapOrderStatus.expired,
    };

DateTime getDateTimeFromMSSinceEpoch(int msSinceEpoch) {
  try {
    return DateTime.fromMicrosecondsSinceEpoch(msSinceEpoch);
  } catch (e) {
    throw FormatException('input: $msSinceEpoch; error: $e');
  }
}

extension ChangellyFixedOrderResponseExt on ChangellyFixedOrderResponse {
  SwapOrder toSwapOrder() {
    final orderFee =
        Decimal.parse(amountExpectedFrom) - Decimal.parse(amountExpectedTo);

    return SwapOrder(
      createdAt: getDateTimeFromMSSinceEpoch(createdAt),
      id: id,
      from: currencyFrom.toSwapAsset(),
      to: currencyTo.toSwapAsset(),
      depositAddress: payinAddress,
      depositExtraId: null,
      settleAddress: payoutAddress,
      settleExtraId: null,
      depositCoinNetworkFee: null,
      settleCoinNetworkFee: Decimal.parse(networkFee),
      serviceFee: SwapFee(
        type: SwapFeeType.flatFee,
        value: orderFee,
        currency: SwapFeeCurrency.usd,
      ),
      depositAmount: Decimal.parse(amountExpectedFrom),
      settleAmount: Decimal.parse(amountExpectedTo),
      expiresAt: payTill,
      status: changellyToSwapOrderStatus(status),
      serviceType: SwapServiceSource.changelly,
    );
  }
}

extension ChangellyVariableOrderResponseExt on ChangellyVariableOrderResponse {
  SwapOrder toSwapOrder() {
    final orderFee =
        Decimal.parse(amountExpectedFrom) - Decimal.parse(amountExpectedTo);

    return SwapOrder(
      createdAt: getDateTimeFromMSSinceEpoch(createdAt),
      id: id,
      from: currencyFrom.toSwapAsset(),
      to: currencyTo.toSwapAsset(),
      depositAddress: payinAddress,
      depositExtraId: null,
      settleAddress: payoutAddress,
      settleExtraId: null,
      depositCoinNetworkFee: null,
      settleCoinNetworkFee: Decimal.parse(networkFee),
      serviceFee: SwapFee(
        type: SwapFeeType.flatFee,
        value: orderFee,
        currency: SwapFeeCurrency.usd,
      ),
      depositAmount: Decimal.parse(amountExpectedFrom),
      settleAmount: Decimal.parse(amountExpectedTo),
      expiresAt: null, // float orders don't have an expiry
      status: changellyToSwapOrderStatus(status),
      serviceType: SwapServiceSource.changelly,
    );
  }
}

extension ChangellyAssetExt on String? {
  SwapAsset toSwapAsset() {
    if (this == null || this!.isEmpty) {
      return SwapAsset.nullAsset;
    }
    final changellyAsset = ChangellyAsset(id: this!);
    final swapAsset = changellyAsset.toSwapAsset();
    return SwapAsset(
      id: swapAsset.id,
      name: swapAsset.name,
      ticker: swapAsset.ticker,
    );
  }
}
