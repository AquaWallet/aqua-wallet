import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:aqua/features/swaps/swaps.dart';

part 'changelly_models.freezed.dart';
part 'changelly_models.g.dart';

enum ChangellyOrderStatus {
  unknown,
  @JsonValue('new')
  new_,
  waiting,
  confirming,
  exchanging,
  sending,
  finished,
  failed,
  refunded,
  hold,
  overdue,
  expired,
}

enum ChangellyOrderType {
  float,
  fixed,
}

@freezed
class ChangellyPair with _$ChangellyPair {
  const factory ChangellyPair({
    required String from,
    required String to,
  }) = _ChangellyPair;

  factory ChangellyPair.fromJson(Map<String, dynamic> json) =>
      _$ChangellyPairFromJson(json);
}

@freezed
class ChangellyVariableOrderResponse with _$ChangellyVariableOrderResponse {
  const factory ChangellyVariableOrderResponse({
    required String id,
    required String trackUrl,
    required int createdAt,
    required ChangellyOrderType type,
    required ChangellyOrderStatus status,
    required String currencyFrom,
    required String currencyTo,
    required String payinAddress,
    required String amountExpectedFrom,
    required String payoutAddress,
    String? refundAddress,
    required String amountExpectedTo,
    required String networkFee,
  }) = _ChangellyVariableOrderResponse;

  factory ChangellyVariableOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyVariableOrderResponseFromJson(json);
}

@freezed
class ChangellyFixedOrderResponse with _$ChangellyFixedOrderResponse {
  const factory ChangellyFixedOrderResponse({
    required String id,
    required String trackUrl,
    required int createdAt,
    required ChangellyOrderType type,
    required ChangellyOrderStatus status,
    required String currencyFrom,
    required String currencyTo,
    required String payinAddress,
    required String amountExpectedFrom,
    required String payoutAddress,
    String? refundAddress,
    required String amountExpectedTo,
    required String networkFee,
    required DateTime payTill,
  }) = _ChangellyFixedOrderResponse;

  factory ChangellyFixedOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyFixedOrderResponseFromJson(json);
}

@freezed
class ChangellyQuoteResponse with _$ChangellyQuoteResponse {
  const factory ChangellyQuoteResponse({
    required String from,
    required String to,
    required String networkFee,
    required String amountFrom,
    required String amountTo,
    required String max,
    required String maxFrom,
    required String maxTo,
    required String min,
    required String minFrom,
    required String minTo,
    required String visibleAmount,
    required String rate,
    required String fee,
  }) = _ChangellyQuoteResponse;

  factory ChangellyQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyQuoteResponseFromJson(json);
}

@freezed
class ChangellyQuotePayload with _$ChangellyQuotePayload {
  const factory ChangellyQuotePayload({
    required String from,
    required String to,
    required String amountFrom,
  }) = _ChangellyQuotePayload;

  factory ChangellyQuotePayload.fromJson(Map<String, dynamic> json) =>
      _$ChangellyQuotePayloadFromJson(json);
}

@freezed
class ChangellyFixedRatePayload with _$ChangellyFixedRatePayload {
  const factory ChangellyFixedRatePayload({
    required String from,
    required String to,
    String? amountFrom,
    String? amountTo,
  }) = _ChangellyFixedRatePayload;

  factory ChangellyFixedRatePayload.fromJson(Map<String, dynamic> json) =>
      _$ChangellyFixedRatePayloadFromJson(json);
}

@freezed
class ChangellyVariableOrderPayload with _$ChangellyVariableOrderPayload {
  const factory ChangellyVariableOrderPayload({
    required String from,
    required String to,
    required String address,
    String? refundAddress,
    String? amountTo,
    String? amountFrom,
  }) = _ChangellyVariableOrderPayload;

  factory ChangellyVariableOrderPayload.fromJson(Map<String, dynamic> json) =>
      _$ChangellyVariableOrderPayloadFromJson(json);
}

