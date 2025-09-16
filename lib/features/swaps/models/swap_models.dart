import 'package:coin_cz/common/decimal/decimal_converter.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'swap_models.freezed.dart';
part 'swap_models.g.dart';

enum SwapOrderType {
  @JsonValue('variable')
  variable,
  @JsonValue('fixed')
  fixed,
}

@freezed
class SwapArgs with _$SwapArgs {
  const factory SwapArgs({
    required SwapPair pair,
    SwapServiceSource? serviceProvider,
  }) = _SwapArgs;
}

@freezed
class SwapAsset with _$SwapAsset {
  const factory SwapAsset({
    required String id,
    required String name,
    required String ticker,
  }) = _SwapAsset;

  factory SwapAsset.fromJson(Map<String, dynamic> json) =>
      _$SwapAssetFromJson(json);

  factory SwapAsset.fromAsset(Asset asset) => SwapAsset(
        id: asset.id,
        name: asset.name,
        ticker: asset.ticker,
      );

  static const SwapAsset nullAsset = SwapAsset(id: '', name: '', ticker: '');
}

@freezed
class SwapPair with _$SwapPair {
  const factory SwapPair({
    required SwapAsset from,
    required SwapAsset to,
  }) = _SwapPair;

  factory SwapPair.fromJson(Map<String, dynamic> json) =>
      _$SwapPairFromJson(json);
}

@freezed
class SwapRate with _$SwapRate {
  const factory SwapRate({
    required Decimal rate,
    required Decimal min,
    required Decimal max,
  }) = _SwapRate;

  factory SwapRate.fromJson(Map<String, dynamic> json) =>
      _$SwapRateFromJson(json);
}

@freezed
class SwapQuote with _$SwapQuote {
  const factory SwapQuote({
    required String id,
    required DateTime createdAt,
    required String depositCoin,
    required String settleCoin,
    required String depositNetwork,
    required String settleNetwork,
    required DateTime expiresAt,
    @DecimalConverter() required Decimal depositAmount,
    @DecimalConverter() required Decimal settleAmount,
    @DecimalConverter() required Decimal rate,
    String? affiliateId,
  }) = _SwapQuote;

  factory SwapQuote.fromJson(Map<String, dynamic> json) =>
      _$SwapQuoteFromJson(json);
}

@freezed
class SwapOrderRequest with _$SwapOrderRequest {
  const factory SwapOrderRequest({
    required SwapAsset from,
    required SwapAsset to,
    String? refundAddress,
    String? receiveAddress,
    Decimal? amount,
    SwapQuote? quote,
    @Default(SwapOrderType.fixed) SwapOrderType type,
  }) = _SwapOrderRequest;

  factory SwapOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$SwapOrderRequestFromJson(json);
}

@freezed
class SwapOrder with _$SwapOrder {
  const factory SwapOrder({
    required DateTime createdAt,
    required String id,
    required SwapAsset from,
    required SwapAsset to,
    required String depositAddress,
    String? depositExtraId,
    required String settleAddress,
    String? settleExtraId,
    required Decimal depositAmount,
    Decimal? settleAmount, // can be null for variable orders
    required SwapFee serviceFee,
    Decimal? depositCoinNetworkFee,
    Decimal? settleCoinNetworkFee,
    DateTime? expiresAt,
    required SwapOrderStatus status,
    @Default(SwapOrderType.fixed) SwapOrderType type,
    required SwapServiceSource serviceType,
  }) = _SwapOrder;

  factory SwapOrder.fromJson(Map<String, dynamic> json) =>
      _$SwapOrderFromJson(json);
}

enum SwapOrderStatus {
  @JsonValue('unknown')
  unknown,
  @JsonValue('waiting')
  waiting,
  @JsonValue('processing')
  processing,
  @JsonValue('exchanging')
  exchanging,
  @JsonValue('sending')
  sending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('refunding')
  refunding,
  @JsonValue('refunded')
  refunded,
  @JsonValue('expired')
  expired,
}

enum SwapFeeType {
  @JsonValue('flatFee')
  flatFee,
  @JsonValue('percentageFee')
  percentageFee,
}

enum SwapFeeCurrency {
  @JsonValue('sats')
  sats,
  @JsonValue('usd')
  usd,
}

@freezed
class SwapFee with _$SwapFee {
  const factory SwapFee({
    required SwapFeeType type,
    @DecimalConverter() required Decimal value,
    required SwapFeeCurrency currency,
  }) = _SwapFee;

  factory SwapFee.fromJson(Map<String, dynamic> json) =>
      _$SwapFeeFromJson(json);
}
