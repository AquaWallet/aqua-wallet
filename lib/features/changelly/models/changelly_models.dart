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
    String? id,
    String? trackUrl,
    int? createdAt,
    ChangellyOrderType? type,
    ChangellyOrderStatus? status,
    String? currencyFrom,
    String? currencyTo,
    String? payinAddress,
    String? amountExpectedFrom,
    String? payoutAddress,
    String? amountExpectedTo,
    String? networkFee,
  }) = _ChangellyVariableOrderResponse;

  factory ChangellyVariableOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyVariableOrderResponseFromJson(json);
}

@freezed
class ChangellyQuoteResponse with _$ChangellyQuoteResponse {
  const factory ChangellyQuoteResponse({
    String? from,
    String? to,
    String? networkFee,
    String? amountFrom,
    String? amountTo,
    String? max,
    String? maxFrom,
    String? maxTo,
    String? min,
    String? minFrom,
    String? minTo,
    String? visibleAmount,
    String? rate,
    String? fee,
  }) = _ChangellyQuoteResponse;

  factory ChangellyQuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangellyQuoteResponseFromJson(json);
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
