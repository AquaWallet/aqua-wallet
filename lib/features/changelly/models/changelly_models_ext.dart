import 'package:coin_cz/features/swaps/swaps.dart';
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
      rate: Decimal.parse(rate ?? '0'),
      min: Decimal.parse(min ?? '0'),
      max: Decimal.parse(max ?? '0'),
    );
  }
}

extension ChangellyVariableOrderResponseExt on ChangellyVariableOrderResponse {
  SwapOrderStatus get orderStatus => status == null
      ? SwapOrderStatus.unknown
      : switch (status!) {
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

  SwapOrder toSwapOrder() {
    // Validate required fields first
    if (id == null || id!.isEmpty) {
      throw const FormatException('Order ID is required');
    }
    if (amountExpectedFrom == null || amountExpectedTo == null) {
      throw const FormatException('Amount expected values are required');
    }
    if (payinAddress == null || payoutAddress == null) {
      throw const FormatException('Payment addresses are required');
    }
    if (currencyFrom == null || currencyTo == null) {
      throw const FormatException('Currency information is required');
    }

    DateTime getCreatedAtDateTime() {
      if (createdAt == null) {
        throw const FormatException('Created timestamp is required');
      }
      try {
        return DateTime.fromMicrosecondsSinceEpoch(createdAt!);
      } catch (e) {
        throw FormatException('Invalid createdAt timestamp: $e');
      }
    }

    final orderFee =
        Decimal.parse(amountExpectedFrom!) - Decimal.parse(amountExpectedTo!);

    return SwapOrder(
      createdAt: getCreatedAtDateTime(),
      id: id!,
      from: currencyFrom!.toSwapAsset(),
      to: currencyTo!.toSwapAsset(),
      depositAddress: payinAddress!,
      depositExtraId: null,
      settleAddress: payoutAddress!,
      settleExtraId: null,
      depositCoinNetworkFee: null,
      settleCoinNetworkFee:
          networkFee != null ? Decimal.parse(networkFee!) : Decimal.zero,
      serviceFee: SwapFee(
        type: SwapFeeType.flatFee,
        value: orderFee,
        currency: SwapFeeCurrency.usd,
      ),
      depositAmount: Decimal.parse(amountExpectedFrom!),
      settleAmount: Decimal.parse(amountExpectedTo!),
      expiresAt: null, // float orders don't have an expiry
      status: orderStatus,
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