@freezed
class ChangellyFixedOrderPayload with _$ChangellyFixedOrderPayload {
  const factory ChangellyFixedOrderPayload({
    required String from,
    required String to,
    required String address,
    required String rateId,
    required String refundAddress,
    String? amountTo,
    String? amountFrom,
  }) = _ChangellyFixedOrderPayload;

  factory ChangellyFixedOrderPayload.fromJson(Map<String, dynamic> json) =>
      _$ChangellyFixedOrderPayloadFromJson(json);
}

@freezed
class ChangellyFixedQuoteResponse with _$ChangellyFixedQuoteResponse {
  const factory ChangellyFixedQuoteResponse({
    required String from,
    required String to,
    required String id,
    required String result,
    required String networkFee,
    required String max,
    required String maxFrom,
    required String maxTo,
    required String min,
    required String minFrom,
    required String minTo,
    required String amountFrom,
    required String amountTo,
    required int expiredAt,
  }) = _ChangellyFixedQuoteResponse;

  factory ChangellyFixedQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyFixedQuoteResponseFromJson(json);
}

class ChangellyAssetIds {
  static const String btc = 'btc';
  static const String lbtc = 'lbtc';
  static const String usdt20 = 'usdt20';
  static const String usdtrx = 'usdtrx';
  static const String usdtbsc = 'usdtbsc';
  static const String usdtsol = 'usdtsol';
  static const String usdtpolygon = 'usdtpolygon';
  static const String usdton = 'usdton';
  static const String lusdt = 'lusdt';
}

@freezed
class ChangellyAsset with _$ChangellyAsset {
  ChangellyAsset._();

  factory ChangellyAsset({
    required String id,
  }) = _ChangellyAsset;

  factory ChangellyAsset.fromJson(Map<String, dynamic> json) =>
      _$ChangellyAssetFromJson(json);

  factory ChangellyAsset.fromSwapAsset(SwapAsset swapAsset) {
    return ChangellyAsset(id: _swapToChangellyId[swapAsset.id] ?? swapAsset.id);
  }

  SwapAsset toSwapAsset() {
    return _changellyToSwapAsset[id] ??
        (throw ArgumentError('Unsupported Changelly asset ID: $id'));
  }

  static final Map<String, String> _swapToChangellyId = {
    SwapAssetExt.btc.id: ChangellyAssetIds.btc,
    SwapAssetExt.lbtc.id: ChangellyAssetIds.lbtc,
    SwapAssetExt.usdtEth.id: ChangellyAssetIds.usdt20,
    SwapAssetExt.usdtTrx.id: ChangellyAssetIds.usdtrx,
    SwapAssetExt.usdtBep.id: ChangellyAssetIds.usdtbsc,
    SwapAssetExt.usdtSol.id: ChangellyAssetIds.usdtsol,
    SwapAssetExt.usdtPol.id: ChangellyAssetIds.usdtpolygon,
    SwapAssetExt.usdtTon.id: ChangellyAssetIds.usdton,
    SwapAssetExt.usdtLiquid.id: ChangellyAssetIds.lusdt,
  };

  static final Map<String, SwapAsset> _changellyToSwapAsset = {
    ChangellyAssetIds.btc: SwapAssetExt.btc,
    ChangellyAssetIds.lbtc: SwapAssetExt.lbtc,
    ChangellyAssetIds.usdt20: SwapAssetExt.usdtEth,
    ChangellyAssetIds.usdtrx: SwapAssetExt.usdtTrx,
    ChangellyAssetIds.usdtbsc: SwapAssetExt.usdtBep,
    ChangellyAssetIds.usdtsol: SwapAssetExt.usdtSol,
    ChangellyAssetIds.usdtpolygon: SwapAssetExt.usdtPol,
    ChangellyAssetIds.usdton: SwapAssetExt.usdtTon,
    ChangellyAssetIds.lusdt: SwapAssetExt.usdtLiquid,
  };
}
